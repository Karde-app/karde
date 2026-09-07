import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/platform/backup_folder_service.dart';
import 'package:ibank/core/security/backup_identity_service.dart';
import 'package:ibank/core/security/bundle_crypto_service.dart';
import 'package:ibank/core/storage/settings_repository.dart';
import 'package:ibank/features/backup/data/auto_backup_file.dart';
import 'package:ibank/features/backup/data/auto_backup_service.dart';
import 'package:ibank/features/backup/data/pending_backup_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the user's chosen folder.
class FakeFolder extends Fake implements BackupFolderService {
  final Map<String, String> files = {};
  bool reachable = true;

  /// The folder accepts writes but will not enumerate itself. Some providers
  /// really do behave this way, and history must not be a condition of backup.
  bool failListing = false;

  /// Files whose names match this cannot be written. Used to prove setup stops
  /// rather than destroying a backup it could not first move to safety.
  RegExp? failWritesTo;
  int writes = 0;

  @override
  Future<bool> isUsable(String treeUri) async => reachable;

  @override
  Future<String?> read(String treeUri, String name) async {
    if (!reachable) throw const BackupFolderUnavailable('folder is gone');
    return files[name];
  }

  @override
  Future<void> write(String treeUri, String name, String content) async {
    if (!reachable) throw const BackupFolderUnavailable('folder is gone');
    if (failWritesTo?.hasMatch(name) ?? false) {
      throw const BackupFolderUnavailable('cannot write that file');
    }
    writes++;
    files[name] = content;
  }

  @override
  Future<List<String>> list(String treeUri) async {
    if (!reachable || failListing) {
      throw const BackupFolderUnavailable('folder is gone');
    }
    return files.keys.toList();
  }

  @override
  Future<bool> delete(String treeUri, String name) async {
    if (!reachable) throw const BackupFolderUnavailable('folder is gone');
    return files.remove(name) != null;
  }
}

/// Stands in for the platform's sealing, which cannot run in a unit test.
///
/// Deliberately reversible rubbish rather than real crypto: what is under test
/// here is which record ends up where, not the cipher.
class FakeIdentity extends Fake implements BackupIdentityService {
  int seals = 0;

  @override
  Future<BackupIdentity> create(String passphrase) async => const BackupIdentity(
        publicKey: 'PUB',
        sealedPrivateKey: 'SEALED-PRIVATE',
      );

  @override
  Future<String> seal({
    required String publicKey,
    required String plaintext,
  }) async {
    seals++;
    return jsonEncode({'k': publicKey, 'iv': 'IV', 'd': plaintext});
  }

  /// Opens what [seal] wrote. Reversible rubbish, deliberately: what is under
  /// test is which record comes back as what, not the cipher.
  @override
  Future<List<String>> openAll({
    required String sealedPrivateKey,
    required String passphrase,
    required List<String> records,
  }) async {
    if (sealedPrivateKey != 'SEALED-PRIVATE') {
      throw const BackupPassphraseIncorrect();
    }
    return records
        .map((r) => (jsonDecode(r) as Map<String, dynamic>)['d'] as String)
        .toList();
  }
}

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

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AutoBackupService service;
  late FakeFolder folder;
  late FakeIdentity identity;
  late SettingsRepository settings;

  /// The queue of changes waiting for the folder lives in a real file, so these
  /// tests give it a real directory rather than the phone's.
  late Directory queueDirectory;

  const chosenFolder = BackupFolderChoice(
    uri: 'content://tree/primary%3ADocuments',
    label: 'Documents',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    queueDirectory = await Directory.systemTemp.createTemp('karde_queue');
    folder = FakeFolder();
    identity = FakeIdentity();
    settings = SettingsRepository(
      await SharedPreferences.getInstance(),
      FakeSecureStorage(),
    );
    service = AutoBackupService(
      settings: settings,
      folder: folder,
      identity: identity,
      pending: PendingBackupStore(directory: queueDirectory),
    );
  });

  tearDown(() async {
    if (await queueDirectory.exists()) {
      await queueDirectory.delete(recursive: true);
    }
  });

  group('Before it is set up', () {
    test('saving an item does nothing and complains about nothing', () async {
      // Every save calls this. It has to be harmless before setup, or every
      // caller needs its own guard and one of them will forget.
      await service.recordSave(id: 'card:1', plaintext: '{"nickname":"Visa"}');

      expect(folder.writes, 0);
      expect(await service.isConfigured, isFalse);
    });

    test('a vault with no backup arranged is not a broken backup', () async {
      expect(await service.isHealthy(), isTrue);
    });
  });

  group('Setting it up', () {
    test('writes an empty backup straight away', () async {
      // While the user is standing here and can do something about it. The
      // alternative is finding out the folder is unwritable on their first saved
      // card — or never finding out.
      await service.configure(
        passphrase: 'correct horse battery staple',
        folderChoice: chosenFolder,
      );

      expect(folder.files, contains(AutoBackupService.currentFileName));
      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.count, 0);
      expect(file.sealedPrivateKey, 'SEALED-PRIVATE');
    });

    test('an unwritable folder fails setup rather than being remembered', () async {
      // Storing a broken arrangement would leave the user believing they are
      // covered by a backup that has never once been written.
      folder.reachable = false;

      expect(
        () => service.configure(passphrase: 'p', folderChoice: chosenFolder),
        throwsA(isA<BackupFolderUnavailable>()),
      );
      expect(await service.isConfigured, isFalse);
    });

    test('remembers where the backups go, in words the user chose', () async {
      final setup = await service.configure(
        passphrase: 'p',
        folderChoice: chosenFolder,
      );

      expect(setup.folderLabel, 'Documents');
      expect((await service.setup())!.folderLabel, 'Documents');
    });
  });

  group('Setting up over a folder that already holds a backup', () {
    // The single worst bug this feature had, found by the user re-onboarding
    // onto yesterday's folder and noticing the file had been modified.
    //
    // Setting up wrote an empty backup over karde-backup.json without looking.
    // So the exact sequence a person follows on a new phone — install Karde,
    // walk onboarding, point it at the folder holding their backup — destroyed
    // that backup before they ever reached the screen that would have restored
    // it. Nothing warned them, and nothing could be undone.

    /// A backup already sitting in the folder, holding one card.
    String existingBackup() {
      final file = AutoBackupFile.empty('SOMEONE-ELSES-KEY');
      file.put('card:1', jsonEncode({'k': 'K', 'iv': 'IV', 'd': 'precious'}));
      return file.encode();
    }

    test('the existing backup is kept, not overwritten', () async {
      folder.files[AutoBackupService.currentFileName] = existingBackup();

      await service.configure(passphrase: 'p', folderChoice: chosenFolder);

      final displaced = folder.files.entries.where(
        (e) => e.key.startsWith('karde-backup-replaced-'),
      );
      expect(displaced, hasLength(1),
          reason: 'the old backup must still exist somewhere');
      final kept = AutoBackupFile.decode(displaced.single.value);
      expect(kept.ids, ['card:1']);
      expect(kept.sealedPrivateKey, 'SOMEONE-ELSES-KEY',
          reason: 'it must still be openable with the passphrase it was made '
              'with, which is not the one just chosen');
    });

    test('and the new backup starts empty, under the usual name', () async {
      folder.files[AutoBackupService.currentFileName] = existingBackup();

      await service.configure(passphrase: 'p', folderChoice: chosenFolder);

      final current = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(current.count, 0);
      expect(current.sealedPrivateKey, 'SEALED-PRIVATE');
    });

    test('the displaced copy is never pruned as a daily snapshot', () async {
      // Five-day pruning is for routine copies. A backup displaced by a new
      // setup may be the only copy of a vault nothing on this phone can open.
      final name = AutoBackupService.displacedNameFor(DateTime.now());
      expect(
        RegExp(r'^karde-backup-\d{4}-\d{2}-\d{2}\.json$').hasMatch(name),
        isFalse,
      );
    });

    test('an empty folder is set up without leaving stray files', () async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);

      expect(folder.files.keys, [AutoBackupService.currentFileName]);
    });

    test('setup stops rather than destroying what it could not move', () async {
      // If the old backup cannot be copied to safety, carrying on is exactly
      // the case that destroys somebody's only copy.
      final original = existingBackup();
      folder.files[AutoBackupService.currentFileName] = original;
      folder.failWritesTo = RegExp('^karde-backup-replaced-');

      await expectLater(
        service.configure(passphrase: 'p', folderChoice: chosenFolder),
        throwsA(isA<BackupFolderUnavailable>()),
      );

      expect(
        folder.files[AutoBackupService.currentFileName],
        original,
        reason: 'the original is untouched',
      );
      expect(await service.isConfigured, isFalse);
    });

    test('Karde can say a backup is already there before writing', () async {
      // So the setup screen can offer to restore instead of quietly starting
      // over. Reads only; changes nothing.
      final original = existingBackup();
      folder.files[AutoBackupService.currentFileName] = original;

      expect(await service.existingBackupChangedAt(chosenFolder.uri), isNotNull);
      expect(folder.files[AutoBackupService.currentFileName], original);
    });

    test('and says there is none when the folder is empty', () async {
      expect(await service.existingBackupChangedAt(chosenFolder.uri), isNull);
    });
  });

  group('Keeping up with the vault', () {
    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
      folder.writes = 0;
    });

    test('a saved item is sealed and written', () async {
      await service.recordSave(id: 'card:1', plaintext: '{"nickname":"Visa"}');

      expect(identity.seals, 1);
      expect(folder.writes, 1);
      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, ['card:1']);
    });

    test('sealing needs no passphrase and no prompt', () async {
      // The reason automatic backup is possible at all. Karde has the item in
      // plain form at the moment of saving and needs nothing from the Keystore.
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}');

      expect(identity.seals, 1);
    });

    test('editing the same item replaces it', () async {
      await service.recordSave(id: 'card:1', plaintext: '{"nickname":"old"}');
      await service.recordSave(id: 'card:1', plaintext: '{"nickname":"new"}');

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.count, 1);
      expect(file.sealedRecords.single, contains('new'));
    });

    test('cards and IDs live side by side', () async {
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}');
      await service.recordSave(id: 'id:1', plaintext: '{"b":2}');

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.count, 2, reason: 'the ids must not collide across types');
    });

    test('a deleted item is dropped from the backup', () async {
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}');
      await service.recordSave(id: 'id:1', plaintext: '{"b":2}');

      await service.recordDelete('card:1');

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, ['id:1']);
    });

    test('deleting something the backup never had writes nothing', () async {
      // An item saved before backup was set up. Ordinary, not an error, and not
      // worth rewriting the file over.
      await service.recordDelete('card:404');

      expect(folder.writes, 0);
    });
  });

  group('Keeping a few days of history', () {
    // An automatic backup is instant, and that is its one weakness: delete a
    // card by mistake and, with only a current file, the backup agrees with you
    // a second later and the card is gone from both places at once.

    /// Puts a backup in the folder that was last written [daysAgo] days ago.
    void seedBackupFrom(int daysAgo, {List<String> ids = const []}) {
      final when = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
      final records = <String, dynamic>{
        for (final id in ids) id: {'k': 'K', 'iv': 'IV', 'd': 'D'},
      };
      folder.files[AutoBackupService.currentFileName] = jsonEncode({
        'format': 'karde.autobackup',
        'version': 1,
        'createdAt': when.toIso8601String(),
        'updatedAt': when.toIso8601String(),
        'sealedPrivateKey': 'SEALED-PRIVATE',
        'records': records,
      });
    }

    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
    });

    test('the first change of the day preserves yesterday', () async {
      seedBackupFrom(1, ids: ['card:1']);

      await service.recordSave(id: 'card:2', plaintext: '{"a":1}');

      final yesterday = AutoBackupService.snapshotNameFor(
        DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(folder.files, contains(yesterday));
      final kept = AutoBackupFile.decode(folder.files[yesterday]!);
      expect(kept.ids, ['card:1'],
          reason: 'the snapshot must hold what the day ended with, not what '
              'the new save contains');
    });

    test('later changes the same day do not pile up copies', () async {
      // One write per day, not one per save. The rest of the day's edits should
      // cost a single write each, as they should.
      seedBackupFrom(1, ids: ['card:1']);
      await service.recordSave(id: 'card:2', plaintext: '{"a":1}');
      final afterFirst = folder.files.keys.toSet();

      await service.recordSave(id: 'card:3', plaintext: '{"b":2}');

      expect(folder.files.keys.toSet(), afterFirst);
    });

    test('a change on the same day it was written keeps no copy', () async {
      seedBackupFrom(0, ids: ['card:1']);

      await service.recordSave(id: 'card:2', plaintext: '{"a":1}');

      expect(folder.files.keys.where((n) => n != AutoBackupService.currentFileName),
          isEmpty);
    });

    test('old copies are pruned, the newest kept', () async {
      for (var day = 1; day <= AutoBackupService.keepDays + 3; day++) {
        folder.files[AutoBackupService.snapshotNameFor(
          DateTime.now().toUtc().subtract(Duration(days: day)),
        )] = '{}';
      }
      seedBackupFrom(1, ids: ['card:1']);

      await service.recordSave(id: 'card:2', plaintext: '{"a":1}');

      final snapshots = folder.files.keys
          .where((n) => n != AutoBackupService.currentFileName)
          .toList();
      expect(snapshots, hasLength(AutoBackupService.keepDays));
      final oldest = AutoBackupService.snapshotNameFor(
        DateTime.now().toUtc().subtract(
              Duration(days: AutoBackupService.keepDays + 3),
            ),
      );
      expect(snapshots, isNot(contains(oldest)));
    });

    test('a folder that cannot hold history can still hold a backup', () async {
      // History is a kindness on top of the current file. Losing the kindness is
      // no reason to lose the backup.
      seedBackupFrom(1, ids: ['card:1']);
      folder.failListing = true;

      await service.recordSave(id: 'card:2', plaintext: '{"a":1}');

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, containsAll(['card:1', 'card:2']));
    });
  });

  group('Reading a backup back', () {
    // The only test that matters in the end. Everything else here checks that
    // the file is written correctly; this checks that what was written can be
    // turned back into a vault.
    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
    });

    test('a card written automatically comes back as a card', () async {
      await service.recordSave(
        id: 'card:1',
        plaintext: jsonEncode({
          'nickname': 'Horizon Bank',
          'cardBrand': 'Visa',
          'lastFourDigits': '1234',
          'secrets': {'cardNumber': '4111111111111234'},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );

      final backup = await service.openBackupFile(
        contents: folder.files[AutoBackupService.currentFileName]!,
        passphrase: 'p',
      );

      expect(backup.cards, hasLength(1));
      expect(backup.ids, isEmpty);
      expect(backup.cards.single.nickname, 'Horizon Bank');
      expect(backup.cards.single.secrets['cardNumber'], '4111111111111234');
    });

    test('a document comes back as a document, not a card', () async {
      // The record id is the only thing that says which is which, because both
      // are just JSON once opened. Getting this wrong would restore someone's
      // passport as a credit card.
      await service.recordSave(
        id: 'id:1',
        plaintext: jsonEncode({
          'nickname': 'My Passport',
          'idType': 'Passport',
          'fields': {'documentNumber': 'X1234567'},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );

      final backup = await service.openBackupFile(
        contents: folder.files[AutoBackupService.currentFileName]!,
        passphrase: 'p',
      );

      expect(backup.cards, isEmpty);
      expect(backup.ids, hasLength(1));
      expect(backup.ids.single.nickname, 'My Passport');
    });

    test('cards and documents in one file are sorted correctly', () async {
      await service.recordSave(
        id: 'card:1',
        plaintext: jsonEncode({
          'nickname': 'A card',
          'cardBrand': 'Visa',
          'lastFourDigits': '1234',
          'secrets': <String, dynamic>{},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );
      await service.recordSave(
        id: 'id:1',
        plaintext: jsonEncode({
          'nickname': 'A document',
          'idType': 'Passport',
          'fields': <String, dynamic>{},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );

      final backup = await service.openBackupFile(
        contents: folder.files[AutoBackupService.currentFileName]!,
        passphrase: 'p',
      );

      expect(backup.cards.single.nickname, 'A card');
      expect(backup.ids.single.nickname, 'A document');
    });

    test('a deleted card does not come back', () async {
      await service.recordSave(
        id: 'card:1',
        plaintext: jsonEncode({
          'nickname': 'Deleted',
          'cardBrand': 'Visa',
          'lastFourDigits': '1234',
          'secrets': <String, dynamic>{},
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );
      await service.recordDelete('card:1');

      final backup = await service.openBackupFile(
        contents: folder.files[AutoBackupService.currentFileName]!,
        passphrase: 'p',
      );

      expect(backup.cards, isEmpty);
    });
  });

  group('When the folder goes away', () {
    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
    });

    test('a failed save is not swallowed', () async {
      // The worst outcome this feature can have is a backup that quietly stopped
      // working months ago, whose owner believes they are covered.
      folder.reachable = false;

      expect(
        () => service.recordSave(id: 'card:1', plaintext: '{"a":1}'),
        throwsA(isA<BackupFolderUnavailable>()),
      );
    });

    test('the health check says so instead of throwing', () async {
      // Asked in the background to decide whether to warn. It has to answer.
      folder.reachable = false;

      expect(await service.isHealthy(), isFalse);
    });
  });

  group('Saving with no signal', () {
    // The case the user found within minutes of first using this: a Google Drive
    // folder and no connection. It used to fail silently AND lose the change —
    // each save read the folder's file, added its record and wrote it back, so a
    // save that never reached the folder left that card missing from the backup
    // permanently, or until it happened to be edited again.
    //
    // For a cloud folder, offline is not an exception. It is a plane, a train, a
    // basement, a country with no data.
    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
    });

    test('a card saved offline is not lost, it waits', () async {
      folder.reachable = false;

      await expectLater(
        service.recordSave(id: 'card:1', plaintext: '{"a":1}'),
        throwsA(isA<BackupFolderUnavailable>()),
      );

      expect(await service.behindFor(), isNotNull,
          reason: 'the backup knows it is behind');
    });

    test('and it lands the moment the folder is reachable again', () async {
      folder.reachable = false;
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}').catchError((_) {});

      folder.reachable = true;
      await service.flushPending();

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, ['card:1']);
      expect(await service.behindFor(), isNull);
    });

    test('several offline changes all arrive together', () async {
      folder.reachable = false;
      for (final id in ['card:1', 'card:2', 'id:1']) {
        await service.recordSave(id: id, plaintext: '{"a":1}').catchError((_) {});
      }

      folder.reachable = true;
      await service.flushPending();

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, containsAll(['card:1', 'card:2', 'id:1']));
    });

    test('editing the same card twice offline arrives once', () async {
      // Not five copies of one card for five edits on a train.
      folder.reachable = false;
      await service.recordSave(id: 'card:1', plaintext: '{"v":"first"}')
          .catchError((_) {});
      await service.recordSave(id: 'card:1', plaintext: '{"v":"second"}')
          .catchError((_) {});

      folder.reachable = true;
      await service.flushPending();

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.count, 1);
      expect(file.sealedRecords.single, contains('second'));
    });

    test('a card added then deleted offline never reaches the backup', () async {
      // What the backup should hold is whatever happened last, not a replay of
      // every step that got there.
      folder.reachable = false;
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}')
          .catchError((_) {});
      await service.recordDelete('card:1').catchError((_) {});

      folder.reachable = true;
      await service.flushPending();

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.count, 0);
    });

    test('the wait is not restarted by each new change', () async {
      // "Behind since" has to be when it FIRST fell behind, or a user editing
      // daily on a broken folder would never be told, because the clock would
      // keep resetting.
      folder.reachable = false;
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}')
          .catchError((_) {});
      final first = await service.behindFor();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await service.recordSave(id: 'card:2', plaintext: '{"b":2}')
          .catchError((_) {});
      final second = await service.behindFor();

      expect(second!, greaterThanOrEqualTo(first!));
    });

    test('a queued change survives Karde being closed', () async {
      // The queue is a file, not memory. Someone who saves a card underground
      // and closes the app has not thereby lost it from the backup.
      folder.reachable = false;
      await service.recordSave(id: 'card:1', plaintext: '{"a":1}')
          .catchError((_) {});

      final afterRestart = AutoBackupService(
        settings: settings,
        folder: folder,
        identity: identity,
        pending: PendingBackupStore(directory: queueDirectory),
      );
      folder.reachable = true;
      await afterRestart.flushPending();

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, ['card:1']);
    });
  });

  group('A backup file that is there but unreadable', () {
    setUp(() async {
      await service.configure(passphrase: 'p', folderChoice: chosenFolder);
    });

    test('is never overwritten', () async {
      // It may be the only copy of a vault this phone can no longer decrypt.
      // Starting fresh over the top of it would destroy exactly that.
      folder.files[AutoBackupService.currentFileName] = 'corrupted rubbish';

      expect(
        () => service.recordSave(id: 'card:1', plaintext: '{"a":1}'),
        throwsA(isA<BackupFileUnreadable>()),
      );
      expect(
        folder.files[AutoBackupService.currentFileName],
        'corrupted rubbish',
      );
    });

    test('but a missing one is simply started again', () async {
      // Happens on the first save, and if the user moves or deletes the file
      // themselves. Refusing would leave them with no backup at all.
      folder.files.remove(AutoBackupService.currentFileName);

      await service.recordSave(id: 'card:1', plaintext: '{"a":1}');

      final file = AutoBackupFile.decode(
        folder.files[AutoBackupService.currentFileName]!,
      );
      expect(file.ids, ['card:1']);
    });
  });
}
