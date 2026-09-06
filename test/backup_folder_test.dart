import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/platform/backup_folder_service.dart';

/// The folder is the part of automatic backup most able to fail quietly, and
/// most damaging when it does: a backup that stopped working months ago is worse
/// than none, because its owner believes they are covered.
///
/// So what is tested here is mostly the failures — that each one is recognised,
/// and that "you cancelled" never gets mistaken for "something is broken".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ibank.security/backup');
  final service = BackupFolderService();

  MethodCall? lastCall;
  late Object? Function(MethodCall) respond;

  setUp(() {
    lastCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      lastCall = call;
      final value = respond(call);
      if (value is PlatformException) throw value;
      return value;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Choosing a folder', () {
    test('returns somewhere the user can recognise', () async {
      // The raw handle means nothing to a person, and Karde has to be able to
      // say where the backups are going.
      respond = (_) => jsonEncode({
            'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADocuments',
            'label': 'Documents',
          });

      final choice = await service.choose();

      expect(choice.label, 'Documents');
      expect(choice.uri, startsWith('content://'));
    });

    test('backing out is not a failure', () async {
      // Distinct from every other outcome. Someone who closed the picker has not
      // hit a problem and must not be shown one.
      respond = (_) => PlatformException(code: 'FOLDER_CANCELLED');

      expect(service.choose(), throwsA(isA<BackupFolderNotChosen>()));
    });

    test('a phone with no folder picker is a real failure', () async {
      respond = (_) => PlatformException(code: 'NO_FOLDER_PICKER');

      expect(service.choose(), throwsA(isA<BackupFolderUnavailable>()));
    });
  });

  group('Checking the folder is still there', () {
    test('says no rather than throwing when it has gone', () async {
      // This is asked on a schedule, in the background, to decide whether to warn
      // the user. It has to answer, not explode.
      respond = (_) => PlatformException(code: 'BACKUP_FOLDER_UNAVAILABLE');

      expect(await service.isUsable('content://gone'), isFalse);
    });

    test('says yes when the platform says yes', () async {
      respond = (_) => true;

      expect(await service.isUsable('content://there'), isTrue);
      expect(lastCall!.method, 'backupFolderUsable');
    });
  });

  group('Reading and writing', () {
    test('a missing file reads as nothing, not as an error', () async {
      // The first backup on a fresh folder finds no file. That is the normal
      // beginning, not a fault.
      respond = (_) => null;

      expect(await service.read('content://there', 'karde-backup.json'), isNull);
    });

    test('a write that cannot land is reported, never swallowed', () async {
      // The one thing this must never do is fail silently.
      respond = (_) => PlatformException(
            code: 'BACKUP_FOLDER_UNAVAILABLE',
            message: 'No space left on device',
          );

      expect(
        () => service.write('content://there', 'karde-backup.json', '{}'),
        throwsA(isA<BackupFolderUnavailable>()),
      );
    });

    test('listing gives the names, for pruning old copies', () async {
      respond = (_) => jsonEncode(['karde-backup.json', 'karde-backup-2026-09-05.json']);

      expect(await service.list('content://there'), hasLength(2));
    });

    test('an empty folder lists as empty', () async {
      respond = (_) => null;

      expect(await service.list('content://there'), isEmpty);
    });
  });
}
