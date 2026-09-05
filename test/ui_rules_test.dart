import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/features/backup/presentation/widgets/passphrase_dialog.dart';
import 'package:ibank/features/cards/domain/virtual_card.dart';
import 'package:ibank/features/ids/domain/virtual_id.dart';
import 'package:ibank/features/ids/presentation/add_id_screen.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ID form date rules', () {
    test('parses a well-formed date', () {
      expect(parseIdDate('09/03/2026'), DateTime(2026, 3, 9));
      expect(parseIdDate('  09/03/2026  '), DateTime(2026, 3, 9));
    });

    test('rejects a day that does not exist in that month', () {
      // The one that matters. DateTime(2030, 2, 31) does not throw — it rolls
      // forward to 3 March — so a naive parse would silently accept it and store
      // a date the user never chose.
      expect(parseIdDate('31/02/2030'), isNull);
      expect(parseIdDate('31/04/2026'), isNull);
      expect(parseIdDate('30/02/2024'), isNull, reason: 'even in a leap year');
      expect(parseIdDate('29/02/2024'), DateTime(2024, 2, 29),
          reason: '2024 is a leap year, so this one is real');
      expect(parseIdDate('29/02/2026'), isNull, reason: '2026 is not');
    });

    test('rejects malformed input rather than guessing', () {
      expect(parseIdDate(null), isNull);
      expect(parseIdDate(''), isNull);
      expect(parseIdDate('   '), isNull);
      expect(parseIdDate('2026-03-09'), isNull);
      expect(parseIdDate('09/03'), isNull);
      expect(parseIdDate('aa/bb/cccc'), isNull);
    });

    test('formatting round-trips through parsing', () {
      final date = DateTime(2026, 3, 9);
      expect(formatIdDate(date), '09/03/2026');
      expect(parseIdDate(formatIdDate(date)), date);
    });

    test('an expiry before its issue date is refused', () {
      final issue = DateTime(2026, 3, 9);

      expect(
        expiryPrecedesIssue(issue: issue, expiry: DateTime(2026, 3, 8)),
        isTrue,
        reason: 'this is the bug that was reported — it must not be accepted',
      );
      expect(
        expiryPrecedesIssue(issue: issue, expiry: issue),
        isTrue,
        reason: 'a document that expires the instant it is issued is not valid',
      );
      expect(expiryPrecedesIssue(issue: issue, expiry: DateTime(2026, 3, 10)), isFalse);
    });

    test('an expiry in the past is allowed, so long as it follows the issue', () {
      // Keeping an expired passport in a vault is entirely reasonable.
      expect(
        expiryPrecedesIssue(issue: DateTime(2010, 1, 1), expiry: DateTime(2020, 1, 1)),
        isFalse,
      );
    });

    test('a missing date on either side is not an error yet', () {
      // Blank fields are the "required" check's business, not this one's.
      expect(expiryPrecedesIssue(issue: null, expiry: DateTime(2026, 1, 1)), isFalse);
      expect(expiryPrecedesIssue(issue: DateTime(2026, 1, 1), expiry: null), isFalse);
      expect(expiryPrecedesIssue(issue: null, expiry: null), isFalse);
    });
  });

  group('Backup passphrase strength', () {
    test('the minimum is enforced as a floor', () {
      expect(PassphraseDialog.minimumLength, 8);
      expect(PassphraseDialog.strengthOf('short').label, 'Too short');
      expect(PassphraseDialog.strengthOf('short').weak, isTrue);
      expect(PassphraseDialog.strengthOf('1234567').weak, isTrue);
    });

    test('meeting the floor with one character class is still called weak', () {
      // The floor is a minimum, not a target. Somebody typing eight lowercase
      // letters should be told it is thin rather than congratulated.
      final result = PassphraseDialog.strengthOf('aaaaaaaa');
      expect(result.weak, isTrue);
      expect(result.label, 'Weak');
    });

    test('length and variety both improve the reading', () {
      final short = PassphraseDialog.strengthOf('Ab3\$abcd');
      final long = PassphraseDialog.strengthOf('Ab3\$abcdefghijklmnop');
      expect(long.fraction, greaterThan(short.fraction));
      expect(long.label, 'Strong');
      expect(long.weak, isFalse);

      // A long passphrase of one class still beats a short mixed one, because
      // length dominates — which is what the hint text tells the user.
      expect(
        PassphraseDialog.strengthOf('correcthorsebatterystaple').fraction,
        greaterThan(PassphraseDialog.strengthOf('Ab3\$abcd').fraction),
      );
    });

    test('an empty passphrase reads as nothing at all', () {
      final result = PassphraseDialog.strengthOf('');
      expect(result.fraction, 0);
      expect(result.label, isEmpty);
    });
  });

  group('The hasPhoto flag', () {
    test('survives the card map round trip and defaults to false', () {
      final created = DateTime.parse('2026-01-01T00:00:00.000');
      final withPhoto = VirtualCard(
        nickname: 'With',
        cardBrand: 'Visa',
        lastFourDigits: '4242',
        encryptedData: 'iv:payload',
        hasPhoto: true,
        createdAt: created,
        updatedAt: created,
      );
      expect(VirtualCard.fromMap(withPhoto.toMap()).hasPhoto, isTrue);

      final without = VirtualCard(
        nickname: 'Without',
        cardBrand: 'Visa',
        lastFourDigits: '0000',
        encryptedData: 'iv:payload',
        createdAt: created,
        updatedAt: created,
      );
      expect(without.hasPhoto, isFalse);
      expect(VirtualCard.fromMap(without.toMap()).hasPhoto, isFalse);
    });

    test('survives the ID map round trip', () {
      final created = DateTime.parse('2026-01-01T00:00:00.000');
      final doc = VirtualId(
        nickname: 'Passport',
        idType: 'Passport',
        encryptedData: 'iv:payload',
        hasPhoto: true,
        createdAt: created,
        updatedAt: created,
      );
      expect(VirtualId.fromMap(doc.toMap()).hasPhoto, isTrue);
      expect(doc.copyWith(nickname: 'Renamed').hasPhoto, isTrue);
    });

    test('is readable from a summary row, so the list can badge without '
        'decrypting', () {
      // The whole reason the flag exists outside the encrypted payload.
      final summary = <String, dynamic>{
        'id': 1,
        'nickname': 'With photo',
        'cardBrand': 'Visa',
        'lastFourDigits': '4242',
        'hasPhoto': 1,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        // No encryptedData: list queries deliberately omit it.
      };
      final card = VirtualCard.fromMap(summary);
      expect(card.hasPhoto, isTrue);
      expect(card.encryptedData, isEmpty);
    });
  });

  group('Database migration to v6', () {
    test('both tables gain hasPhoto and existing rows default to 0', () async {
      final dbPath = p.join(
        Directory.systemTemp.path,
        'karde_v6_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      addTearDown(() {
        if (File(dbPath).existsSync()) File(dbPath).deleteSync();
      });

      final v5 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nickname TEXT NOT NULL,
                cardBrand TEXT NOT NULL,
                lastFourDigits TEXT NOT NULL,
                encryptedData TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE ids (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nickname TEXT NOT NULL,
                idType TEXT NOT NULL,
                encryptedData TEXT NOT NULL,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      await v5.insert('cards', {
        'nickname': 'Old card',
        'cardBrand': 'Visa',
        'lastFourDigits': '4242',
        'encryptedData': 'iv:payload',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      await v5.close();

      final v6 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 6,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 6) {
              await db.execute(
                'ALTER TABLE cards ADD COLUMN hasPhoto INTEGER DEFAULT 0',
              );
              await db.execute(
                'ALTER TABLE ids ADD COLUMN hasPhoto INTEGER DEFAULT 0',
              );
            }
          },
        ),
      );

      final row = (await v6.query('cards')).single;
      expect(row['nickname'], 'Old card');
      expect(row['encryptedData'], 'iv:payload', reason: 'additive migration');
      expect(row['hasPhoto'], 0,
          reason: 'a card from before the flag existed has no photo');

      await v6.close();
    });
  });

  group("Onboarding must not leave routes underneath the app", () {
    // Regression guard for a bug the user hit on the device: editing a card and
    // saving dropped them onto the language picker, vault apparently gone.
    //
    // Nothing was lost. Onboarding handed off to MainScaffold with
    // pushReplacement, which swaps only the TOP route — so the language,
    // lock-setup and PIN screens stayed on the stack underneath MainScaffold for
    // the entire life of the install. Any stray pop then surfaced one of them,
    // and the bottom of that stack is "Welcome to Karde".
    //
    // Every onboarding handoff must therefore clear the stack. Asserted against
    // the source because the failure is a navigator-stack property that no
    // widget test of a single screen would notice.
    const onboardingFiles = [
      "lib/features/onboarding/presentation/recovery_setup_screen.dart",
      "lib/features/onboarding/presentation/security_questions_setup_screen.dart",
      "lib/features/onboarding/presentation/pin_setup_screen.dart",
      "lib/features/onboarding/presentation/lock_setup_screen.dart",
    ];

    for (final path in onboardingFiles) {
      test("$path enters MainScaffold with pushAndRemoveUntil", () {
        final source = File(path).readAsStringSync();
        final marker = "const MainScaffold()";

        for (var i = source.indexOf(marker);
            i != -1;
            i = source.indexOf(marker, i + 1)) {
          final start = i - 260 < 0 ? 0 : i - 260;
          final preceding = source.substring(start, i);
          final call = preceding.lastIndexOf("Navigator.");
          if (call == -1) continue;
          final navigation = preceding.substring(call);

          expect(
            navigation.contains("pushReplacement"),
            isFalse,
            reason:
                "$path reaches MainScaffold via pushReplacement, which leaves "
                "the onboarding screens on the stack underneath it.",
          );
          expect(
            navigation.contains("pushAndRemoveUntil"),
            isTrue,
            reason: "$path must clear the stack when entering MainScaffold.",
          );
        }
      });
    }
  });
}
