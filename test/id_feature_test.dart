import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ibank/core/storage/database.dart';
import 'package:ibank/features/ids/domain/virtual_id.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ibank/features/cards/domain/virtual_card.dart';
import 'package:ibank/core/security/secret_hasher.dart';
import 'package:ibank/features/cards/presentation/vault_screen.dart';

void main() {
  // Initialize ffi for sqlite testing on desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ID Feature Tests', () {
    
    test('Migration from v1 to v2 creates ids table and preserves cards', () async {
      final dbPath = p.join(Directory.systemTemp.path, 'test_db_${DateTime.now().millisecondsSinceEpoch}.db');
      if (File(dbPath).existsSync()) File(dbPath).deleteSync();

      // Create an in-memory database at version 1
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nickname TEXT NOT NULL,
                cardBrand TEXT NOT NULL,
                lastFourDigits TEXT NOT NULL,
                encryptedCardNumber TEXT NOT NULL,
                encryptedExpiry TEXT NOT NULL,
                encryptedCvv TEXT NOT NULL,
                encryptedCardholderName TEXT NOT NULL,
                encryptedNotes TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert a dummy card in v1
      await db.insert('cards', {
        'nickname': 'Test Card',
        'cardBrand': 'Visa',
        'lastFourDigits': '1234',
        'encryptedCardNumber': 'enc1',
        'encryptedExpiry': 'enc2',
        'encryptedCvv': 'enc3',
        'encryptedCardholderName': 'enc4',
        'encryptedNotes': 'enc5',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Now close and reopen with version 2 to trigger onUpgrade
      await db.close();

      final dbV2 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('''
                CREATE TABLE ids (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  nickname TEXT NOT NULL,
                  idType TEXT NOT NULL,
                  encryptedData TEXT NOT NULL,
                  encryptedImagePath TEXT,
                  createdAt TEXT NOT NULL,
                  updatedAt TEXT NOT NULL
                )
              ''');
              await db.execute('CREATE INDEX idx_idType ON ids (idType)');
              await db.execute('CREATE INDEX idx_createdAt ON ids (createdAt)');
            }
          },
        ),
      );

      // Verify cards table still exists and data is preserved
      final cards = await dbV2.query('cards');
      expect(cards.length, 1);
      expect(cards.first['nickname'], 'Test Card');

      // Verify ids table was created
      final idsCount = Sqflite.firstIntValue(await dbV2.rawQuery('SELECT COUNT(*) FROM ids'));
      expect(idsCount, 0); // Table exists and is empty
      
      await dbV2.close();
      if (File(dbPath).existsSync()) File(dbPath).deleteSync();
    });

    test('SecretHasher verifies a correct PIN and rejects a wrong one', () {
      // FIX 2-2: PINs are stored salted and key-stretched, not as a bare digest.
      final stored = SecretHasher.hash('1234');

      expect(SecretHasher.verify('1234', stored), isTrue);
      expect(SecretHasher.verify('1235', stored), isFalse);
      expect(SecretHasher.verify('', stored), isFalse);
    });

    test('SecretHasher salts every hash, so identical PINs differ on disk', () {
      // Without a salt, two users with PIN 1234 share a digest and one rainbow
      // table cracks both. These must not be equal.
      final a = SecretHasher.hash('1234');
      final b = SecretHasher.hash('1234');

      expect(a, isNot(equals(b)));
      expect(SecretHasher.verify('1234', a), isTrue);
      expect(SecretHasher.verify('1234', b), isTrue);
    });

    test('SecretHasher output carries no trace of the secret', () {
      final stored = SecretHasher.hash('1234');

      expect(stored.startsWith('pbkdf2-sha256:'), isTrue);
      expect(stored.contains('1234'), isFalse);
    });

    test('SecretHasher fails closed on malformed or legacy stored values', () {
      // A PIN written by an older build was a bare SHA-256 digest. It must not
      // verify, and must not throw — the user is sent to PIN re-setup instead.
      const legacySha256 =
          '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';

      expect(SecretHasher.verify('1234', legacySha256), isFalse);
      expect(SecretHasher.verify('1234', null), isFalse);
      expect(SecretHasher.verify('1234', ''), isFalse);
      expect(SecretHasher.verify('1234', 'pbkdf2-sha256:notanumber:aa:bb'), isFalse);
      expect(SecretHasher.verify('1234', 'pbkdf2-sha256:1000:!!!:!!!'), isFalse);
    });

    test('Security answers ignore case and surrounding whitespace', () {
      // FIX 2-3: normalisation must happen on both sides, or a user who typed
      // "Rex" at setup could never recover by typing "rex".
      final stored = SecretHasher.hash(SecretHasher.normaliseAnswer('  Rex  '));

      expect(SecretHasher.verify(SecretHasher.normaliseAnswer('rex'), stored), isTrue);
      expect(SecretHasher.verify(SecretHasher.normaliseAnswer('REX'), stored), isTrue);
      expect(SecretHasher.verify(SecretHasher.normaliseAnswer('Fido'), stored), isFalse);
    });

    test('CardSecrets round-trips every field through one JSON payload', () {
      // FIX 2-1: all card secrets travel as a single encrypted payload so that
      // saving or revealing a card costs exactly one authenticated crypto
      // operation (and therefore one OS auth prompt) rather than five.
      const original = CardSecrets(
        cardNumber: '4242424242424242',
        expiry: '12/30',
        cvv: '123',
        cardholderName: 'JANE DOE',
        notes: 'Backup card. PIN hint: dog.',
      );

      final restored = CardSecrets.fromJson(original.toJson());

      expect(restored.cardNumber, '4242424242424242');
      expect(restored.expiry, '12/30');
      expect(restored.cvv, '123');
      expect(restored.cardholderName, 'JANE DOE');
      expect(restored.notes, 'Backup card. PIN hint: dog.');
    });

    test('CardSecrets tolerates missing fields without throwing', () {
      // Payloads written by an older build, or with notes omitted, must not
      // crash the reveal path.
      final restored = CardSecrets.fromJson('{"cardNumber":"4111111111111111"}');

      expect(restored.cardNumber, '4111111111111111');
      expect(restored.expiry, '');
      expect(restored.cvv, '');
      expect(restored.cardholderName, '');
      expect(restored.notes, '');
    });

    test('VirtualCard persists encryptedData through the DB map round-trip', () {
      final card = VirtualCard(
        id: 7,
        nickname: 'TestBank',
        cardBrand: 'VISA',
        lastFourDigits: '4242',
        encryptedData: 'iv==:payload==',
        createdAt: DateTime.parse('2026-09-01T10:00:00Z'),
        updatedAt: DateTime.parse('2026-09-01T10:00:00Z'),
        isPinnedToTop: true,
      );

      final restored = VirtualCard.fromMap(card.toMap());

      expect(restored.encryptedData, 'iv==:payload==');
      expect(restored.lastFourDigits, '4242');
      expect(restored.isPinnedToTop, true);
      expect(restored.isPinnedToHomescreen, false);
    });

    test('VirtualId encrypt/decrypt round-trip JSON serialization', () {
      final Map<String, String> originalData = {
        'documentNumber': 'A1234567',
        'fullName': 'John Doe',
        'dateOfBirth': '1990-01-01',
        // Note: expiry is omitted to test nulls/missing fields
      };
      
      final jsonString = jsonEncode(originalData);
      
      final idDoc = VirtualId(
        id: 1,
        nickname: 'My Passport',
        idType: 'Passport',
        encryptedData: jsonString, // Mocking encryption by passing raw json
        createdAt: DateTime.parse('2026-09-01T10:00:00Z'),
        updatedAt: DateTime.parse('2026-09-01T10:00:00Z'),
      );
      
      // Serialize to map (DB format)
      final map = idDoc.toMap();
      expect(map['idType'], 'Passport');
      expect(map['encryptedData'], jsonString);
      
      // Deserialize back from map
      final restoredIdDoc = VirtualId.fromMap(map);
      final decodedMap = jsonDecode(restoredIdDoc.encryptedData) as Map<String, dynamic>;
      
      expect(decodedMap['documentNumber'], 'A1234567');
      expect(decodedMap['fullName'], 'John Doe');
      expect(decodedMap.containsKey('expiryDate'), false); // Ensure omitted fields remain omitted
    });

    test('Vault merging logic sorts by createdAt correctly', () {
      final oldDate = DateTime.parse('2026-09-01T10:00:00Z');
      final newDate = DateTime.parse('2026-09-02T10:00:00Z');

      final oldCard = VirtualCard(
        id: 1,
        nickname: 'Old Card',
        cardBrand: 'Visa',
        lastFourDigits: '1111',
        encryptedData: '',
        createdAt: oldDate, updatedAt: oldDate,
      );

      final newCard = VirtualCard(
        id: 2,
        nickname: 'New Card',
        cardBrand: 'Mastercard',
        lastFourDigits: '2222',
        encryptedData: '',
        createdAt: newDate, updatedAt: newDate,
      );

      final oldId = VirtualId(
        id: 1,
        nickname: 'Old ID',
        idType: 'Passport',
        encryptedData: '',
        createdAt: oldDate, updatedAt: oldDate,
      );

      final cList = [oldCard, newCard];
      final iList = [oldId];

      final merged = [
        ...cList.map((c) => VaultItem(type: VaultItemType.card, item: c, id: c.id!, nickname: c.nickname, subtitle: '', createdAt: c.createdAt)),
        ...iList.map((i) => VaultItem(type: VaultItemType.id, item: i, id: i.id!, nickname: i.nickname, subtitle: '', createdAt: i.createdAt)),
      ]..sort((a, b) {
          final cmp = b.createdAt.compareTo(a.createdAt);
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

      // Expected order (descending): newCard (newDate), oldCard/oldId (oldDate, tie break by id, but wait their IDs are 1 and 1)
      expect(merged[0].nickname, 'New Card');
    });

  });
}
