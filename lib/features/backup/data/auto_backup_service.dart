import 'dart:convert';

import '../../../core/platform/backup_folder_service.dart';
import '../../../core/security/backup_identity_service.dart';
import '../../../core/security/bundle_crypto_service.dart';
import '../../../core/security/encryption_service.dart';
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
    BundleCryptoService? bundle,
    EncryptionService? vault,
  })  : folder = folder ?? BackupFolderService(),
        identity = identity ?? BackupIdentityService(),
        pending = pending ?? PendingBackupStore(),
        bundle = bundle ?? BundleCryptoService(),
        vault = vault ?? EncryptionService();

  final SettingsRepository settings;
  final BackupFolderService folder;
  final BackupIdentityService identity;
  final PendingBackupStore pending;

  /// Wraps and unwraps things under a passphrase. Used to move the sealed
  /// private key from one passphrase to another, and for nothing else here.
  final BundleCryptoService bundle;

  /// The authenticated vault key. Only ever used on the passphrase reminder, so
  /// that reading the reminder back costs the phone's own prompt.
  final EncryptionService vault;

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

  /// The name an existing backup is moved to when a new one is set up over it.
  ///
  /// Deliberately not the dated-snapshot shape, so the five-day pruning never
  /// touches it. A backup displaced by a new setup is not a routine daily copy;
  /// it may be the only copy of a vault nothing on this phone can open.
  static String displacedNameFor(DateTime when) {
    final w = when.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'karde-backup-replaced-${w.year}-${two(w.month)}-${two(w.day)}'
        '-${two(w.hour)}${two(w.minute)}.json';
  }

  /// Creates the key pair, remembers the folder, and writes an empty backup.
  ///
  /// The empty file matters. It proves, while the user is still standing here
  /// and can do something about it, that the folder they picked can actually be
  /// written to — rather than finding out on their first saved card, or worse,
  /// never finding out.
  ///
  /// **Anything already in that folder is moved aside first, never overwritten.**
  ///
  /// This was the single worst bug in the feature, and it lived in the exact
  /// place it could do most harm. Setting up wrote an empty backup over
  /// karde-backup.json without looking, so the sequence a person follows on a
  /// new phone — install Karde, walk onboarding, point it at the folder holding
  /// their backup — destroyed that backup before they ever reached the screen
  /// that would have restored it. The user found it by re-onboarding onto
  /// yesterday's folder and noticing the file had been modified.
  ///
  /// Moving rather than merging, because the new setup has a new key pair: a
  /// file holding records sealed by two different keys could be opened by
  /// neither passphrase in full. Two intact files, one of which is restorable,
  /// beats one file that is half unreadable.
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

    await _preserveExisting(created.folderUri);

    await folder.write(
      created.folderUri,
      currentFileName,
      AutoBackupFile.empty(created.sealedPrivateKey).encode(),
    );

    await settings.setAutoBackup(created.toStorage());
    await rememberPassphrase(passphrase);
    return created;
  }

  /// Keeps a copy of the passphrase on this phone, sealed by the vault key.
  ///
  /// Never allowed to fail setup. The reminder is a convenience; the backup is
  /// the point, and a phone that cannot seal the reminder — the prompt was
  /// dismissed, the screen lock was just removed — has still been given a
  /// working backup. [hasPassphraseReminder] then reports false and the Backup
  /// screen offers to save it again.
  Future<void> rememberPassphrase(String passphrase) async {
    try {
      await settings.setSealedBackupPassphrase(await vault.encrypt(passphrase));
    } catch (_) {
      await settings.clearSealedBackupPassphrase();
    }
  }

  Future<bool> get hasPassphraseReminder async =>
      (await settings.getSealedBackupPassphrase()) != null;

  /// Reads the reminder back. Raises the phone's own authentication prompt.
  ///
  /// Null when there is nothing stored. Anything else — a dismissed prompt, a
  /// key the phone destroyed when its screen lock changed — comes out as the
  /// exception the caller already knows how to describe.
  Future<String?> revealPassphrase() async {
    final sealed = await settings.getSealedBackupPassphrase();
    if (sealed == null) return null;
    return vault.decrypt(sealed);
  }

  /// Confirms that [passphrase] is the one this backup was set up with.
  ///
  /// Does it by actually unwrapping the sealed private key, which is the only
  /// definition of "correct" that matters: a passphrase that opens that key is a
  /// passphrase that opens the backup on a new phone, whatever else may be
  /// stored on this one.
  Future<bool> passphraseOpensBackup(String passphrase) async {
    final current = await setup();
    if (current == null) return false;
    try {
      await bundle.open(current.sealedPrivateKey, passphrase);
      return true;
    } on BackupPassphraseIncorrect {
      return false;
    }
  }

  /// Moves the backup from one passphrase to another.
  ///
  /// Cheap, because the passphrase never sealed the records themselves. Each
  /// record is sealed with the public half of a key pair that does not change;
  /// the passphrase only wraps the private half. So changing it is unwrap,
  /// rewrap, and write — no reading the vault, and not one authentication prompt
  /// per card.
  ///
  /// The folder's current file is rewritten with the newly wrapped key. Dated
  /// copies from earlier days are deliberately left alone: they still hold the
  /// old wrapping and still open with the old passphrase. That is a fact the
  /// user has to be told rather than a thing to fix, because rewriting them
  /// would mean touching backups that are currently intact.
  ///
  /// Throws [BackupPassphraseIncorrect] if [oldPassphrase] is not the current
  /// one, and writes nothing in that case.
  Future<void> changePassphrase({
    required String oldPassphrase,
    required String newPassphrase,
  }) async {
    final current = await setup();
    if (current == null) {
      throw const BackupCryptoFailure('automatic backup is not set up');
    }

    // Throws BackupPassphraseIncorrect if the old one is wrong, before anything
    // has been written anywhere.
    final privateKey = await bundle.open(current.sealedPrivateKey, oldPassphrase);
    final resealed = await bundle.seal(privateKey, newPassphrase);

    // The file first. If this fails, storage still names the old wrapping, which
    // still matches what is in the folder — so the old passphrase keeps working
    // and nothing is stranded. The other order could leave a phone whose stored
    // key and whose file disagree.
    final existing = await folder.read(current.folderUri, currentFileName);
    if (existing != null && existing.trim().isNotEmpty) {
      final file = AutoBackupFile.decode(existing);
      await folder.write(
        current.folderUri,
        currentFileName,
        file.withSealedPrivateKey(resealed).encode(),
      );
    }

    await settings.setAutoBackup(AutoBackupSetup(
      folderUri: current.folderUri,
      folderLabel: current.folderLabel,
      publicKey: current.publicKey,
      sealedPrivateKey: resealed,
    ).toStorage());
    await rememberPassphrase(newPassphrase);
  }

  /// Whether the chosen folder already holds a Karde backup, and when it changed.
  ///
  /// So the setup screen can say so before anything is written. Answers null
  /// when there is nothing there, when it cannot be read, or when the folder
  /// cannot be reached — none of which should stop somebody setting up.
  Future<DateTime?> existingBackupChangedAt(String folderUri) async {
    try {
      final contents = await folder.read(folderUri, currentFileName);
      if (contents == null || contents.trim().isEmpty) return null;
      return AutoBackupFile.decode(contents).updatedAt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _preserveExisting(String folderUri) async {
    final String? existing;
    try {
      existing = await folder.read(folderUri, currentFileName);
    } catch (_) {
      // Cannot read the folder. The write that follows will fail too and setup
      // will stop there, which is the right outcome: nothing has been destroyed.
      return;
    }
    if (existing == null || existing.trim().isEmpty) return;

    // Not wrapped in a try. If the old backup cannot be moved to safety, setting
    // a new one up must not go ahead — that is precisely the case where carrying
    // on destroys the only copy someone has.
    await folder.write(
      folderUri,
      displacedNameFor(DateTime.now()),
      existing,
    );
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

  /// Seals a whole batch of items and pushes them in one write.
  ///
  /// For the items that were already in the vault when automatic backup was
  /// switched on. Every other path here records one item at the moment it is
  /// saved, because that is the only moment Karde has it in plain form for free;
  /// these have to be read back out of the vault instead, which is why they are
  /// not recorded automatically and why this exists as a deliberate, one-off act
  /// the user agrees to.
  ///
  /// One write rather than one per item. Each [recordSave] is a read of the
  /// backup file, an edit and a write back — fine for a single card, and for a
  /// vault of twenty it would be twenty round trips to a cloud folder, any of
  /// which could fail half way and leave the seeding partly done.
  Future<void> recordManySaves(Map<String, String> plaintextById) async {
    if (plaintextById.isEmpty) return;
    final config = await setup();
    if (config == null) return;

    var queue = await pending.read();
    for (final entry in plaintextById.entries) {
      queue = queue.withSave(
        entry.key,
        await identity.seal(
          publicKey: config.publicKey,
          plaintext: entry.value,
        ),
      );
    }
    await pending.write(queue);

    await flushPending(config);
  }

  /// Which items the backup file currently holds, by their record ids.
  ///
  /// Ids rather than a count, so "is anything missing" can be answered exactly
  /// instead of by comparing two numbers. A vault of two and a backup of two can
  /// still be a backup missing something, if one item was seeded and a different
  /// one deleted; comparing "card:3" against "card:3" cannot make that mistake.
  /// Nothing is decrypted to do this — the ids are in the clear in the file, and
  /// say nothing about what the records contain.
  ///
  /// Null means "cannot tell" — no backup set up, or the folder could not be
  /// reached. Deliberately distinct from an empty set, because the difference
  /// decides whether Karde may tell somebody their backup is incomplete, and a
  /// cloud folder that is briefly unreachable must not be reported as an empty
  /// backup.
  Future<Set<String>?> backupRecordIds() async {
    final config = await setup();
    if (config == null) return null;
    try {
      final contents = await folder.read(config.folderUri, currentFileName);
      if (contents == null || contents.trim().isEmpty) return <String>{};
      return AutoBackupFile.decode(contents).ids.toSet();
    } catch (_) {
      return null;
    }
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
