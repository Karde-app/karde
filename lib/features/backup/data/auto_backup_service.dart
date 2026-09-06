import 'dart:convert';

import '../../../core/platform/backup_folder_service.dart';
import '../../../core/security/backup_identity_service.dart';
import '../../../core/storage/settings_repository.dart';
import '../domain/vault_backup.dart';
import 'auto_backup_file.dart';
import 'pending_backup_store.dart';

/// How automatic backup is set up on this phone.
class AutoBackupSetup {
  const AutoBackupSetup({
    required this.folderUri,
    required this.folderLabel,
    required this.publicKey,
    required this.sealedPrivateKey,
  });

  final String folderUri;

  /// Somewhere the user recognises, e.g. "Documents/Karde". Shown, never used.
  final String folderLabel;

  /// Seals new records. Cannot open anything, so it is safe to keep to hand.
  final String publicKey;

  /// Opens them, once the passphrase has unwrapped it. Only used on restore.
  final String sealedPrivateKey;

  Map<String, String> toStorage() => {
        'folderUri': folderUri,
        'folderLabel': folderLabel,
        'publicKey': publicKey,
        'sealedPrivateKey': sealedPrivateKey,
      };

  static AutoBackupSetup? fromStorage(Map<String, String>? stored) {
    if (stored == null) return null;
    final folderUri = stored['folderUri'];
    final folderLabel = stored['folderLabel'];
    final publicKey = stored['publicKey'];
    final sealedPrivateKey = stored['sealedPrivateKey'];
    // All four or none. Any missing piece leaves an arrangement that cannot
    // work, and pretending otherwise means failing later with less to say.
    if (folderUri == null ||
        folderLabel == null ||
        publicKey == null ||
        sealedPrivateKey == null) {
      return null;
    }
    return AutoBackupSetup(
      folderUri: folderUri,
      folderLabel: folderLabel,
      publicKey: publicKey,
      sealedPrivateKey: sealedPrivateKey,
    );
  }
}

/// Keeps the backup file in step with the vault, without ever asking the user.
///
/// The rule this exists to honour: a backup Karde takes for you is worth having
/// only if it is current and only if you are told when it stops. Everything
/// here follows from those two.
///
/// It is current because a save updates one record rather than rebuilding the
/// file from the vault. Rebuilding would mean reading every item back, and the
/// vault key demands an authentication prompt per item — so a single edit would
/// cost as many fingerprint touches as you have cards. Sealing the one record
/// the user just typed costs nothing at all.
///
/// You are told when it stops because [recordSave] and [recordDelete] let their
/// failures out. Swallowing them would produce the worst outcome this feature
/// has: a backup that quietly stopped working months ago, whose owner believes
/// they are covered and has stopped thinking about it.
class AutoBackupService {
  AutoBackupService({
    required this.settings,
    BackupFolderService? folder,
    BackupIdentityService? identity,
    PendingBackupStore? pending,
  })  : folder = folder ?? BackupFolderService(),
        identity = identity ?? BackupIdentityService(),
        pending = pending ?? PendingBackupStore();

  final SettingsRepository settings;
  final BackupFolderService folder;
  final BackupIdentityService identity;
  final PendingBackupStore pending;

  /// The file Karde keeps up to date. Dated copies live beside it.
  static const String currentFileName = 'karde-backup.json';

  /// How many days of older copies to keep beside the current file.
  ///
  /// An automatic backup is instant, and that is its one weakness: delete a card
  /// by mistake and, with only a current file, the backup would agree with you a
  /// second later and the card would be gone from both places at once. Yesterday's
  /// copy is what makes that recoverable.
  ///
  /// Five days rather than five saves. Someone who notices a missing card notices
  /// it days later, when they go looking for it — not within the next few edits.
  static const int keepDays = 5;

  static String snapshotNameFor(DateTime day) {
    final d = day.toUtc();
    final month = d.month.toString().padLeft(2, '0');
    final dayOfMonth = d.day.toString().padLeft(2, '0');
    return 'karde-backup-${d.year}-$month-$dayOfMonth.json';
  }

  static final RegExp _snapshotPattern =
      RegExp(r'^karde-backup-\d{4}-\d{2}-\d{2}\.json$');

  Future<AutoBackupSetup?> setup() async =>
      AutoBackupSetup.fromStorage(await settings.getAutoBackup());

  Future<bool> get isConfigured async => (await setup()) != null;

  /// Creates the key pair, remembers the folder, and writes an empty backup.
  ///
  /// The empty file matters. It proves, while the user is still standing here
  /// and can do something about it, that the folder they picked can actually be
  /// written to — rather than finding out on their first saved card, or worse,
  /// never finding out.
  Future<AutoBackupSetup> configure({
    required String passphrase,
    required BackupFolderChoice folderChoice,
  }) async {
    final pair = await identity.create(passphrase);
    final created = AutoBackupSetup(
      folderUri: folderChoice.uri,
      folderLabel: folderChoice.label,
      publicKey: pair.publicKey,
      sealedPrivateKey: pair.sealedPrivateKey,
    );

    await folder.write(
      created.folderUri,
      currentFileName,
      AutoBackupFile.empty(created.sealedPrivateKey).encode(),
    );

    await settings.setAutoBackup(created.toStorage());
    return created;
  }

  /// Records one item, adding it or replacing it.
  ///
  /// [id] identifies the item within the file — "card:12", "id:3" — so a second
  /// save of the same card replaces the first rather than leaving two copies for
  /// a restore to bring back.
  ///
  /// Does nothing at all if automatic backup has not been set up, so callers can
  /// call it unconditionally and stay readable.
  Future<void> recordSave({
    required String id,
    required String plaintext,
  }) async {
    final config = await setup();
    if (config == null) return;

    // Sealed and queued first, and only then pushed. The sealing needs nothing
    // but the phone, so it always succeeds; the pushing needs the folder, which
    // for a cloud folder means a network. Queueing before pushing is what stops
    // a save made with no signal from vanishing from the backup entirely.
    final sealed =
        await identity.seal(publicKey: config.publicKey, plaintext: plaintext);
    await pending.write((await pending.read()).withSave(id, sealed));

    await flushPending(config);
  }

  /// Forgets one item, because the user deleted it.
  Future<void> recordDelete(String id) async {
    final config = await setup();
    if (config == null) return;

    await pending.write((await pending.read()).withDelete(id));
    await flushPending(config);
  }

  /// Pushes everything queued to the folder, if it can be reached.
  ///
  /// Throws if it cannot, and leaves the queue alone so the next attempt carries
  /// the same changes. Callers that are not the user's own save — a retry on
  /// waking the app, say — should swallow that: nobody wants a message every
  /// time a phone comes out of a pocket underground.
  ///
  /// The folder's file is read before it is written, and the queue is only
  /// cleared once the write lands. Nothing is ever overwritten on the strength
  /// of a copy Karde could not first confirm.
  Future<void> flushPending([AutoBackupSetup? known]) async {
    final config = known ?? await setup();
    if (config == null) return;

    final changes = await pending.read();
    if (changes.isEmpty) return;

    final file = await _openOrStart(config);
    var changed = changes.saved.isNotEmpty;
    changes.saved.forEach(file.put);
    for (final id in changes.deleted) {
      if (file.remove(id)) changed = true;
    }

    // Deleting an item the backup never held — one saved before backup was set
    // up — leaves the file exactly as it was. Writing it anyway would churn the
    // folder and, worse, spend the day's history slot on a copy identical to the
    // one already there.
    if (changed) await _writeCurrent(config, file);
    await pending.clear();
  }

  /// How long the backup has been behind, or null if it is up to date.
  Future<Duration?> behindFor() async {
    final changes = await pending.read();
    return changes.isEmpty ? null : changes.behindFor;
  }

  /// Opens an automatic backup file into the same shape a manual one produces.
  ///
  /// Everything downstream — working out which items are already here, telling
  /// the user what a restore would do, writing the rows — is then one piece of
  /// code serving both kinds of file. A restore should not have to care how the
  /// backup it is reading was taken.
  ///
  /// Costs one key derivation for the whole file rather than one per record,
  /// which is why [BackupIdentityService.openAll] takes them all at once.
  Future<VaultBackup> openBackupFile({
    required String contents,
    required String passphrase,
  }) async {
    final file = AutoBackupFile.decode(contents);
    final entries = file.sealedEntries;

    final opened = await identity.openAll(
      sealedPrivateKey: file.sealedPrivateKey,
      passphrase: passphrase,
      records: entries.map((entry) => entry.value).toList(),
    );

    final cards = <BackupCard>[];
    final documents = <BackupId>[];
    for (var i = 0; i < entries.length; i++) {
      final json = jsonDecode(opened[i]) as Map<String, dynamic>;
      if (AutoBackupFile.isCardId(entries[i].key)) {
        cards.add(BackupCard.fromJson(json));
      } else {
        documents.add(BackupId.fromJson(json));
      }
    }

    return VaultBackup.now(cards: cards, ids: documents);
  }

  /// Whether the folder is still reachable and still holds the backup.
  ///
  /// For the periodic check that decides whether to warn. Answers rather than
  /// throwing, because it is asked when nobody is watching.
  Future<bool> isHealthy() async {
    final config = await setup();
    if (config == null) return true; // Nothing set up is not a broken backup.
    return folder.isUsable(config.folderUri);
  }

  /// Writes the current file, keeping a copy of the day it is replacing.
  ///
  /// The snapshot is taken *before* the overwrite and named after the day the
  /// outgoing file was last written, so each dated copy is that day's final
  /// state. Written once per day rather than once per save: the first change
  /// after midnight preserves yesterday, and the rest of the day's edits cost
  /// one write each, as they should.
  ///
  /// A snapshot that cannot be taken never stops the backup being written. The
  /// current file is the thing that matters; history is a kindness on top of it,
  /// and losing the kindness is no reason to lose the backup.
  Future<void> _writeCurrent(AutoBackupSetup config, AutoBackupFile file) async {
    await _keepYesterday(config, file);
    await folder.write(config.folderUri, currentFileName, file.encode());
  }

  Future<void> _keepYesterday(AutoBackupSetup config, AutoBackupFile file) async {
    try {
      final name = snapshotNameFor(file.updatedAt);
      if (name == snapshotNameFor(DateTime.now())) return; // Same day already.

      final existing = await folder.read(config.folderUri, currentFileName);
      if (existing == null || existing.trim().isEmpty) return;

      final names = await folder.list(config.folderUri);
      if (!names.contains(name)) {
        await folder.write(config.folderUri, name, existing);
      }
      await _pruneSnapshots(config, await folder.list(config.folderUri));
    } catch (_) {
      // Deliberately swallowed. See the note above: the current file is what
      // matters, and a folder that cannot hold history can still hold a backup.
    }
  }

  Future<void> _pruneSnapshots(AutoBackupSetup config, List<String> names) async {
    final snapshots = names.where(_snapshotPattern.hasMatch).toList()..sort();
    if (snapshots.length <= keepDays) return;
    for (final stale in snapshots.take(snapshots.length - keepDays)) {
      await folder.delete(config.folderUri, stale);
    }
  }

  /// Reads the current file, or starts a fresh one if it has gone.
  ///
  /// A missing file is not treated as a failure: it happens on the very first
  /// save, and it happens if the user moves or deletes the file themselves. In
  /// both cases the right answer is to write a new one rather than to refuse and
  /// leave them with no backup at all.
  ///
  /// A file that is *there* but unreadable is a different matter and is allowed
  /// to throw. Overwriting it would throw away whatever it holds, and it may be
  /// the only copy of a vault this phone can no longer decrypt.
  Future<AutoBackupFile> _openOrStart(AutoBackupSetup config) async {
    final contents = await folder.read(config.folderUri, currentFileName);
    if (contents == null || contents.trim().isEmpty) {
      return AutoBackupFile.empty(config.sealedPrivateKey);
    }
    return AutoBackupFile.decode(contents);
  }
}
