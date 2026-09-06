import 'dart:io';

import 'package:local_auth/local_auth.dart';
import 'package:ibank/core/security/authentication_service.dart';

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
      expect(PassphraseDialog.strengthOf('short').band, PassphraseStrength.tooShort);
      expect(PassphraseDialog.strengthOf('short').weak, isTrue);
      expect(PassphraseDialog.strengthOf('1234567').weak, isTrue);
    });

    test('meeting the floor with one character class is still called weak', () {
      // The floor is a minimum, not a target. Somebody typing eight lowercase
      // letters should be told it is thin rather than congratulated.
      final result = PassphraseDialog.strengthOf('aaaaaaaa');
      expect(result.weak, isTrue);
      expect(result.band, PassphraseStrength.weak);
    });

    test('length and variety both improve the reading', () {
      final short = PassphraseDialog.strengthOf('Ab3\$abcd');
      final long = PassphraseDialog.strengthOf('Ab3\$abcdefghijklmnop');
      expect(long.fraction, greaterThan(short.fraction));
      expect(long.band, PassphraseStrength.strong);
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
      expect(result.band, PassphraseStrength.empty);
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

  group("Changing your mind is not a failure", () {
    // Reported from the device twice, in two different places: raise the
    // fingerprint prompt, press the phone's Back button, and Karde answered
    // "Could not confirm it was you, try again" — or, opening the app,
    // "Biometric authentication failed, please use PIN". The user had not
    // failed at anything. They had decided not to, which is their right, and
    // Karde told them off for it.
    //
    // The cause was that the plugin raises an exception for a deliberate stop
    // exactly as it does for a genuine fault, and Karde caught them all the same
    // way. The information to tell them apart was always there in the code.

    test("pressing Back or cancel says nothing at all", () {
      for (final code in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.userRequestedFallback,
        LocalAuthExceptionCode.timeout,
        LocalAuthExceptionCode.authInProgress,
      ]) {
        expect(
          classifyBiometricFailure(code),
          BiometricFailure.silent,
          reason: "$code is the user or the system stopping on purpose. "
              "Whatever happens next — the PIN screen, or staying put — is "
              "answer enough without an error message.",
        );
      }
    });

    test("a phone with nothing to check against says so", () {
      for (final code in [
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.noCredentialsSet,
      ]) {
        expect(classifyBiometricFailure(code), BiometricFailure.notEnrolled);
      }
    });

    test("a locked-out sensor is not an invitation to try again", () {
      for (final code in [
        LocalAuthExceptionCode.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout,
      ]) {
        expect(
          classifyBiometricFailure(code),
          BiometricFailure.lockedOut,
          reason: "Trying again is precisely what will not work here.",
        );
      }
    });

    test("anything unrecognised blames the phone, not the user", () {
      // The plugin documents this enum as open to new values, so there will be
      // codes this build has never heard of. Guessing turns into an accusation.
      expect(
        classifyBiometricFailure(LocalAuthExceptionCode.deviceError),
        BiometricFailure.unavailable,
      );
      expect(
        classifyBiometricFailure(LocalAuthExceptionCode.uiUnavailable),
        BiometricFailure.unavailable,
      );
    });
  });

  group("Pages that can grow must be able to scroll", () {
    // Two device reports with one cause. The security-question picker was a
    // Column that overflowed once a row gained an "Already used above" line, so
    // the last question sat clipped behind the navigation bar and read as a
    // second greyed-out option. The home screen was a Column that overflowed
    // once the backup reminder appeared, so the Add a card and Add an ID buttons
    // were cut off entirely — reported as the reminder "removing" them.
    //
    // Neither page had any way to scroll to what it was hiding, and a large
    // system font size would have done the same to both without any of our
    // widgets appearing at all.
    const growingPages = {
      "lib/features/home/presentation/dashboard_screen.dart":
          "the security warning, the fingerprint-change notice and the backup "
              "reminder all appear above the Add buttons",
      "lib/features/onboarding/presentation/security_questions_setup_screen.dart":
          "the question picker grows when a question is taken or wraps to two "
              "lines",
    };

    growingPages.forEach((path, why) {
      test("$path can scroll", () {
        final source = File(path).readAsStringSync();
        expect(
          source.contains("SingleChildScrollView") ||
              source.contains("ListView") ||
              source.contains("CustomScrollView"),
          isTrue,
          reason: "$path must be scrollable: $why.",
        );
      });
    });
  });

  group("Screens must describe the security the user actually has", () {
    // The rule behind all of these: never show recovery for something Karde
    // cannot recover, and never offer to "change" something never configured.
    //
    // Asserted against the source because each one is a property of how screens
    // hand off to each other, which no widget test of a single screen would
    // notice — the same reasoning as the navigator-stack group below.
    //
    // Line breaks in the source are not the subject of any of these rules, so
    // they are collapsed before matching. Otherwise a reformat would fail a test
    // about security wording, and the next person would learn to ignore it.
    String flat(String source) => source.replaceAll(RegExp(r"\s+"), " ");

    test("Phone Lock at onboarding does not lead to recovery options", () {
      // Karde does not hold the device passcode or the fingerprints. If those
      // are lost the way back is through Android, so a recovery screen offered
      // to a Phone Lock user recovers nothing: its questions would reset a PIN
      // that does not exist, and its "Phone Lock" option offered the phone's own
      // lock as the way back from the phone's own lock.
      final source =
          File("lib/features/onboarding/presentation/lock_setup_screen.dart")
              .readAsStringSync();

      expect(
        source.contains("RecoverySetupScreen"),
        isFalse,
        reason: "Phone Lock must finish onboarding, not hand off to recovery "
            "setup. Karde PIN and Both still reach it, by way of PIN setup.",
      );
      expect(
        source.contains("loc.phoneLockPinHint"),
        isTrue,
        reason: "Removing the recovery step leaves nothing in the flow that "
            "mentions the Karde PIN again, so the option has to say a PIN can "
            "still be added later.",
      );
    });

    test("no PIN screen is raised for a PIN that does not exist", () {
      // Both entry points, not one. Cancelling the fingerprint prompt used to
      // hand a Phone Lock user the PIN screen, which found no stored hash,
      // offered to CREATE a PIN, and counted that creation as a successful
      // sign-in — so declining the only real factor was a way in.
      final source =
          File("lib/core/security/authentication_service.dart").readAsStringSync();

      final guards =
          "if (!hasKardePin) return false;".allMatches(flat(source)).length;
      expect(
        guards,
        2,
        reason: "authenticate() and authenticateAppStartup() must each refuse "
            "to fall back to the PIN screen when no Karde PIN exists.",
      );
      expect(
        source.contains("settings.hasKardePin()"),
        isTrue,
        reason: "PIN existence is a fact in storage. getRequirePinLock() "
            "reports a setting, and the two disagree for exactly the Phone "
            "Lock user this guard protects.",
      );
    });

    test("Settings names what the tap will do", () {
      final source =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsStringSync();

      expect(
        source.contains("hasKardePinProvider"),
        isTrue,
        reason: "The PIN row's wording must follow whether a PIN exists.",
      );
      expect(
        flat(source).contains("hasKardePin ? loc.changePin : loc.createKardePin"),
        isTrue,
        reason: '"Change Karde PIN" for someone who has never had one offers '
            "to change a thing that does not exist.",
      );
      expect(
        source.contains("loc.settingsSecurityQuestionsAdd"),
        isTrue,
        reason: "The questions row must say Add when there are none. That "
            "state is reachable from Phone Lock onboarding, and from anyone "
            "who chose Phone Lock or No Recovery at the recovery step.",
      );
      expect(
        source.contains("RecoverySetupScreen(fromSettings: true)"),
        isTrue,
        reason: "Creating a PIN from Settings is the first moment recovery "
            "means anything, so it has to be offered there.",
      );
    });

    test("the questions screen takes its wording from storage", () {
      // isChanging answers a different question: where the screen returns to and
      // which palette it uses. Settings can reach it with nothing saved yet.
      final source = File(
        "lib/features/onboarding/presentation/security_questions_setup_screen.dart",
      ).readAsStringSync();

      expect(
        flat(source).contains(
          "widget.isChanging ? loc.changeSecurityQuestionsTitle",
        ),
        isFalse,
        reason: "The title must not call it a change merely because the screen "
            "was reached from Settings.",
      );
      expect(
        flat(source).contains(
          "_hasExistingQuestions ? loc.changeSecurityQuestionsTitle",
        ),
        isTrue,
        reason: "Add-versus-change wording must follow the stored questions.",
      );
    });
  });

  group("Erasing the vault must drop every cached answer", () {
    // Every provider in settings_repository.dart caches something read from
    // storage — a StateNotifier reads it once in its constructor, a
    // FutureProvider holds the resolved value for the life of the process.
    // Wiping storage does nothing to any of them, so each has to be invalidated
    // by hand, and one left out is invisible until someone erases their vault.
    //
    // Both of the ones added for Phase 10 were missed exactly that way. On the
    // device, after an erase and a fresh Phone Lock onboarding, Settings still
    // offered to "Change Karde PIN" — the answer cached before the wipe,
    // describing a PIN that no longer existed.
    //
    // Listing the providers from the source rather than naming them here means a
    // provider added later is covered without anyone remembering to come back.
    test("resetAllVaultState covers every settings provider", () {
      final repository =
          File("lib/core/storage/settings_repository.dart").readAsStringSync();
      final reset = File("lib/core/storage/vault_reset.dart").readAsStringSync();

      // Not caches: one is overridden in main.dart, the other is a plain
      // wrapper around it that holds no state of its own.
      const stateless = {"sharedPreferencesProvider", "settingsRepositoryProvider"};

      final providers = RegExp(r"^final (\w+Provider) =", multiLine: true)
          .allMatches(repository)
          .map((m) => m.group(1)!)
          .where((name) => !stateless.contains(name))
          .toList();

      expect(providers, isNotEmpty, reason: "the regex should find providers");

      for (final provider in providers) {
        expect(
          reset.contains("ref.invalidate($provider)"),
          isTrue,
          reason: "$provider caches state read from storage, so erasing the "
              "vault must invalidate it. Without that, Settings and the "
              "dashboard describe the vault the user had before the erase.",
        );
      }
    });
  });

  group("Cached answers must not outlive what they describe", () {
    // resetAllVaultState covers the erase. It cannot cover the rest: a PIN is
    // created during onboarding, and questions are set at the recovery step,
    // both with Settings nowhere on screen to notice. A FutureProvider that
    // outlives its listeners keeps handing out the answer it worked out before
    // any of that happened.
    //
    // Seen on the device: erase the vault, set up again choosing Karde PIN, and
    // Settings still offered to "Create Karde PIN" for the PIN that had just
    // been made. autoDispose drops the answer when the last listener goes, so
    // every fresh visit to Settings asks storage again.
    test("the what-is-configured providers are autoDispose", () {
      final source =
          File("lib/core/storage/settings_repository.dart").readAsStringSync();

      for (final provider in [
        "hasKardePinProvider",
        "hasSecurityQuestionsProvider",
      ]) {
        expect(
          RegExp("final $provider = FutureProvider.autoDispose")
              .hasMatch(source),
          isTrue,
          reason: "$provider answers a question that changes while nothing is "
              "listening, so it must not cache across listeners.",
        );
      }
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
