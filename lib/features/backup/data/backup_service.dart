import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/backup_folder_service.dart';
import '../../../core/platform/file_transfer_service.dart';
import '../../../core/security/bundle_crypto_service.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/storage/database.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/domain/virtual_card.dart';
import '../../ids/data/id_repository.dart';
import '../../ids/domain/virtual_id.dart';
import '../domain/vault_backup.dart';
import 'auto_backup_file.dart';
import 'auto_backup_recorder.dart';
import 'auto_backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    cards: ref.watch(cardRepositoryProvider),
    ids: ref.watch(idRepositoryProvider),
    database: DatabaseHelper.instance,
    vault: EncryptionService(),
    bundle: BundleCryptoService(),
    files: FileTransferService(),
    auto: ref.watch(autoBackupServiceProvider),
  );
});

/// How many items are in the vault but not in the automatic backup.
///
/// Zero when everything is covered, when automatic backup is not set up, and
/// when the folder cannot be reached — the last of those because "your backup is
/// incomplete" is a serious thing to tell somebody and a folder that is offline
/// for a moment is not evidence of it.
///
/// This is only ever above zero because of items that were in the vault before
/// automatic backup was switched on. Everything saved afterwards is recorded as
/// it is typed. See [BackupService.copyExistingItemsIntoBackup].
///
/// autoDispose so it is asked again on each visit: it changes when a card is
/// saved, when the seeding runs, and when a folder comes back online.
final autoBackupMissingCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final inBackup = await ref.watch(autoBackupServiceProvider).backupRecordIds();
  if (inBackup == null) return 0;

  final storedCards = await ref.watch(cardRepositoryProvider).getAllCards();
  final storedIds = await ref.watch(idRepositoryProvider).getAllIds();

  var missing = 0;
  for (final card in storedCards) {
    final id = card.id;
    if (id != null && !inBackup.contains(AutoBackupRecorder.cardId(id))) {
      missing++;
    }
  }
  for (final doc in storedIds) {
    final id = doc.id;
    if (id != null && !inBackup.contains(AutoBackupRecorder.idDocId(id))) {
      missing++;
    }
  }
  return missing;
});

/// There is nothing in the vault to export.
class BackupVaultEmpty implements Exception {
  const BackupVaultEmpty();
}

/// Progress across the authentication prompts an operation costs.
typedef BackupProgress = void Function(int completed, int total);

/// What a restore would do, worked out before any prompt is spent.
class ImportPlan {
  final VaultBackup backup;
  final List<BackupCard> newCards;
  final List<BackupId> newIds;
  final int duplicateCount;

  const ImportPlan({
    required this.backup,
    required this.newCards,
    required this.newIds,
    required this.duplicateCount,
  });

  int get newItemCount => newCards.length + newIds.length;
  bool get hasNothingToDo => newItemCount == 0;
}

/// Encrypted export and import of the whole vault.
///
/// The shape of both operations is dictated by the vault key requiring user
/// authentication for every single use (audit finding 2-1). One record is one
/// cryptographic operation is one OS prompt, so an export of eight items costs
/// eight prompts and there is no batching available that would not weaken the
/// key. A photo rides inside its record's payload, so it adds no prompts of its
/// own. Both operations report progress, and both are all-or-nothing: every
/// record is processed in memory first and only then is anything written, so
/// dismissing a prompt half way through leaves no partial file and no
/// half-restored vault.
class BackupService {
  final CardRepository cards;
  final IdRepository ids;
  final DatabaseHelper database;
  final EncryptionService vault;
  final BundleCryptoService bundle;
  final FileTransferService files;

  /// Reads the files Karde maintains by itself. See [planImport], which serves
  /// both kinds of backup so the user never has to know which they are holding.
  final AutoBackupService auto;

  const BackupService({
    required this.cards,
    required this.ids,
    required this.database,
    required this.vault,
    required this.bundle,
    required this.files,
    required this.auto,
  });

  /// How many prompts an export will cost, so the user can be told before they
  /// commit to standing at the sensor.
  ///
  /// One per item, photo or no photo: the picture travels inside the item's own
  /// encrypted payload, so it comes out on the same authentication as the rest
  /// of the record.
  Future<int> countExportableItems() async {
    final storedCards = await cards.getAllCards();
    final storedIds = await ids.getAllIds();
    return storedCards.length + storedIds.length;
  }

  /// Decrypts the whole vault, seals it under [passphrase], and writes it to a
  /// location the user chooses. Returns the name of the file written.
  ///
  /// Throws [BackupVaultEmpty] if there is nothing to export, [VaultAuthCancelled]
  /// if a prompt is dismissed, and [FileTransferCancelled] if the save location
  /// picker is dismissed.
  Future<String> exportVault({
    required String passphrase,
    required BackupProgress onProgress,
  }) async {
    final storedCards = await cards.getAllCards();
    final storedIds = await ids.getAllIds();

    final total = storedCards.length + storedIds.length;
    if (total == 0) throw const BackupVaultEmpty();

    var completed = 0;
    onProgress(completed, total);

    final backupCards = <BackupCard>[];
    for (final card in storedCards) {
      // One decrypt yields the whole record, photo included.
      final secrets = _asMap(await vault.decrypt(await cards.payloadFor(card)));

      // Lifted out of the payload and into its own bundle field, so a decrypted
      // backup reads as "here is a card, and here is its picture" rather than
      // hiding a megabyte of base64 among the card's fields.
      final image = secrets.remove('image');

      backupCards.add(
        BackupCard(
          nickname: card.nickname,
          cardBrand: card.cardBrand,
          lastFourDigits: card.lastFourDigits,
          secrets: secrets,
          image: image is String && image.isNotEmpty ? image : null,
          createdAt: card.createdAt,
          updatedAt: card.updatedAt,
          isPinnedToTop: card.isPinnedToTop,
          isPinnedToHomescreen: card.isPinnedToHomescreen,
        ),
      );
      onProgress(++completed, total);
    }

    final backupIds = <BackupId>[];
    for (final doc in storedIds) {
      final payload = _asMap(await vault.decrypt(await ids.payloadFor(doc)));
      final image = IdPayload.imageOf(payload);

      backupIds.add(
        BackupId(
          nickname: doc.nickname,
          idType: doc.idType,
          fields: IdPayload.fieldsOf(payload),
          image: image,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          isPinnedToTop: doc.isPinnedToTop,
          isPinnedToHomescreen: doc.isPinnedToHomescreen,
        ),
      );
      onProgress(++completed, total);
    }

    // From here until the seal completes, the entire vault is in the clear in
    // this isolate's heap. Dart strings are immutable and cannot be wiped, so the
    // only available mitigation is to keep that window as short as possible and
    // drop every reference the moment it is no longer needed — hence sealing
    // immediately rather than, say, showing a preview first.
    final backup = VaultBackup.now(cards: backupCards, ids: backupIds);
    final envelope = await bundle.seal(backup.encode(), passphrase);
    backupCards.clear();
    backupIds.clear();

    return files.save(
      suggestedName: _suggestedFileName(),
      content: envelope,
    );
  }

  /// Asks the user for a backup file and returns its raw envelope text.
  ///
  /// Kept separate from decryption so the user picks the file first and is only
  /// asked for a passphrase once there is something to apply it to.
  Future<String> chooseBackupFile() => files.open();

  /// Opens [envelope] with [passphrase] and works out what restoring it would do.
  ///
  /// Costs no authentication prompts: duplicate detection compares nickname and
  /// creation time, both of which are stored unencrypted on the device.
  /// Works out what restoring [envelope] would do, whichever kind of file it is.
  ///
  /// Karde now writes two: the one the user exports by hand, sealed as a single
  /// bundle, and the one it keeps up to date by itself, holding each item sealed
  /// separately. The user has no reason to know or care which they are holding —
  /// both are "my Karde backup" — so the file says which it is and Karde reads it
  /// accordingly, rather than making them choose the right button and be wrong.
  /// Puts what is already in the vault into the automatic backup.
  ///
  /// Switching automatic backup on used to start it empty. Every save from that
  /// moment on was recorded, and everything saved *before* it was silently left
  /// out — so somebody with a full vault who turned backup on had a backup of
  /// nothing, was told "your backup is on", and would have found out on the day
  /// they replaced their phone. Found on the device: one card in the vault, and
  /// restoring the file it had just written reported "that backup does not
  /// contain any items".
  ///
  /// It is not automatic because it cannot be. These records are sealed inside
  /// the vault, and the vault key demands an authentication prompt for every
  /// single use, so this costs one prompt per item and the user has to be asked
  /// first. That is also why it is offered rather than retried in the
  /// background: nobody can answer a fingerprint prompt they are not standing in
  /// front of.
  ///
  /// Returns how many items were copied. Sealing is per item, but the write to
  /// the folder happens once at the end.
  Future<int> copyExistingItemsIntoBackup({
    required BackupProgress onProgress,
  }) async {
    // Only what is actually missing. Reading the whole vault would be simpler
    // and would charge the user an authentication prompt for every card they
    // own, most of which are already in the backup — and the count they agreed
    // to would not match the number of times the sensor asked.
    final alreadyThere = await auto.backupRecordIds();
    if (alreadyThere == null) throw const BackupFolderUnavailable('unreadable');

    final storedCards = (await cards.getAllCards())
        .where((c) =>
            c.id != null &&
            !alreadyThere.contains(AutoBackupRecorder.cardId(c.id!)))
        .toList();
    final storedIds = (await ids.getAllIds())
        .where((i) =>
            i.id != null &&
            !alreadyThere.contains(AutoBackupRecorder.idDocId(i.id!)))
        .toList();

    final total = storedCards.length + storedIds.length;
    if (total == 0) return 0;

    var completed = 0;
    onProgress(completed, total);

    // The same identifiers and the same record shapes a normal save writes, so a
    // seeded item and one recorded as it was typed are indistinguishable in the
    // file — and re-running this replaces those records rather than duplicating
    // them.
    final records = <String, String>{};

    for (final card in storedCards) {
      final id = card.id;
      if (id == null) continue;
      final secrets = _asMap(await vault.decrypt(await cards.payloadFor(card)));
      final image = secrets.remove('image');
      records[AutoBackupRecorder.cardId(id)] = jsonEncode(
        BackupCard(
          nickname: card.nickname,
          cardBrand: card.cardBrand,
          lastFourDigits: card.lastFourDigits,
          secrets: secrets,
          image: image is String && image.isNotEmpty ? image : null,
          createdAt: card.createdAt,
          updatedAt: card.updatedAt,
          isPinnedToTop: card.isPinnedToTop,
          isPinnedToHomescreen: card.isPinnedToHomescreen,
        ).toJson(),
      );
      onProgress(++completed, total);
    }

    for (final doc in storedIds) {
      final id = doc.id;
      if (id == null) continue;
      final payload = _asMap(await vault.decrypt(await ids.payloadFor(doc)));
      records[AutoBackupRecorder.idDocId(id)] = jsonEncode(
        BackupId(
          nickname: doc.nickname,
          idType: doc.idType,
          fields: IdPayload.fieldsOf(payload),
          image: IdPayload.imageOf(payload),
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          isPinnedToTop: doc.isPinnedToTop,
          isPinnedToHomescreen: doc.isPinnedToHomescreen,
        ).toJson(),
      );
      onProgress(++completed, total);
    }

    await auto.recordManySaves(records);
    records.clear();
    return total;
  }

  Future<ImportPlan> planImport({
    required String envelope,
    required String passphrase,
  }) async {
    final backup = _looksAutomatic(envelope)
        ? await auto.openBackupFile(contents: envelope, passphrase: passphrase)
        : VaultBackup.decode(await bundle.open(envelope, passphrase));

    return _planFor(backup);
  }

  /// Whether this is one of the files Karde maintains automatically.
  ///
  /// Read from the file rather than guessed from its name, because the user is
  /// free to rename it, and a dated copy from the history is a perfectly good
  /// thing to restore from — which is the whole reason the history exists.
  bool _looksAutomatic(String contents) {
    try {
      final json = jsonDecode(contents);
      return json is Map && json['format'] == AutoBackupFile.formatName;
    } catch (_) {
      // Not JSON at all. Let the bundle path produce the error, which knows how
      // to say "this is not a Karde backup" properly.
      return false;
    }
  }

  Future<ImportPlan> _planFor(VaultBackup backup) async {
    final existingCards = (await cards.getAllCards())
        .map((c) => '${c.nickname}|${c.createdAt.toIso8601String()}')
        .toSet();
    final existingIds = (await ids.getAllIds())
        .map((i) => '${i.nickname}|${i.createdAt.toIso8601String()}')
        .toSet();

    final newCards =
        backup.cards.where((c) => !existingCards.contains(c.identity)).toList();
    final newIds =
        backup.ids.where((i) => !existingIds.contains(i.identity)).toList();

    return ImportPlan(
      backup: backup,
      newCards: newCards,
      newIds: newIds,
      duplicateCount: backup.itemCount - newCards.length - newIds.length,
    );
  }

  /// Re-encrypts every new record under this device's vault key and writes them
  /// in a single transaction.
  ///
  /// Returns the number of items restored. Throws [VaultAuthCancelled] if a
  /// prompt is dismissed, in which case nothing at all has been written.
  Future<int> restore({
    required ImportPlan plan,
    required BackupProgress onProgress,
  }) async {
    final total = plan.newItemCount;
    if (total == 0) return 0;

    var completed = 0;
    onProgress(completed, total);

    // Encrypt everything before writing anything. A dismissed prompt at item
    // five of eight must not leave the vault holding a partial restore that the
    // user then has to identify and unpick by hand. Photos need no special
    // handling here: each one is part of its record's single payload, so it is
    // held back with the row it belongs to.
    final cardRows = <Map<String, dynamic>>[];
    for (final card in plan.newCards) {
      final encrypted = await vault.encrypt(jsonEncode({
        ...card.secrets,
        if (card.hasImage) 'image': _validImage(card.image!),
      }));
      cardRows.add(
        VirtualCard(
          nickname: card.nickname,
          cardBrand: card.cardBrand,
          lastFourDigits: card.lastFourDigits,
          encryptedData: encrypted,
          hasPhoto: card.hasImage,
          createdAt: card.createdAt,
          updatedAt: card.updatedAt,
          isPinnedToTop: card.isPinnedToTop,
          isPinnedToHomescreen: card.isPinnedToHomescreen,
        ).toMap()
          ..remove('id'),
      );
      onProgress(++completed, total);
    }

    final idRows = <Map<String, dynamic>>[];
    for (final doc in plan.newIds) {
      final encrypted = await vault.encrypt(jsonEncode(
        IdPayload.encode(
          fields: doc.fields.map((k, v) => MapEntry(k, v.toString())),
          image: doc.hasImage ? _validImage(doc.image!) : null,
        ),
      ));
      idRows.add(
        VirtualId(
          nickname: doc.nickname,
          idType: doc.idType,
          encryptedData: encrypted,
          hasPhoto: doc.hasImage,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          isPinnedToTop: doc.isPinnedToTop,
          isPinnedToHomescreen: doc.isPinnedToHomescreen,
        ).toMap()
          ..remove('id'),
      );
      onProgress(++completed, total);
    }

    await database.insertRestoredRecords(cards: cardRows, ids: idRows);
    return total;
  }

  /// Checks a bundle photo really is base64 before it is written back.
  ///
  /// Caught here rather than on the way out, so a damaged picture fails the
  /// restore instead of being silently dropped — a restore that quietly loses a
  /// photo the user believes they backed up is worse than one that stops and
  /// says so.
  String _validImage(String base64Image) {
    try {
      if (base64Decode(base64Image).isEmpty) {
        throw const BackupContentInvalid(BackupContentProblem.photoDamaged);
      }
    } on FormatException {
      throw const BackupContentInvalid(BackupContentProblem.photoDamaged);
    }
    return base64Image;
  }

  /// A decrypted payload should always be a JSON object. Anything else means the
  /// record was written by something other than this app, so it is surfaced as a
  /// damaged backup rather than silently exported as an empty entry.
  Map<String, dynamic> _asMap(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const BackupContentInvalid(BackupContentProblem.recordUnreadable);
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _suggestedFileName() {
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'karde-backup-$stamp.karde';
  }
}
