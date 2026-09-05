import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/security/secret_hasher.dart';
import 'package:ibank/core/storage/database.dart';
import 'package:ibank/core/storage/settings_repository.dart';
import 'package:ibank/core/widgets/vault_photo_field.dart';
import 'package:ibank/features/cards/data/card_repository.dart';
import 'package:ibank/features/cards/domain/virtual_card.dart';
import 'package:ibank/features/ids/data/id_repository.dart';
import 'package:ibank/features/ids/domain/virtual_id.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory stand-in for the Keystore-backed secure storage.
///
/// [SettingsRepository] takes the storage as a constructor argument precisely so
/// this is possible; the real implementation is a platform channel and would
/// throw MissingPluginException here.
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

Uint8List fakeJpeg(int seed) =>
    Uint8List.fromList(List.generate(16, (i) => (i + seed) % 256));

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database migration to v5', () {
    test('cards gain the vestigial photo column and existing rows survive',
        () async {
      final dbPath = p.join(
        Directory.systemTemp.path,
        'karde_v5_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      addTearDown(() {
        if (File(dbPath).existsSync()) File(dbPath).deleteSync();
      });

      final v4 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nickname TEXT NOT NULL,
                cardBrand TEXT NOT NULL,
                lastFourDigits TEXT NOT NULL,
                encryptedData TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL,
                isPinnedToTop INTEGER DEFAULT 0,
                isPinnedToHomescreen INTEGER DEFAULT 0
              )
            ''');
          },
        ),
      );
      await v4.insert('cards', {
        'nickname': 'Existing card',
        'cardBrand': 'Visa',
        'lastFourDigits': '4242',
        'encryptedData': 'iv:payload',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'isPinnedToTop': 1,
      });
      await v4.close();

      final v5 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 5,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 5) {
              await db.execute(
                'ALTER TABLE cards ADD COLUMN encryptedImagePath TEXT',
              );
            }
          },
        ),
      );

      // Unlike the v4 step, which dropped the table, this migration is additive:
      // nothing about how the existing columns are encrypted has changed.
      final rows = await v5.query('cards');
      expect(rows.single['nickname'], 'Existing card');
      expect(rows.single['encryptedData'], 'iv:payload');
      expect(rows.single['isPinnedToTop'], 1);

      await v5.close();
    });
  });

  group('Payload encoding carries the photo', () {
    test('CardSecrets round-trips a photo alongside the card fields', () {
      final image = base64Encode(fakeJpeg(3));
      final restored = CardSecrets.fromJson(
        CardSecrets(
          cardNumber: '4242424242424242',
          expiry: '12/30',
          cvv: '123',
          cardholderName: 'JANE DOE',
          notes: 'a note',
          image: image,
        ).toJson(),
      );

      expect(restored.cardNumber, '4242424242424242');
      expect(restored.notes, 'a note');
      expect(restored.image, image);
      expect(restored.hasImage, isTrue);
    });

    test('a card with no photo writes no image key at all', () {
      const secrets = CardSecrets(
        cardNumber: '4242424242424242',
        expiry: '12/30',
        cvv: '123',
        cardholderName: 'JANE DOE',
      );

      expect(jsonDecode(secrets.toJson()), isNot(contains('image')));
      expect(CardSecrets.fromJson(secrets.toJson()).hasImage, isFalse);
    });

    test('IdPayload keeps the photo out of the user-visible fields', () {
      final image = base64Encode(fakeJpeg(5));
      final payload = IdPayload.encode(
        fields: {'documentNumber': 'X1234567', 'fullName': 'JANE DOE'},
        image: image,
      );

      expect(IdPayload.imageOf(payload), image);
      // The critical property: anything that walks the payload as "the user's
      // fields" must not see the photo. Without this the base64 blob would be
      // rendered as a detail row on the ID screen, and copied into a text field
      // by the edit form.
      expect(IdPayload.fieldsOf(payload), {
        'documentNumber': 'X1234567',
        'fullName': 'JANE DOE',
      });
      expect(IdPayload.fieldsOf(payload).containsKey(IdPayload.photoKey), isFalse);
    });

    test('a document written before photos existed still decodes', () {
      // No photo key at all, which is every ID saved before this feature.
      final payload = <String, dynamic>{'documentNumber': 'X1'};
      expect(IdPayload.imageOf(payload), isNull);
      expect(IdPayload.fieldsOf(payload), {'documentNumber': 'X1'});
    });
  });

  group('VaultPhotoController', () {
    test('reports the photo in the form the payload carries it', () {
      final controller = VaultPhotoController();
      expect(controller.hasPhoto, isFalse);
      expect(controller.imageBase64, isNull);

      final bytes = fakeJpeg(7);
      controller.select(bytes);

      expect(controller.hasPhoto, isTrue);
      expect(controller.imageBase64, base64Encode(bytes));
      expect(base64Decode(controller.imageBase64!), bytes);
    });

    test('adopting a decrypted photo behaves as a selection', () {
      final controller = VaultPhotoController();
      controller.adopt(fakeJpeg(2));
      expect(controller.hasPhoto, isTrue);
    });

    test('clearing removes the photo from the next save', () {
      final controller = VaultPhotoController()..select(fakeJpeg(1));
      controller.clear();
      expect(controller.hasPhoto, isFalse);
      expect(controller.imageBase64, isNull);
    });

    test('listeners fire so the form redraws on every change', () {
      var notifications = 0;
      final controller = VaultPhotoController()
        ..addListener(() => notifications++);

      controller.select(fakeJpeg(1));
      controller.clear();
      expect(notifications, 2);
    });
  });

  group('List queries and the payload they leave behind', () {
    late CardRepository cards;
    late IdRepository ids;
    late Database db;

    setUp(() async {
      db = await DatabaseHelper.instance.database;
      await db.delete(DatabaseHelper.tableCards);
      await db.delete(DatabaseHelper.tableIds);
      cards = CardRepository(DatabaseHelper.instance);
      ids = IdRepository(DatabaseHelper.instance);
    });

    VirtualCard sample({String nickname = 'Card'}) => VirtualCard(
          nickname: nickname,
          cardBrand: 'Visa',
          lastFourDigits: '4242',
          encryptedData: 'iv:the-real-payload',
          createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2026-01-01T00:00:00.000'),
        );

    test('the list carries no payload, and payloadFor fetches it', () async {
      await cards.insertCard(sample());

      final listed = (await cards.getAllCards()).single;
      // Deliberately absent: the payload holds the card photo, and dragging it
      // through memory on every rebuild to draw a nickname would be wasteful.
      expect(listed.encryptedData, isEmpty);
      expect(listed.nickname, 'Card');

      expect(await cards.payloadFor(listed), 'iv:the-real-payload');
    });

    test('pinning a card from the list does not blank its payload', () async {
      await cards.insertCard(sample());
      final listed = (await cards.getAllCards()).single;

      // Exactly what the vault screen does when the pin is toggled. The model
      // came from the list, so its encryptedData is empty; writing it back
      // verbatim would destroy the card while appearing to succeed.
      await cards.updateCard(listed.copyWith(isPinnedToTop: true));

      final after = (await cards.getAllCards()).single;
      expect(after.isPinnedToTop, isTrue);
      expect(await cards.payloadFor(after), 'iv:the-real-payload');
    });

    test('pinning an ID from the list does not blank its payload', () async {
      await ids.insertId(
        VirtualId(
          nickname: 'Passport',
          idType: 'Passport',
          encryptedData: 'iv:the-real-id-payload',
          createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2026-01-01T00:00:00.000'),
        ),
      );
      final listed = (await ids.getAllIds()).single;
      expect(listed.encryptedData, isEmpty);

      await ids.updateId(listed.copyWith(isPinnedToHomescreen: true));

      final after = (await ids.getAllIds()).single;
      expect(after.isPinnedToHomescreen, isTrue);
      expect(await ids.payloadFor(after), 'iv:the-real-id-payload');
    });

    test('a real edit still replaces the payload', () async {
      await cards.insertCard(sample());
      final listed = (await cards.getAllCards()).single;

      await cards.updateCard(listed.copyWith(encryptedData: 'iv:brand-new'));

      expect(await cards.payloadFor((await cards.getAllCards()).single),
          'iv:brand-new');
    });

    test('payloadFor trusts a model that already has one', () async {
      // A card straight from a save has never been through the list projection.
      expect(await cards.payloadFor(sample()), 'iv:the-real-payload');
    });
  });

  group('Security question answers', () {
    late SettingsRepository settings;
    late FakeSecureStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = FakeSecureStorage();
      settings = SettingsRepository(await SharedPreferences.getInstance(), storage);
    });

    test('answers stored as typed verify as typed', () async {
      await settings.setSecurityQuestions(
        'In what city were you born?',
        'Addis Ababa',
        'What is your favorite book?',
        'Dune',
      );

      expect(
        await settings.verifySecurityAnswers('Addis Ababa', 'Dune'),
        isTrue,
      );
      // Normalisation: capitalisation and stray spaces must not lock a user out
      // of their own recovery flow.
      expect(
        await settings.verifySecurityAnswers('  addis ababa ', 'DUNE'),
        isTrue,
      );
      expect(
        await settings.verifySecurityAnswers('Addis Ababa', 'Not Dune'),
        isFalse,
      );
    });

    test('a pre-hashed answer does not verify, which is what broke recovery',
        () async {
      // The setup screen used to SHA-256 the answer before handing it over, so
      // what was stored was PBKDF2(sha256(answer)) while verification computed
      // PBKDF2(answer). The two could never match and recovery could not succeed
      // for anyone. This pins the contract: the repository hashes, callers pass
      // the answer as the user typed it.
      final preHashed = SecretHasher.hash('Addis Ababa');
      await settings.setSecurityQuestions(
        'In what city were you born?',
        preHashed,
        'What is your favorite book?',
        SecretHasher.hash('Dune'),
      );

      expect(
        await settings.verifySecurityAnswers('Addis Ababa', 'Dune'),
        isFalse,
        reason: 'double hashing is exactly the shipped bug this guards against',
      );
    });

    test('the stored answer bears no resemblance to what was typed', () async {
      await settings.setSecurityQuestions('q1', 'Rufus', 'q2', 'Dune');

      final stored = storage.values['security_answer_1'];
      expect(stored, isNotNull);
      expect(stored, isNot(contains('Rufus')));
      expect(stored, isNot(contains('rufus')));

      // The question itself is not a secret and is stored in the clear, because
      // it has to be shown back to the user before they can answer it.
      expect(storage.values['security_question_1'], 'q1');
    });
  });
}
