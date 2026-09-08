import 'dart:convert';
import 'dart:io';

import 'dart:ui' show Offset, Rect;

import 'package:ibank/core/notifications/expiry_notifications.dart';
import 'package:ibank/core/utils/expiry.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ibank/core/security/authentication_service.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/features/backup/presentation/widgets/passphrase_dialog.dart';
import 'package:ibank/core/widgets/guided_camera_screen.dart';
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

  group('Passphrases people actually reach for', () {
    // Reported from the device: the automatic backup accepted "12345678910".
    // Eleven characters scored well on length, and the single point lost for
    // using only digits was not enough to matter — so a purely numeric
    // passphrase passed a check meant to refuse weak ones.
    //
    // Eleven digits is ten to the eleventh. Eleven mixed characters is nearer
    // ten to the twenty-first. No scheme that merely subtracts a penalty for
    // low variety can express a difference of a hundred billion times.

    test('digits only is weak however long it looks', () {
      for (final digitsOnly in ['12345678', '12345678910', '0000000000000']) {
        expect(
          PassphraseDialog.strengthOf(digitsOnly).weak,
          isTrue,
          reason: '$digitsOnly draws on ten characters per position, which is '
              'what an attacker guessing offline actually faces.',
        );
      }
    });

    test('so is a short run of one kind of letter', () {
      expect(PassphraseDialog.strengthOf('password').weak, isTrue);
      expect(PassphraseDialog.strengthOf('ABCDEFGH').weak, isTrue);
    });

    test('mixing kinds is what makes a short one workable', () {
      // Eight characters is the floor, and it only clears the bar by using the
      // whole keyboard.
      expect(PassphraseDialog.strengthOf('Tr7!kQ2z').weak, isFalse);
    });

    test('a phrase of ordinary words is not punished for being lowercase', () {
      // The check must not push people away from the one kind of passphrase
      // that is both strong and memorable.
      final phrase = PassphraseDialog.strengthOf('correct horse battery staple');
      expect(phrase.weak, isFalse);
      expect(phrase.band, PassphraseStrength.strong);
    });

    test('anything under the floor is refused before strength is discussed', () {
      expect(PassphraseDialog.strengthOf('Tr7!kQ').band,
          PassphraseStrength.tooShort);
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

  group("Declining must land somewhere, not loop", () {
    // Reported from the device. With Phone Lock alone, cancelling the phone's
    // unlock prompt should leave the user on "Karde is Locked", with Unlock
    // Karde and Exit app. It did not: dismissing the prompt resumes the
    // activity, and resuming raised the prompt straight back, so the lock screen
    // never got a chance to be seen.
    //
    // With Both it looked correct, but only by accident — the Karde PIN screen
    // is a Flutter route that holds the flow open until the user closes it, so
    // no resume ever arrived to restart anything.

    test("a declined unlock is not retried automatically", () {
      final source = File("lib/features/home/presentation/main_scaffold.dart")
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith("//"))
          .join("\n")
          .replaceAll(RegExp(r"\s+"), " ");

      expect(
        source.contains(
          "if (!_isAppAuthenticated && !_isAuthenticating && (!_authDeclined || _noScreenLock) && mounted)",
        ),
        isTrue,
        reason: "Coming back to the foreground must not re-raise the unlock "
            "prompt after the user has just declined it — the resume that "
            "arrives is usually Karde's own prompt closing. A missing screen "
            "lock is the exception, and re-checked every time: the user has "
            "most likely just come back from setting one.",
      );
    });

    test("Karde's own prompts are declared as system UI", () {
      // Unguarded, the activity going inactive behind a prompt Karde raised
      // itself is indistinguishable from the user walking away, so a slow
      // authentication arms the auto-lock timer behind the very prompt being
      // answered. The vault's prompts were guarded; these two were missed.
      final source = File("lib/core/security/authentication_service.dart")
          .readAsStringSync();

      expect(
        "SystemInteractionGuard.run".allMatches(source).length,
        2,
        reason: "Both the sensitive-action prompt and the app-startup prompt "
            "must suppress the auto-lock timer while they are on screen.",
      );
    });
  });

  group("Cancel must mean cancel", () {
    // Reported from the device: turning the Karde PIN off asks whether to keep
    // or delete it, and pressing Cancel switched the PIN off anyway. A dialog
    // whose Cancel button performs the action it asked about is worse than no
    // dialog, because it teaches the user that reading them is pointless.
    test("dismissing the keep-or-delete question changes nothing", () {
      final source = File("lib/features/settings/presentation/settings_screen.dart")
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith("//"))
          .join("\n")
          .replaceAll(RegExp(r"\s+"), " ");

      expect(
        source.contains("if (!await _offerToForgetPin()) return;"),
        isTrue,
        reason: "The answer has to be able to stop the switch being flipped, "
            "which means it cannot be a Future<void> that runs and is ignored.",
      );
      expect(
        source.contains("if (choice == KardeConfirmChoice.cancelled) return false;"),
        isTrue,
        reason: "Cancelled is its own answer, distinct from both Keep and "
            "Delete: it means the user changed their mind about the switch.",
      );
    });
  });

  group("The lock switches must mean what they say", () {
    // Reported from the device: App PIN lock switched off, app restarted, still
    // asked for the Karde PIN. The switch was never consulted when opening the
    // app — that path asked for the PIN whenever a PIN existed — so the one
    // thing its label promises was the one thing it did not do.
    String codeOf(String path) => File(path)
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith("//"))
        .join("\n");

    test("opening the app consults the App PIN lock switch", () {
      final source = codeOf("lib/core/security/authentication_service.dart");
      final startup = source.substring(source.indexOf("authenticateAppStartup"));

      expect(
        startup.contains("requirePinLock"),
        isTrue,
        reason: "Opening the app must honour the switch labelled "
            "\"Require a PIN to open Karde\".",
      );
    });

    test("a PIN screen is never raised for a PIN that does not exist", () {
      // The third and last place still relying on this state being unreachable
      // rather than on a guard. The verification screen finds no stored hash,
      // offers to CREATE a PIN, and counts that creation as authentication.
      final source = codeOf("lib/core/security/authentication_service.dart");

      expect(
        source.contains("if (requirePinLock && hasKardePin)"),
        isTrue,
        reason: "The sensitive-action gate must check that a PIN exists before "
            "asking for one.",
      );
    });

    test("a vault the phone cannot protect is not gated, it is explained", () {
      // Asking for a Karde PIN with no screen lock takes a correct answer and
      // opens a vault where nothing can be read and nothing can be saved.
      final source =
          codeOf("lib/features/home/presentation/main_scaffold.dart");

      expect(
        source.contains("canUseVault"),
        isTrue,
        reason: "Opening the app must check the phone can protect the vault "
            "before asking the user for anything.",
      );
      expect(
        source.contains("openSecuritySettings"),
        isTrue,
        reason: "Telling someone their phone needs a screen lock without "
            "offering to take them there leaves them to go hunting.",
      );
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

  group("Vault health must measure what protects the vault", () {
    // Reported from the device: a phone with a PIN set and no fingerprint
    // enrolled was shown "Security Warning — no biometrics enrolled". Nothing
    // was at risk. The vault key is created with setUserAuthenticationRequired,
    // which accepts a strong biometric OR the phone's PIN, pattern or password,
    // so a PIN-only phone protects the vault completely. As the user put it,
    // not every device has a face or fingerprint sensor.
    //
    // Frightening someone about a choice that costs them nothing teaches them to
    // ignore the banner, which is the one thing a security banner cannot afford.
    // Comments are stripped before matching. The file explains at length what it
    // used to do wrongly and why, and a rule that reads prose would fail on its
    // own explanation — which is how this test failed the first time it ran.
    String codeOf(String path) => File(path)
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith("//"))
        .join("\n");

    test("health is not judged on enrolled biometrics", () {
      final source = codeOf("lib/core/security/device_security_service.dart");

      for (final biometricOnlyCheck in [
        "getAvailableBiometrics",
        "canCheckBiometrics",
      ]) {
        expect(
          source.contains(biometricOnlyCheck),
          isFalse,
          reason: "$biometricOnlyCheck reports whether a finger or face is "
              "enrolled, which says nothing about whether the vault is "
              "protected. A PIN protects it just as well.",
        );
      }

      expect(
        source.contains("canUseVault"),
        isTrue,
        reason: "Health must ask the same question the vault itself depends "
            "on: can the key exist and be used on this phone.",
      );
    });

    test("there is no middle state to be vague with", () {
      // Two honest answers: the phone can protect the vault, or it has no secure
      // lock screen at all — in which case nothing can be saved and anything
      // already saved is already gone. A third, softer state existed only to
      // carry the biometric complaint.
      final source = codeOf("lib/core/security/device_security_service.dart");

      expect(source.contains("warning"), isFalse);
      expect(source.contains("excellent"), isTrue);
      expect(source.contains("atRisk"), isTrue);
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
        source.contains("loc.lockChoiceChangeableLater"),
        isTrue,
        reason: "Nothing later in the Phone Lock flow revisits this decision, "
            "so the screen has to say the choice is not final. It says it once, "
            "about all three options — an earlier version said it under Phone "
            "Lock alone, which implied the other two were harder to undo.",
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

  group("Two screens must not answer to the same knock", () {
    // Android returns every picker's result to one method, tagged with the
    // request code that started it, and MainActivity offers each result to its
    // handlers in turn until one claims it. Two handlers sharing a code means
    // the first one wins and the second never hears its own answer.
    //
    // That happened: the backup folder picker was given 0xBA03, which the
    // gallery picker already used, and the folder is offered the result first —
    // so choosing a photo from the gallery was silently swallowed. Nothing
    // crashed and nothing was logged; the picture simply never arrived.
    test("every startActivityForResult code is unique", () {
      final codes = <String, String>{};
      for (final file in Directory("android/app/src/main/kotlin/com/karde/app")
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith(".kt"))) {
        for (final match in RegExp(r"val (REQUEST_\w+) = (0x[0-9A-Fa-f]+)")
            .allMatches(file.readAsStringSync())) {
          final name = match.group(1)!;
          final code = match.group(2)!.toUpperCase();
          expect(
            codes.containsKey(code),
            isFalse,
            reason: "$name shares $code with ${codes[code]}. Whichever handler "
                "MainActivity asks first will swallow the other's result.",
          );
          codes[code] = name;
        }
      }
      expect(codes, isNotEmpty, reason: "the regex should find request codes");
    });
  });

  group("Where the backup is offered", () {
    // The backup is the only thing that survives losing the phone or turning off
    // its screen lock. A screen lock or a PIN can be changed whenever the user
    // likes; a backup arranged after the phone is gone protects nothing.
    //
    // So it is the last step of onboarding, and every route out of onboarding
    // goes through the same handoff. Three routes reach the end — Phone Lock at
    // the lock screen, Karde PIN and Both after recovery — and each used to
    // enter the app on its own, which is exactly how one of three gets missed.
    test("every path out of onboarding goes through finishOnboarding", () {
      const endings = [
        "lib/features/onboarding/presentation/lock_setup_screen.dart",
        "lib/features/onboarding/presentation/recovery_setup_screen.dart",
        "lib/features/onboarding/presentation/security_questions_setup_screen.dart",
      ];

      // Comments are stripped: recovery_setup_screen explains at length why it
      // does *not* enter MainScaffold when reached from Settings, and a rule
      // that read prose would fail on that explanation.
      for (final path in endings) {
        final source = File(path)
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith("//"))
            .join("\n");
        expect(
          source.contains("finishOnboarding("),
          isTrue,
          reason: "$path ends onboarding, so it must hand off through the one "
              "place that arranges the backup first.",
        );
        expect(
          source.contains("MainScaffold"),
          isFalse,
          reason: "$path must not enter the app directly, which would skip "
              "backup setup entirely.",
        );
      }
    });

    test("onboarding does not ask for a backup", () {
      // It did, briefly. Asking someone who has not yet seen a single screen to
      // invent a passphrase, write it down and choose a folder — for a copy of a
      // vault that is still empty — is where people put the phone down. The
      // offer belongs where there is something to lose.
      final source =
          File("lib/features/onboarding/presentation/onboarding_finish.dart")
              .readAsLinesSync()
              .where((line) => !line.trimLeft().startsWith("//"))
              .join("\n");

      expect(source.contains("BackupSetupScreen"), isFalse);
    });

    test("but the home screen offers one, through the bell", () {
      // The warnings that used to stack up above the cards are collected behind
      // one bell now, so the offer lives on the notifications screen rather than
      // on the page. What must stay true is that it is one tap from the home
      // screen — the container has changed from a bottom sheet to a screen, and
      // may change again; the reachability is the rule.
      final dashboard =
          File("lib/features/home/presentation/dashboard_screen.dart")
              .readAsStringSync();
      final notifications =
          File("lib/features/home/presentation/notifications_screen.dart")
              .readAsStringSync();

      expect(dashboard.contains("NotificationsScreen.open"), isTrue,
          reason: "the bell has to open the notifications screen");
      expect(notifications.contains("BackupSetupScreen"), isTrue,
          reason: "and that screen has to offer setting a backup up");
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
    // The handoff now lives in one place. It used to be repeated at the end of
    // every path, which is how a step added to the end of onboarding gets added
    // twice and forgotten once.
    const onboardingFiles = [
      "lib/features/onboarding/presentation/onboarding_finish.dart",
      "lib/features/onboarding/presentation/pin_setup_screen.dart",
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

  group("What the app says must help the user decide, not explain the app", () {
    // The rule, in the user's words: "user doesn't need to know the maths, how
    // Karde works... The only thing we need to tell user is if he doesn't know
    // what the label means or what it does. Not the engineering."
    //
    // Karde had accumulated a lot of the other kind — "encrypted with
    // AES-256-GCM", "a key held in your phone's secure hardware", "your answers
    // are scrambled before they are saved". All true, none of it anything a
    // person can act on, and all of it crowding out the sentences that matter.
    //
    // Two strings are deliberately exempt. The About dialog is the one place
    // where describing the app is the whole point, and the offline badge is a
    // two-word reassurance rather than an explanation.
    // The privacy policy is exempt for the same reason About is: describing how
    // the app protects things is the entire purpose of that document, and it is
    // where the user said this material belongs.
    const exempt = {"aboutDialogBody", "offlineBadge"};
    bool isPolicy(String key) => key.startsWith("privacy");

    // Words that only make sense to somebody who has read the source.
    final jargon = RegExp(
      r"AES-256|AES\b|secure hardware|security chip|vault key|encryption key|"
      r"scrambled|hashed|ciphertext|key derivation|payload|Keystore",
      caseSensitive: false,
    );

    test("no user-facing string explains the mechanism", () {
      final arb = jsonDecode(
        File("lib/l10n/app_en.arb").readAsStringSync(),
      ) as Map<String, dynamic>;

      final offenders = <String>[];
      arb.forEach((key, value) {
        if (key.startsWith("@") || value is! String) return;
        if (exempt.contains(key) || isPolicy(key)) return;
        if (jargon.hasMatch(value)) offenders.add('$key: "$value"');
      });

      expect(offenders, isEmpty,
          reason: "these tell the user how Karde works rather than what to do:"
              "\n${offenders.join('\n')}");
    });

    test("nothing threatens a permanent lockout", () {
      // The Karde PIN used to lock the app for good after five wrong tries, and
      // the only way past it was erasing the vault. It is gone — wrong PINs now
      // cost a wait that grows — and no wording should survive that promised
      // otherwise.
      final arb = File("lib/l10n/app_en.arb").readAsStringSync();

      expect(arb.contains("maxAttemptsReached"), isFalse,
          reason: "the permanent lockout is gone; its message should be too");

      final screen =
          File("lib/core/security/pin_verification_screen.dart").readAsStringSync();
      expect(screen.contains("setIsPermanentlyLocked"), isFalse,
          reason: "nothing may set a permanent lock any more");
    });
  });

  group("Karde asks for nothing it does not use", () {
    test("the manifest declares no microphone or media-store access", () {
      // The camera plugin brings RECORD_AUDIO and READ_EXTERNAL_STORAGE with it
      // through the manifest merge. Karde records no audio — the controller is
      // built with enableAudio false — and reads no media store, because photos
      // arrive from the system picker as content URIs. Left alone, a vault app
      // would have been declaring microphone access on its Play listing.
      //
      // Caught on the device with `adb shell dumpsys package com.karde.app`
      // after the camera went in, which is the only place a merged manifest is
      // visible.
      final manifest =
          File("android/app/src/main/AndroidManifest.xml").readAsStringSync();

      for (final permission in [
        "android.permission.RECORD_AUDIO",
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.INTERNET",
      ]) {
        final line = RegExp(
          'uses-permission android:name="$permission"[^/]*/>',
        ).firstMatch(manifest);

        expect(line, isNotNull,
            reason: "$permission must be listed so it can be removed; a plugin "
                "that adds it back would otherwise merge in unnoticed");
        expect(line!.group(0), contains('tools:node="remove"'),
            reason: "$permission must be stripped from the merged manifest");
      }
    });
  });

  group("Karde's camera", () {
    // The guide is described in fractions of two different edges, so the two
    // numbers are not interchangeable and the arithmetic is easy to get backwards
    // — which is exactly what happened: the rectangle on the phone was nearly the
    // full height of the screen and nothing like the shape of a card.
    double shapeOnScreen(double previewAspect) {
      final guide = GuidedCameraScreen.guideFor(previewAspect);
      // The preview box is `1 / previewAspect` wide for every 1 tall, so the
      // guide's real width in pixels is scaled by that and its height is not.
      return (guide.width / previewAspect) / guide.height;
    }

    test("the guide is card-shaped on screen, whatever the preview's shape", () {
      for (final previewAspect in [4 / 3, 16 / 9, 3 / 2, 1.0]) {
        expect(
          shapeOnScreen(previewAspect),
          closeTo(GuidedCameraScreen.cardAspectRatio, 0.02),
          reason: "a $previewAspect preview must still frame a card shape",
        );
      }
    });

    test("and is nowhere near the full height of the screen", () {
      // The reported symptom. Multiplying by the preview aspect where the
      // formula divides asked for 0.96 of the height on a 16:9 preview and got
      // the clamp.
      expect(GuidedCameraScreen.guideFor(16 / 9).height, lessThan(0.5));
      expect(GuidedCameraScreen.guideFor(4 / 3).height, lessThan(0.5));
    });

    test("the guide stays centred", () {
      for (final previewAspect in [4 / 3, 16 / 9]) {
        final guide = GuidedCameraScreen.guideFor(previewAspect);
        expect(guide.left + guide.width / 2, closeTo(0.5, 0.001));
        expect(guide.top + guide.height / 2, closeTo(0.5, 0.001));
      }
    });

    test("the crop is never taken against the preview", () {
      // The reason this screen now asks the user to place the rectangle. On the
      // S23 Ultra the preview and the still are both 1280x720, but the sensor
      // fetch window is 4000x3000 and the multi-lens pipeline gives the still a
      // wider field of view — so a rectangle drawn on the preview named a
      // different part of the photograph, and nothing reachable from Dart can
      // measure the difference. The crop is now placed on the photo itself.
      final dart = File("lib/core/security/vault_image_service.dart")
          .readAsStringSync();
      final screen = File("lib/core/widgets/guided_camera_screen.dart")
          .readAsStringSync();
      final kotlin =
          File("android/app/src/main/kotlin/com/karde/app/ImageCapture.kt")
              .readAsStringSync();

      // The live preview still measures its aiming guide against the preview's
      // own shape, which is right — it is drawn on the preview. What must never
      // happen again is that number reaching the crop.
      for (final source in [dart, kotlin]) {
        expect(source.contains("previewAspect"), isFalse,
            reason: "the preview cannot describe a region of the still");
      }
      expect(screen.contains("previewAspect: "), isFalse,
          reason: "it must not be handed to cropCapture");

      expect(screen.contains("prepareCapture"), isTrue,
          reason: "the whole photo has to be shown before anything is cut");
      expect(screen.contains("left: _crop.left"), isTrue,
          reason: "the crop must come from the rectangle the user placed");
    });

    test("a rejected capture is deleted, not left in the cache", () {
      // It is a full-resolution photograph of somebody's passport.
      final screen = File("lib/core/widgets/guided_camera_screen.dart")
          .readAsStringSync();
      expect(screen.contains("discardCapture"), isTrue);
    });

    test("the crop rectangle cannot be turned inside out or lost", () {
      const crop = Rect.fromLTWH(0.2, 0.2, 0.5, 0.5);

      // Dragged far past the opposite edge, a corner stops at the minimum size
      // rather than crossing over and inverting the rectangle.
      final squashed = CropCorner.bottomRight.resize(crop, const Offset(-9, -9), 0.12);
      expect(squashed.width, closeTo(0.12, 0.001));
      expect(squashed.height, closeTo(0.12, 0.001));
      expect(squashed.left, crop.left, reason: "the held corner stays put");

      // And it can never be dragged outside the photograph.
      final shoved = CropCorner.topLeft.resize(crop, const Offset(-9, -9), 0.12);
      expect(shoved.left, 0.0);
      expect(shoved.top, 0.0);
    });

    test("a bounds-only decode never null-checks through ?.use", () {
      // This bug has now shipped twice in the same file. In inJustDecodeBounds
      // mode BitmapFactory.decodeStream returns null by contract, so
      //
      //   openInputStream(uri)?.use { decodeStream(it, null, bounds) } ?: throw
      //
      // reads as "throw if the photo could not be opened" and does not mean it:
      // the elvis sees the decode result, not the stream, and fires every single
      // time. The first time it made every photo fail; the second time it made
      // every shutter press say "That photo could not be taken."
      //
      // The stream must be held in its own variable and null-checked there.
      final source =
          File("android/app/src/main/kotlin/com/karde/app/ImageCapture.kt")
              .readAsLinesSync()
              .where((line) => !line.trimLeft().startsWith("//"))
              .where((line) => !line.trimLeft().startsWith("*"))
              .join("\n");

      final dangerous = RegExp(
        r'\?\.use\s*\{[^}]*decodeStream\([^)]*bounds\s*\)',
        dotAll: true,
      );

      expect(
        dangerous.hasMatch(source),
        isFalse,
        reason: "a bounds-only decode inside ?.use makes the ?: test the decode "
            "result instead of the stream, and it throws on every image",
      );
    });
  });

  group("form messages name what was typed", () {
    test("the cardholder name rejects digits and symbols separately", () {
      // "Letters and symbols are not allowed" was shown for both, in a field
      // where letters are the only thing that can go.
      final source = File("lib/features/cards/presentation/add_card_screen.dart")
          .readAsStringSync();

      expect(
        source.contains(r"RegExp(r'[0-9]'))) return loc.numbersNotAllowed"),
        isTrue,
        reason: "typing a digit must say numbers are not allowed",
      );
      expect(
        source.contains("return loc.symbolsNotAllowed"),
        isTrue,
        reason: "typing a symbol must say symbols are not allowed",
      );
      expect(
        source.contains("lettersAndSymbolsNotAllowed"),
        isFalse,
        reason: "the combined message told the user letters were the problem",
      );
    });

    test("no name-field message tells the user letters are not allowed", () {
      for (final locale in ["en", "fr", "ar"]) {
        final arb = jsonDecode(File("lib/l10n/app_$locale.arb").readAsStringSync())
            as Map<String, dynamic>;

        expect(arb.containsKey("numbersNotAllowed"), isTrue,
            reason: "$locale is missing the digits message");
        expect(arb.containsKey("symbolsNotAllowed"), isTrue,
            reason: "$locale is missing the symbols message");
        expect(arb.containsKey("lettersAndSymbolsNotAllowed"), isFalse,
            reason: "$locale still carries the message that named letters");
      }

      final en = jsonDecode(File("lib/l10n/app_en.arb").readAsStringSync())
          as Map<String, dynamic>;
      expect(en["numbersNotAllowed"].toString().toLowerCase(),
          isNot(contains("letter")));
      expect(en["symbolsNotAllowed"].toString().toLowerCase(),
          isNot(contains("letter")));
    });
  });

  group("The two Add buttons on the home screen", () {
    // They sit side by side, so they are read as a pair. "Add a card" used a
    // bare plus while "Add an ID" used an ID badge — one naming the action and
    // the other naming the thing, which is why the pair looked unfinished. The
    // word "Add" is already in both labels, so both icons name the thing.
    String homeScreen() => File(
          "lib/features/home/presentation/dashboard_screen.dart",
        ).readAsLinesSync().where((l) => !l.trimLeft().startsWith("//")).join("\n");

    test("neither icon names the action", () {
      expect(
        RegExp(r"Icon\(Icons\.add[,)]").hasMatch(homeScreen()),
        isFalse,
        reason: "a plus says nothing the label has not already said",
      );
    });

    test("both name the thing, and match each other in weight", () {
      expect(homeScreen(), contains("Icon(Icons.credit_card,"),
          reason: "Add a card must show a card");
      expect(homeScreen(), contains("Icon(Icons.badge,"),
          reason: "Add an ID must show an ID");

      // The pair is the point. One solid beside one hollow reads as one button
      // mattering more than the other, which is the trap the Vault list avoids
      // only because its two icons never appear next to each other.
      expect(
        homeScreen().contains("Icon(Icons.credit_card_outlined,") ||
            homeScreen().contains("Icon(Icons.badge_outlined,"),
        isFalse,
        reason: "the two buttons must not mix an outlined icon with a solid one",
      );
    });

    test("the card icon is the one the rest of the app already uses", () {
      // Not a new word invented for the home screen. credit_card is Karde's
      // card icon in the Vault list, its search results and its bottom bar.
      final vault = File("lib/features/cards/presentation/vault_screen.dart")
          .readAsStringSync();
      expect(vault, contains("Icons.credit_card"));
    });
  });

  group("Anything that raises a system window must suspend auto-lock", () {
    // Found three times on the phone in one session: granting the camera
    // permission, granting notifications, and picking the backup folder each
    // dropped the user on the PIN screen, once with a half-filled card behind
    // it. Android's own dialogs take the foreground, and the auto-lock timer
    // cannot tell that apart from the user walking away — so every call that
    // deliberately raises one has to say so.
    const raisers = {
      "lib/core/platform/backup_folder_service.dart": "the folder picker",
      "lib/core/platform/file_transfer_service.dart": "the file picker",
      "lib/core/notifications/expiry_notifications.dart":
          "the notification permission dialog",
      "lib/core/widgets/guided_camera_screen.dart":
          "the camera permission dialog",
      "lib/core/security/authentication_service.dart": "the biometric prompt",
    };

    for (final entry in raisers.entries) {
      test("${entry.value} suspends it", () {
        final source = File(entry.key).readAsStringSync();
        expect(
          source.contains("SystemInteractionGuard.run"),
          isTrue,
          reason: "${entry.key} raises a system window on purpose, so it must "
              "run inside the guard or the vault locks behind it",
        );
      });
    }
  });

  group("The backup alarm must not outlive the problem", () {
    test("a successful catch-up clears the failing flag", () {
      // Found on the phone. A write failed during backup setup (the vault locked
      // behind the folder picker), which raised "Your backup is not being
      // saved". "Copy them now" then wrote everything successfully — but the
      // flag is otherwise only cleared by an ordinary save, so the bell went on
      // saying new changes were not being copied while Settings said automatic
      // backup was on and named the folder. An app contradicting itself about
      // the one thing this alarm exists to be trusted on.
      final source = File("lib/features/backup/presentation/backup_screen.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .join("\n");

      expect(
        source.contains("autoBackupFailingProvider.notifier).state = false"),
        isTrue,
        reason: "copying the missing items through proves the folder is "
            "writable, so the alarm has to come down with it",
      );
    });
  });

  group("Setting a backup up must refresh what the bell knows", () {
    // Found on the phone. Turning automatic backup off and straight back on
    // left a vault of two items with an empty backup file — seeding costs one
    // authentication per item, so it is offered rather than done — and the bell
    // said nothing at all, because the missing count was still the cached zero
    // from before. Its owner puts the phone down believing they are covered,
    // which is the exact failure this feature exists to prevent.
    test("finishing setup invalidates every provider the bell reads", () {
      final source =
          File("lib/features/backup/presentation/backup_setup_screen.dart")
              .readAsLinesSync()
              .where((l) => !l.trimLeft().startsWith("//"))
              .join("\n");

      for (final provider in [
        "autoBackupConfiguredProvider",
        "autoBackupSetupProvider",
        "autoBackupMissingCountProvider",
      ]) {
        expect(
          source.contains("ref.invalidate($provider)"),
          isTrue,
          reason: "$provider is stale the moment a backup is configured, and "
              "the bell reads it before the app is ever restarted",
        );
      }
    });

    test("turning it off invalidates the same count", () {
      final source =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsStringSync();
      expect(
        source.contains("ref.invalidate(autoBackupMissingCountProvider)"),
        isTrue,
      );
    });
  });

  group("A reminder due later today is still due", () {
    // Found on the phone. The schedule is rebuilt every time Karde opens, and
    // the test for "is this reminder still in the future" compared the *day* at
    // midnight while the reminder itself goes out at nine in the morning. So
    // opening the app at any point on the notice day before nine cancelled that
    // morning's reminder and did not put it back. Nine o'clock came and went in
    // silence, which is the one thing this feature exists to prevent.
    test("nine in the morning is still ahead of eight in the morning", () {
      final day = DateTime(2026, 10, 1);
      final send = ExpiryNotifications.sendTimeOf(day);

      expect(send.hour, 9, reason: "reminders go out at nine");
      expect(send.isAfter(DateTime(2026, 10, 1, 8, 59)), isTrue,
          reason: "this is the case that was being dropped");
      expect(send.isAfter(DateTime(2026, 10, 1, 0, 0)), isTrue);
      expect(send.isAfter(DateTime(2026, 10, 1, 9, 1)), isFalse,
          reason: "once it has gone out it is genuinely past");
      expect(send.isAfter(DateTime(2026, 9, 30, 23, 59)), isTrue);
    });

    test("the guard compares the send time, not the bare day", () {
      final source = File("lib/core/notifications/expiry_notifications.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .join("\n");

      expect(source.contains("_sendTimeOf(day).isAfter(now)"), isTrue);
      expect(source.contains("_sendTimeOf(gone).isAfter(now)"), isTrue);
      expect(
        RegExp(r"if \((notice|gone)\.isAfter\(now\)\)").hasMatch(source),
        isFalse,
        reason: "comparing the bare day treats the whole notice day as past",
      );
    });
  });

  group("Reminders need receivers the plugin no longer declares", () {
    // The bug Section J was written to catch, and it caught it. From version 16
    // the notifications plugin stopped declaring its receivers and ships only
    // VIBRATE and POST_NOTIFICATIONS, so nothing merged them in and nothing
    // warned they were missing. Every reminder was scheduled, accepted and
    // thrown away: the alarm was visible in `dumpsys alarm`, it disappeared at
    // nine o'clock on the right day, and Android delivered it to a component
    // that did not exist in the package. Reminders had never once worked.
    final manifest =
        File("android/app/src/main/AndroidManifest.xml").readAsStringSync();

    test("the scheduled-notification receiver is declared", () {
      expect(
        manifest.contains(
          "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver",
        ),
        isTrue,
        reason: "without it a reminder fires into nothing",
      );
    });

    test("and the one that survives a reboot", () {
      expect(
        manifest.contains(
          "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver",
        ),
        isTrue,
        reason: "RECEIVE_BOOT_COMPLETED is declared for this receiver; without "
            "it every reminder dies at the next restart",
      );
      expect(manifest.contains("android.intent.action.BOOT_COMPLETED"), isTrue);
      expect(
        manifest.contains("android.intent.action.MY_PACKAGE_REPLACED"),
        isTrue,
        reason: "an app update must not silently drop the schedule either",
      );
    });

    test("neither receiver is exported", () {
      // Anything on the phone could otherwise ask Karde to post a notification.
      for (final match in RegExp(
        r'<receiver[^>]*flutterlocalnotifications[^>]*',
        dotAll: true,
      ).allMatches(manifest)) {
        expect(match.group(0), contains('android:exported="false"'));
      }
    });

    test("the permission that makes the boot receiver work is declared", () {
      expect(
        manifest.contains("android.permission.RECEIVE_BOOT_COMPLETED"),
        isTrue,
      );
    });
  });

  group("A month's warning is a ladder, not one notification", () {
    // The user's own words: one reminder in a whole month "is unreal". A single
    // warning thirty days out arrives when there is nothing to do about it, and
    // by the time there is, it has long been swiped away.
    test("the reminders get closer together as the date approaches", () {
      final ladder = Expiry.reminderDaysBefore;

      expect(ladder, isNotEmpty);
      expect(ladder.first, greaterThan(ladder.last),
          reason: "counted in days before the end, so it must descend");
      expect(ladder.last, 0, reason: "the day itself must be one of them");

      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], lessThan(ladder[i - 1]),
            reason: "every step must be nearer the date than the last");
      }

      // Descending gaps are what "tightening" means.
      final gaps = [
        for (var i = 1; i < ladder.length; i++) ladder[i - 1] - ladder[i],
      ];
      for (var i = 1; i < gaps.length; i++) {
        expect(gaps[i], lessThanOrEqualTo(gaps[i - 1]),
            reason: "the gaps must never widen as the date gets closer");
      }
    });

    test("a card gets several reminders inside its month", () {
      final forCard = Expiry.reminderOffsetsFor(Expiry.cardNoticeDays);

      expect(forCard.length, greaterThan(3),
          reason: "one reminder a month out is what the user rejected");
      expect(forCard, everyElement(lessThanOrEqualTo(Expiry.cardNoticeDays)),
          reason: "nothing may fire before Karde is meant to speak up");
      expect(forCard, contains(30), reason: "still says it a month out");
      expect(forCard, contains(1), reason: "and the day before");
      expect(forCard, contains(0), reason: "and on the day itself");
      expect(forCard, isNot(contains(90)),
          reason: "a card's window is thirty days, not ninety");
    });

    test("a document uses the whole ladder, because its window is longer", () {
      final forDoc = Expiry.reminderOffsetsFor(Expiry.documentNoticeDays);

      expect(forDoc, contains(90), reason: "three months out for a passport");
      expect(forDoc.length, greaterThan(
        Expiry.reminderOffsetsFor(Expiry.cardNoticeDays).length,
      ));
    });

    test("the schedule is built from the ladder, not a single notice day", () {
      final source = File("lib/core/notifications/expiry_notifications.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .join("\n");

      expect(source.contains("Expiry.reminderOffsetsFor(thing.noticeDays)"),
          isTrue);
    });
  });

  group("A reminder that might not arrive is not a reminder", () {
    // Reminders were inexact so Karde would not need a permission Google
    // reviews. The reasoning was that ten past nine is as good as nine. On the
    // S23 an inexact reminder sat undelivered for its entire one-hour window —
    // awake, charging, not dozing, app in the active standby bucket — and then
    // expired having never been shown.
    final manifest =
        File("android/app/src/main/AndroidManifest.xml").readAsStringSync();
    final source = File("lib/core/notifications/expiry_notifications.dart")
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith("//"))
        .where((l) => !l.trimLeft().startsWith("///"))
        .join("\n");

    test("Karde asks for exact alarms", () {
      expect(
        manifest.contains("android.permission.SCHEDULE_EXACT_ALARM"),
        isTrue,
      );
    });

    test("but never claims to be an alarm clock", () {
      // USE_EXACT_ALARM needs no dialog, and Google reserves it for apps whose
      // primary purpose is alarms, calendars or clocks. Karde is a vault that
      // happens to remind you.
      expect(
        manifest.contains("android.permission.USE_EXACT_ALARM"),
        isFalse,
        reason: "claiming it would be a Play policy risk",
      );
    });

    test("and falls back rather than failing when it is refused", () {
      expect(source.contains("AndroidScheduleMode.exactAllowWhileIdle"), isTrue);
      expect(
        source.contains("AndroidScheduleMode.inexactAllowWhileIdle"),
        isTrue,
        reason: "a refusal must cost punctuality, not the reminders themselves",
      );
      expect(source.contains("canScheduleExactNotifications"), isTrue,
          reason: "the mode has to follow what the phone actually permits");
    });

    test("the permission is asked where it explains itself", () {
      // Never at launch. Straight after the user turns expiry reminders on.
      final settings =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsStringSync();
      expect(settings.contains("requestExactAlarms()"), isTrue);
    });
  });

  group("A reminder is one line, not three", () {
    // There used to be a title above the sentence — "Something in Karde is
    // running out". The user cut it: the notification header already reads
    // "Karde", so a glance at the lock screen cost three lines to learn one
    // thing the sentence said on its own.
    test("reminders are scheduled without a title", () {
      final source = File("lib/core/notifications/expiry_notifications.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .where((l) => !l.trimLeft().startsWith("///"))
          .join("\n");

      expect(
        RegExp(r"zonedSchedule\(\s*id,\s*null,").hasMatch(source),
        isTrue,
        reason: "the title slot must stay empty",
      );
      expect(source.contains("expiringTitle"), isFalse);
      expect(source.contains("expiredTitle"), isFalse);
    });

    test("and the strings behind it are gone from every language", () {
      for (final locale in ["en", "fr", "ar"]) {
        final arb = jsonDecode(File("lib/l10n/app_$locale.arb").readAsStringSync())
            as Map<String, dynamic>;
        expect(arb.containsKey("notifyExpiringTitle"), isFalse,
            reason: "$locale still carries the removed title");
        expect(arb.containsKey("notifyExpiredTitle"), isFalse,
            reason: "$locale still carries the removed title");

        // The sentence itself is the whole notification, so it has to survive.
        expect(arb.containsKey("notifyExpiringBody"), isTrue);
        expect(arb.containsKey("notifyExpiredBody"), isTrue);
      }
    });

    test("the sentence still names nothing", () {
      // The reason the count exists at all: this lands on a lock screen.
      final en = jsonDecode(File("lib/l10n/app_en.arb").readAsStringSync())
          as Map<String, dynamic>;
      for (final key in ["notifyExpiringBody", "notifyExpiredBody"]) {
        final text = en[key].toString();
        expect(text, contains("{count}"));
        expect(text, contains("Open Karde to see which."));
      }
    });
  });

  group("The camera screen must not strobe", () {
    // Reported from the phone: refusing the camera permission left the "no
    // camera access" screen flashing "like an old bulb". A permanently refused
    // permission still flashes Android's dialog up and away, which is an
    // inactive/resumed pair; retrying on every resume started another attempt,
    // each failed, and the screen alternated between spinner and message several
    // times a second.
    final source = File("lib/core/widgets/guided_camera_screen.dart")
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith("//"))
        .where((l) => !l.trimLeft().startsWith("///"))
        .join("\n");

    test("a retry needs a real trip to the background, not any resume", () {
      expect(source.contains("_wasBackgrounded = true"), isTrue,
          reason: "only `paused` may arm a retry");
      expect(
        RegExp(r"resumed\s*&&\s*_controller == null\s*\)").hasMatch(source),
        isFalse,
        reason: "retrying on every resume is what made it strobe",
      );
    });

    test("only one start attempt runs at a time", () {
      expect(source.contains("if (_starting) return;"), isTrue);
    });

    test("the unavailable state is set once an attempt knows the answer", () {
      // Clearing it at the top of every attempt blinked the screen back to the
      // spinner before failing again — the other half of the strobing.
      expect(
        source.contains("if (_unavailable && mounted) setState"),
        isFalse,
        reason: "it must not be cleared before the attempt has run",
      );
      expect(source.contains("_unavailable = false;"), isTrue,
          reason: "but success must still clear it, or one failure latches");
    });
  });

  group("Reminders must never be quietly late", () {
    // A reminder set for nine o'clock arrived somewhere in the following hour —
    // or on the phone it was found on, not at all — and there was nothing
    // anywhere in the app to explain why. Someone relying on it is simply let
    // down. Karde now says so, and offers the way to fix it.
    test("Settings can tell whether the phone allows punctual reminders", () {
      final notifications =
          File("lib/core/notifications/expiry_notifications.dart")
              .readAsStringSync();
      expect(notifications.contains("remindersCanArriveProvider"), isTrue);
      expect(notifications.contains("Future<bool> canBeExact()"), isTrue);
      expect(notifications.contains("isBatteryUnrestricted()"), isTrue,
          reason: "a phone that will not wake the app is the other way a "
              "reminder silently fails, and the one that actually bit");
    });

    test("and says something when the answer is no", () {
      final settings =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsLinesSync()
              .where((l) => !l.trimLeft().startsWith("//"))
              .join("\n");

      expect(settings.contains("remindersCanArriveProvider"), isTrue);
      expect(settings.contains("settingsRemindersMayBeLate"), isTrue);
      expect(settings.contains("requestExactAlarms()"), isTrue,
          reason: "saying it is late is no use without a way to fix it");
    });

    test("the notice stays quiet when there is nothing to report", () {
      // Karde does not warn about reminders somebody has switched off.
      final settings =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsStringSync();
      expect(
        settings.contains("ref.watch(expiryRemindersProvider) &&"),
        isTrue,
        reason: "the warning is gated on reminders actually being on",
      );
    });

    test("the wording explains the consequence, not the mechanism", () {
      for (final locale in ["en", "fr", "ar"]) {
        final arb = jsonDecode(File("lib/l10n/app_$locale.arb").readAsStringSync())
            as Map<String, dynamic>;
        expect(arb.containsKey("settingsRemindersMayBeLate"), isTrue,
            reason: "$locale is missing the notice");
      }
      final en = jsonDecode(File("lib/l10n/app_en.arb").readAsStringSync())
          as Map<String, dynamic>;
      final text = en["settingsRemindersMayBeLate"].toString().toLowerCase();
      for (final jargon in ["alarm", "permission", "api", "schedule_exact"]) {
        expect(text, isNot(contains(jargon)),
            reason: "the user needs the consequence, not the mechanism");
      }
    });
  });

  group("A phone that will not wake Karde must be named", () {
    // The bug that cost this feature weeks. On a Galaxy S23 the alarm fired
    // exactly on time, the phone woke for it, and Samsung's power manager never
    // started the app to handle the broadcast. Nothing in Karde was wrong.
    // Nothing anywhere said so. The reminder appeared within seconds of the app
    // being exempted from battery optimisation.
    test("Karde can ask whether the phone will let it run in the background", () {
      final service = File("lib/core/security/window_security_service.dart")
          .readAsStringSync();
      expect(service.contains("isBatteryUnrestricted"), isTrue);
      expect(service.contains("openBatterySettings"), isTrue,
          reason: "naming the problem without a way to it is only half of it");
    });

    test("an unanswerable question never accuses the phone", () {
      // A device that does not understand the question must not be reported as
      // holding reminders back.
      final service = File("lib/core/security/window_security_service.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .where((l) => !l.trimLeft().startsWith("///"))
          .join("\n");
      expect(
        RegExp(r"invokeMethod<bool>\('batteryUnrestricted'\) \?\? true")
            .hasMatch(service),
        isTrue,
        reason: "the safe default is to assume nothing is wrong",
      );
    });

    test("Karde does not ask for the restricted battery permission", () {
      // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS opens a one-tap dialog, but Google
      // reserves it for a short list of app categories a vault is not on.
      // Sending the user to the system list needs no permission at all.
      final manifest =
          File("android/app/src/main/AndroidManifest.xml").readAsStringSync();
      expect(
        manifest.contains("REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"),
        isFalse,
        reason: "asking for it would put the Play listing at risk",
      );

      final activity =
          File("android/app/src/main/kotlin/com/karde/app/MainActivity.kt")
              .readAsStringSync();
      expect(
        activity.contains("ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS"),
        isTrue,
        reason: "the unrestricted list screen is the one that needs nothing",
      );
    });

    test("both causes are checked before Settings stays quiet", () {
      final notifications =
          File("lib/core/notifications/expiry_notifications.dart")
              .readAsLinesSync()
              .where((l) => !l.trimLeft().startsWith("///"))
              .join("\n");
      expect(notifications.contains("canBeExact()"), isTrue);
      expect(notifications.contains("isBatteryUnrestricted()"), isTrue);
    });
  });

  group("A blocked reminder is raised where people look", () {
    // The Settings notice was the right words in the wrong room. Settings is the
    // one place a user has no reason to visit — and the phones that cause this
    // are the ones that freeze apps people rarely open, which is exactly the
    // profile of somebody who set their cards up once and never came back. The
    // notice would have sat unread.
    test("the bell raises it, not only Settings", () {
      final alerts = File("lib/features/home/data/alerts_providers.dart")
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith("//"))
          .join("\n");

      expect(alerts.contains("remindersCanArriveProvider"), isTrue);
      expect(alerts.contains("'reminders-blocked'"), isTrue);
    });

    test("and it is gated on reminders actually being on", () {
      final alerts = File("lib/features/home/data/alerts_providers.dart")
          .readAsStringSync();
      expect(
        alerts.contains("ref.watch(expiryRemindersProvider) &&"),
        isTrue,
        reason: "Karde must not complain about reminders somebody turned off",
      );
    });

    test("the alert carries a way to fix it", () {
      final screen =
          File("lib/features/home/presentation/notifications_screen.dart")
              .readAsStringSync();
      expect(screen.contains("case 'reminders-blocked':"), isTrue);
      expect(screen.contains("openBatterySettings()"), isTrue);
      expect(screen.contains("requestExactAlarms()"), isTrue,
          reason: "either of the two can be the actual problem");
    });

    test("it is a notice, not an emergency", () {
      // Nothing is at risk. The date is still printed on the card; it is the
      // reminder about it that will not come.
      final alerts = File("lib/features/home/data/alerts_providers.dart")
          .readAsStringSync();
      final block = alerts.substring(alerts.indexOf("'reminders-blocked'"));
      expect(block.substring(0, 200), contains("KardeAlertSeverity.notice"));
    });

    test("turning reminders on also checks the phone will wake Karde", () {
      final settings =
          File("lib/features/settings/presentation/settings_screen.dart")
              .readAsLinesSync()
              .where((l) => !l.trimLeft().startsWith("//"))
              .join("\n");
      expect(settings.contains("isBatteryUnrestricted()"), isTrue,
          reason: "the toggle catches somebody deliberately turning them on; "
              "the bell catches the phone deciding months later");
    });
  });
}
