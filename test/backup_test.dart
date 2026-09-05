import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/platform/file_transfer_service.dart';
import 'package:ibank/core/security/bundle_crypto_service.dart';
import 'package:ibank/core/security/encryption_service.dart';
import 'package:ibank/core/storage/database.dart';
import 'package:ibank/features/backup/data/backup_service.dart';
import 'package:ibank/features/backup/domain/vault_backup.dart';
import 'package:ibank/features/cards/data/card_repository.dart';
import 'package:ibank/features/cards/domain/virtual_card.dart';
import 'package:ibank/features/ids/data/id_repository.dart';
import 'package:ibank/features/ids/domain/virtual_id.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Stands in for the Keystore-backed vault key.
///
/// The real one raises an OS prompt per operation, which is exactly the property
/// these tests need to model: [failOnCall] makes the Nth call behave as if the
/// user dismissed that prompt, so the all-or-nothing guarantees can be checked.
class FakeVault implements EncryptionService {
  int encryptCalls = 0;
  int decryptCalls = 0;

  /// 1-based index of the encrypt call that should be treated as cancelled.
  int? failEncryptOnCall;

  @override
  Future<bool> canUseVault() async => true;

  @override
  Future<bool> willPromptEveryUse() async => true;

  @override
  Future<String> encrypt(String plaintext) async {
    encryptCalls++;
    if (encryptCalls == failEncryptOnCall) throw const VaultAuthCancelled();
    return 'enc($plaintext)';
  }

  @override
  Future<String> decrypt(String encryptedText) async {
    decryptCalls++;
    if (!encryptedText.startsWith('enc(') || !encryptedText.endsWith(')')) {
      throw const VaultCryptoFailure('not fake-encrypted');
    }
    return encryptedText.substring(4, encryptedText.length - 1);
  }
}

/// Models the passphrase envelope without running 600k PBKDF2 rounds.
class FakeBundleCrypto implements BundleCryptoService {
  @override
  Future<String> seal(String plaintext, String passphrase) async =>
      jsonEncode({'pass': passphrase, 'body': plaintext});

  @override
  Future<String> open(String envelope, String passphrase) async {
    final decoded = jsonDecode(envelope) as Map<String, dynamic>;
    if (decoded['pass'] != passphrase) throw const BackupPassphraseIncorrect();
    return decoded['body'] as String;
  }
}

class FakeFileTransfer implements FileTransferService {
  String? written;
  String? toReturnOnOpen;
  bool cancelSave = false;

  @override
  Future<String> save({required String suggestedName, required String content}) async {
    if (cancelSave) throw const FileTransferCancelled();
    written = content;
    return suggestedName;
  }

  @override
  Future<String> open() async {
    final content = toReturnOnOpen;
    if (content == null) throw const FileTransferCancelled();
    return content;
  }
}

VirtualCard sampleCard({
  required String nickname,
  required DateTime createdAt,
  String number = '4242424242424242',
  bool pinnedToTop = false,
}) {
  return VirtualCard(
    nickname: nickname,
    cardBrand: 'Visa',
    lastFourDigits: number.substring(number.length - 4),
    encryptedData: 'enc(${CardSecrets(
      cardNumber: number,
      expiry: '12/30',
      cvv: '123',
      cardholderName: 'JANE DOE',
      notes: 'private note',
    ).toJson()})',
    createdAt: createdAt,
    updatedAt: createdAt,
    isPinnedToTop: pinnedToTop,
  );
}

/// A card whose encrypted payload also carries a photo.
VirtualCard photographedCard({
  required String nickname,
  required DateTime createdAt,
  required String image,
}) {
  return VirtualCard(
    nickname: nickname,
    cardBrand: 'Visa',
    lastFourDigits: '4242',
    encryptedData: 'enc(${CardSecrets(
      cardNumber: '4242424242424242',
      expiry: '12/30',
      cvv: '123',
      cardholderName: 'JANE DOE',
      image: image,
    ).toJson()})',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

VirtualId sampleId({required String nickname, required DateTime createdAt}) {
  return VirtualId(
    nickname: nickname,
    idType: 'Passport',
    encryptedData: 'enc(${jsonEncode({'documentNumber': 'X1234567'})})',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

Uint8List fakeJpeg(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (i + seed) % 256));

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('VaultBackup encoding', () {
    test('round-trips cards and IDs including pin flags', () {
      final created = DateTime.parse('2026-01-02T03:04:05.000');
      final backup = VaultBackup.now(
        cards: [
          BackupCard(
            nickname: 'Travel card',
            cardBrand: 'Visa',
            lastFourDigits: '4242',
            secrets: const {'cardNumber': '4242424242424242', 'cvv': '123'},
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: true,
            isPinnedToHomescreen: false,
          ),
        ],
        ids: [
          BackupId(
            nickname: 'Passport',
            idType: 'Passport',
            fields: const {'documentNumber': 'X1234567'},
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: true,
          ),
        ],
      );

      final restored = VaultBackup.decode(backup.encode());

      expect(restored.itemCount, 2);
      expect(restored.cards.single.nickname, 'Travel card');
      expect(restored.cards.single.secrets['cardNumber'], '4242424242424242');
      expect(restored.cards.single.isPinnedToTop, isTrue);
      expect(restored.cards.single.createdAt, created);
      expect(restored.ids.single.fields['documentNumber'], 'X1234567');
      expect(restored.ids.single.isPinnedToHomescreen, isTrue);
    });

    test('carries a photo through the encode/decode round trip', () {
      final created = DateTime.parse('2026-01-02T03:04:05.000');
      final image = base64Encode(fakeJpeg(7));

      final backup = VaultBackup.now(
        cards: [
          BackupCard(
            nickname: 'Photographed card',
            cardBrand: 'Visa',
            lastFourDigits: '4242',
            secrets: const {'cardNumber': '4242424242424242'},
            image: image,
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
        ids: [
          BackupId(
            nickname: 'Passport',
            idType: 'Passport',
            fields: const {'documentNumber': 'X1'},
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
      );

      final restored = VaultBackup.decode(backup.encode());

      expect(restored.cards.single.image, image);
      expect(restored.cards.single.hasImage, isTrue);
      expect(restored.ids.single.image, isNull);
      expect(restored.ids.single.hasImage, isFalse);
      // A photo rides inside its record's payload, so it adds no prompt of its
      // own: two items, two prompts, whether or not either has a picture.
      expect(restored.promptCount, 2);
    });

    test('a version 1 backup still restores, simply without photos', () {
      final created = DateTime.parse('2026-01-02T03:04:05.000');
      final v1 = jsonEncode({
        'format': VaultBackup.format,
        'version': 1,
        'createdAt': created.toIso8601String(),
        'appVersion': '1.0.0',
        'cards': [
          {
            'nickname': 'Old card',
            'cardBrand': 'Visa',
            'lastFourDigits': '4242',
            'secrets': {'cardNumber': '4242424242424242'},
            'createdAt': created.toIso8601String(),
            'updatedAt': created.toIso8601String(),
          },
        ],
        'ids': const [],
      });

      final restored = VaultBackup.decode(v1);

      expect(restored.cards.single.nickname, 'Old card');
      expect(restored.cards.single.image, isNull);
      expect(restored.promptCount, 1);
    });

    test('rejects a record whose photo field is damaged', () {
      final created = DateTime.parse('2026-01-02T03:04:05.000');
      expect(
        () => VaultBackup.decode(jsonEncode({
          'format': VaultBackup.format,
          'version': VaultBackup.version,
          'createdAt': created.toIso8601String(),
          'cards': [
            {
              'nickname': 'Bad photo',
              'cardBrand': 'Visa',
              'lastFourDigits': '4242',
              'secrets': const {'cardNumber': '4242424242424242'},
              // Not a string: importing this as "no photo" would silently lose
              // data the user believes they backed up.
              'image': 42,
              'createdAt': created.toIso8601String(),
              'updatedAt': created.toIso8601String(),
            },
          ],
        })),
        throwsA(isA<BackupContentInvalid>()),
      );
    });

    test('rejects a file that is not a Karde backup', () {
      expect(
        () => VaultBackup.decode(jsonEncode({'format': 'something.else'})),
        throwsA(isA<BackupContentInvalid>()),
      );
    });

    test('rejects a backup written by a newer version', () {
      expect(
        () => VaultBackup.decode(jsonEncode({
          'format': VaultBackup.format,
          'version': VaultBackup.version + 1,
        })),
        throwsA(isA<BackupContentInvalid>()),
      );
    });

    test('rejects damaged JSON rather than throwing FormatException', () {
      expect(
        () => VaultBackup.decode('{not json'),
        throwsA(isA<BackupContentInvalid>()),
      );
    });

    test('rejects an entry that is missing a required field', () {
      expect(
        () => VaultBackup.decode(jsonEncode({
          'format': VaultBackup.format,
          'version': VaultBackup.version,
          'createdAt': DateTime.now().toIso8601String(),
          'cards': [
            {'nickname': 'No dates here'},
          ],
        })),
        throwsA(isA<BackupContentInvalid>()),
      );
    });
  });

  group('BackupService', () {
    late FakeVault vault;
    late FakeBundleCrypto bundle;
    late FakeFileTransfer files;
    late BackupService service;
    late Database db;

    setUp(() async {
      db = await DatabaseHelper.instance.database;
      await db.delete(DatabaseHelper.tableCards);
      await db.delete(DatabaseHelper.tableIds);

      vault = FakeVault();
      bundle = FakeBundleCrypto();
      files = FakeFileTransfer();
      service = BackupService(
        cards: CardRepository(DatabaseHelper.instance),
        ids: IdRepository(DatabaseHelper.instance),
        database: DatabaseHelper.instance,
        vault: vault,
        bundle: bundle,
        files: files,
      );
    });

    test('refuses to export an empty vault', () async {
      expect(
        () => service.exportVault(passphrase: 'correct horse battery', onProgress: (_, __) {}),
        throwsA(isA<BackupVaultEmpty>()),
      );
    });

    test('export costs one decrypt per item and reports progress', () async {
      final repo = CardRepository(DatabaseHelper.instance);
      await repo.insertCard(sampleCard(
        nickname: 'One',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
      ));
      await repo.insertCard(sampleCard(
        nickname: 'Two',
        createdAt: DateTime.parse('2026-01-02T00:00:00.000'),
        number: '5555444433332222',
      ));
      await IdRepository(DatabaseHelper.instance).insertId(sampleId(
        nickname: 'Passport',
        createdAt: DateTime.parse('2026-01-03T00:00:00.000'),
      ));

      final progress = <String>[];
      final name = await service.exportVault(
        passphrase: 'correct horse battery',
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(vault.decryptCalls, 3, reason: 'one authenticated decrypt per item');
      expect(progress, ['0/3', '1/3', '2/3', '3/3']);
      expect(name, endsWith('.karde'));

      final envelope = files.written;
      expect(envelope, isNotNull);
      final body = jsonDecode(envelope!) as Map<String, dynamic>;
      expect(body['pass'], 'correct horse battery');

      final decoded = VaultBackup.decode(body['body'] as String);
      expect(decoded.cards.length, 2);
      expect(decoded.ids.length, 1);
      expect(
        decoded.cards.map((c) => c.secrets['cardNumber']),
        containsAll(['4242424242424242', '5555444433332222']),
      );
    });

    test('a dismissed prompt during export writes no file', () async {
      await CardRepository(DatabaseHelper.instance).insertCard(sampleCard(
        nickname: 'One',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
      ));
      // A card whose payload the fake vault cannot open stands in for a failure
      // part way through the run.
      await db.insert(DatabaseHelper.tableCards, {
        'nickname': 'Broken',
        'cardBrand': 'Visa',
        'lastFourDigits': '0000',
        'encryptedData': 'not-fake-encrypted',
        'createdAt': DateTime.parse('2026-01-02T00:00:00.000').toIso8601String(),
        'updatedAt': DateTime.parse('2026-01-02T00:00:00.000').toIso8601String(),
      });

      await expectLater(
        service.exportVault(passphrase: 'p', onProgress: (_, __) {}),
        throwsA(isA<VaultCryptoFailure>()),
      );
      expect(files.written, isNull);
    });

    test('a wrong passphrase is reported as such and reveals nothing', () async {
      final envelope = await bundle.seal('anything', 'the right one');
      expect(
        () => service.planImport(envelope: envelope, passphrase: 'the wrong one'),
        throwsA(isA<BackupPassphraseIncorrect>()),
      );
    });

    test('import plan skips items already in the vault', () async {
      final shared = DateTime.parse('2026-01-01T00:00:00.000');
      await CardRepository(DatabaseHelper.instance)
          .insertCard(sampleCard(nickname: 'Already here', createdAt: shared));

      final backup = VaultBackup.now(
        cards: [
          BackupCard(
            nickname: 'Already here',
            cardBrand: 'Visa',
            lastFourDigits: '4242',
            secrets: const {'cardNumber': '4242424242424242'},
            createdAt: shared,
            updatedAt: shared,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
          BackupCard(
            nickname: 'Brand new',
            cardBrand: 'Visa',
            lastFourDigits: '1111',
            secrets: const {'cardNumber': '4111111111111111'},
            createdAt: DateTime.parse('2026-02-02T00:00:00.000'),
            updatedAt: DateTime.parse('2026-02-02T00:00:00.000'),
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
        ids: const [],
      );

      final plan = await service.planImport(
        envelope: await bundle.seal(backup.encode(), 'pass'),
        passphrase: 'pass',
      );

      expect(plan.duplicateCount, 1);
      expect(plan.newItemCount, 1);
      expect(plan.newCards.single.nickname, 'Brand new');
    });

    test('restore writes new rows and preserves pin flags', () async {
      final created = DateTime.parse('2026-03-03T00:00:00.000');
      final backup = VaultBackup.now(
        cards: [
          BackupCard(
            nickname: 'Restored card',
            cardBrand: 'Visa',
            lastFourDigits: '1111',
            secrets: const {'cardNumber': '4111111111111111'},
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: true,
            isPinnedToHomescreen: true,
          ),
        ],
        ids: [
          BackupId(
            nickname: 'Restored passport',
            idType: 'Passport',
            fields: const {'documentNumber': 'X1'},
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
      );

      final plan = await service.planImport(
        envelope: await bundle.seal(backup.encode(), 'pass'),
        passphrase: 'pass',
      );
      final restored = await service.restore(plan: plan, onProgress: (_, __) {});

      expect(restored, 2);
      expect(vault.encryptCalls, 2, reason: 'one authenticated encrypt per item');

      final cards = await CardRepository(DatabaseHelper.instance).getAllCards();
      expect(cards.single.nickname, 'Restored card');
      expect(cards.single.id, isNotNull, reason: 'SQLite assigns a fresh local id');
      expect(cards.single.isPinnedToTop, isTrue);
      expect(cards.single.isPinnedToHomescreen, isTrue);
      expect(cards.single.createdAt, created);

      final ids = await IdRepository(DatabaseHelper.instance).getAllIds();
      expect(ids.single.nickname, 'Restored passport');
    });

    test('a photo costs no prompt of its own and reaches the bundle', () async {
      final created = DateTime.parse('2026-01-01T00:00:00.000');
      final photo = fakeJpeg(3);

      await CardRepository(DatabaseHelper.instance).insertCard(
        photographedCard(
          nickname: 'With photo',
          createdAt: created,
          image: base64Encode(photo),
        ),
      );
      await IdRepository(DatabaseHelper.instance)
          .insertId(sampleId(nickname: 'No photo', createdAt: created));

      expect(await service.countExportableItems(), 2);

      final progress = <String>[];
      await service.exportVault(
        passphrase: 'pass',
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      // Two records, two decrypts. The photo came out inside the card's.
      expect(vault.decryptCalls, 2);
      expect(progress.last, '2/2');

      final body = jsonDecode(files.written!) as Map<String, dynamic>;
      final decoded = VaultBackup.decode(body['body'] as String);
      expect(base64Decode(decoded.cards.single.image!), photo);
      expect(decoded.ids.single.image, isNull);
    });

    test('the exported card fields do not also carry the raw image', () async {
      final created = DateTime.parse('2026-01-01T00:00:00.000');
      await CardRepository(DatabaseHelper.instance).insertCard(
        photographedCard(
          nickname: 'With photo',
          createdAt: created,
          image: base64Encode(fakeJpeg(4)),
        ),
      );

      await service.exportVault(passphrase: 'pass', onProgress: (_, __) {});
      final body = jsonDecode(files.written!) as Map<String, dynamic>;
      final decoded = VaultBackup.decode(body['body'] as String);

      // Lifted out of the payload into its own field, so a decrypted bundle
      // reads as "a card, and its picture" rather than hiding a base64 blob
      // among the card's secrets.
      expect(decoded.cards.single.secrets.containsKey('image'), isFalse);
      expect(decoded.cards.single.image, isNotNull);
    });

    test('restore writes the photo back inside the record payload', () async {
      final created = DateTime.parse('2026-03-03T00:00:00.000');
      final photo = fakeJpeg(9);
      final backup = VaultBackup.now(
        cards: [
          BackupCard(
            nickname: 'Restored with photo',
            cardBrand: 'Visa',
            lastFourDigits: '1111',
            secrets: const {'cardNumber': '4111111111111111'},
            image: base64Encode(photo),
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
        ids: [
          BackupId(
            nickname: 'Restored passport',
            idType: 'Passport',
            fields: const {'documentNumber': 'X1'},
            image: base64Encode(fakeJpeg(11)),
            createdAt: created,
            updatedAt: created,
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ],
      );

      final plan = await service.planImport(
        envelope: await bundle.seal(backup.encode(), 'pass'),
        passphrase: 'pass',
      );
      expect(plan.newItemCount, 2);

      final restored = await service.restore(plan: plan, onProgress: (_, __) {});
      expect(restored, 2);
      expect(vault.encryptCalls, 2, reason: 'a photo adds no encrypt of its own');

      final repo = CardRepository(DatabaseHelper.instance);
      final card = (await repo.getAllCards()).single;
      final secrets = CardSecrets.fromJson(
        await vault.decrypt(await repo.payloadFor(card)),
      );
      expect(base64Decode(secrets.image!), photo);

      final idRepo = IdRepository(DatabaseHelper.instance);
      final doc = (await idRepo.getAllIds()).single;
      final payload = jsonDecode(await vault.decrypt(await idRepo.payloadFor(doc)))
          as Map<String, dynamic>;
      expect(base64Decode(IdPayload.imageOf(payload)!), fakeJpeg(11));
      expect(IdPayload.fieldsOf(payload), {'documentNumber': 'X1'});
    });

    test('a dismissed prompt part way through a photographed restore writes '
        'nothing at all', () async {
      final created = DateTime.parse('2026-03-03T00:00:00.000');
      final backup = VaultBackup.now(
        cards: List.generate(
          2,
          (i) => BackupCard(
            nickname: 'Card $i',
            cardBrand: 'Visa',
            lastFourDigits: '000$i',
            secrets: {'cardNumber': '411111111111111$i'},
            image: base64Encode(fakeJpeg(i)),
            createdAt: created.add(Duration(days: i)),
            updatedAt: created.add(Duration(days: i)),
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ),
        ids: const [],
      );

      final plan = await service.planImport(
        envelope: await bundle.seal(backup.encode(), 'pass'),
        passphrase: 'pass',
      );

      vault.failEncryptOnCall = 2;
      await expectLater(
        service.restore(plan: plan, onProgress: (_, __) {}),
        throwsA(isA<VaultAuthCancelled>()),
      );

      // Photos need no separate cleanup now: each one is part of the row it
      // belongs to, so holding the rows back holds the pictures back with them.
      expect(await CardRepository(DatabaseHelper.instance).getAllCards(), isEmpty);
    });

    test('a damaged photo in a bundle fails the restore rather than silently '
        'dropping the photo', () async {
      final created = DateTime.parse('2026-03-03T00:00:00.000');
      final envelope = await bundle.seal(
        jsonEncode({
          'format': VaultBackup.format,
          'version': VaultBackup.version,
          'createdAt': created.toIso8601String(),
          'cards': [
            {
              'nickname': 'Damaged photo',
              'cardBrand': 'Visa',
              'lastFourDigits': '4242',
              'secrets': const {'cardNumber': '4242424242424242'},
              'image': 'not!valid!base64!',
              'createdAt': created.toIso8601String(),
              'updatedAt': created.toIso8601String(),
            },
          ],
        }),
        'pass',
      );

      final plan = await service.planImport(envelope: envelope, passphrase: 'pass');
      await expectLater(
        service.restore(plan: plan, onProgress: (_, __) {}),
        throwsA(isA<BackupContentInvalid>()),
      );
      expect(await CardRepository(DatabaseHelper.instance).getAllCards(), isEmpty);
    });

    test('a dismissed prompt part way through a restore writes nothing', () async {
      final created = DateTime.parse('2026-03-03T00:00:00.000');
      final backup = VaultBackup.now(
        cards: List.generate(
          3,
          (i) => BackupCard(
            nickname: 'Card $i',
            cardBrand: 'Visa',
            lastFourDigits: '000$i',
            secrets: {'cardNumber': '411111111111111$i'},
            createdAt: created.add(Duration(days: i)),
            updatedAt: created.add(Duration(days: i)),
            isPinnedToTop: false,
            isPinnedToHomescreen: false,
          ),
        ),
        ids: const [],
      );

      final plan = await service.planImport(
        envelope: await bundle.seal(backup.encode(), 'pass'),
        passphrase: 'pass',
      );

      vault.failEncryptOnCall = 2;
      await expectLater(
        service.restore(plan: plan, onProgress: (_, __) {}),
        throwsA(isA<VaultAuthCancelled>()),
      );

      final cards = await CardRepository(DatabaseHelper.instance).getAllCards();
      expect(cards, isEmpty, reason: 'a partial restore must not survive');
    });
  });
}
