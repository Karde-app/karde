import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/security/bundle_crypto_service.dart';
import 'package:ibank/features/backup/data/auto_backup_file.dart';

void main() {
  const sealedKey = '{"format":"karde.backup","data":"..."}';
  const sealedRecord = '{"k":"KEY","iv":"IV","d":"DATA"}';

  group('A file survives being written and read back', () {
    test('an empty backup round-trips', () {
      final file = AutoBackupFile.empty(sealedKey);

      final reopened = AutoBackupFile.decode(file.encode());

      expect(reopened.count, 0);
      expect(reopened.sealedPrivateKey, sealedKey);
    });

    test('records round-trip with their ids', () {
      final file = AutoBackupFile.empty(sealedKey);
      file.put('card:1', sealedRecord);
      file.put('id:7', '{"k":"K2","iv":"I2","d":"D2"}');

      final reopened = AutoBackupFile.decode(file.encode());

      expect(reopened.count, 2);
      expect(reopened.ids, containsAll(['card:1', 'id:7']));
      expect(reopened.sealedRecords, hasLength(2));
    });

    test('the key needed to open it travels inside it', () {
      // The point of this: a restore on a new phone needs the file and the
      // passphrase and nothing else. No account, no server, nothing left behind
      // on the old phone.
      final file = AutoBackupFile.empty(sealedKey);

      final written = jsonDecode(file.encode()) as Map<String, dynamic>;

      expect(written['sealedPrivateKey'], sealedKey);
    });

    test('it says what it is, in the clear', () {
      // Someone finding this file in their Documents folder should be able to
      // tell what it is without Karde.
      final written =
          jsonDecode(AutoBackupFile.empty(sealedKey).encode()) as Map<String, dynamic>;

      expect(written['format'], 'karde.autobackup');
      expect(written['version'], 1);
    });
  });

  group('Editing one record leaves the rest alone', () {
    test('saving the same item twice replaces it, never duplicates it', () {
      // Every write is an upsert of one known record. A list would mean scanning
      // to find it, and two copies of one card is a restore that brings back a
      // card the user edited months ago.
      final file = AutoBackupFile.empty(sealedKey);
      file.put('card:1', sealedRecord);
      file.put('card:1', '{"k":"NEWKEY","iv":"NEWIV","d":"NEWDATA"}');

      expect(file.count, 1);
      expect(file.sealedRecords.single, contains('NEWDATA'));
    });

    test('deleting an item removes only that item', () {
      final file = AutoBackupFile.empty(sealedKey);
      file.put('card:1', sealedRecord);
      file.put('id:7', sealedRecord);

      expect(file.remove('card:1'), isTrue);

      expect(file.count, 1);
      expect(file.ids.single, 'id:7');
    });

    test('deleting something that was never there is not a failure', () {
      // Deleting an item saved before automatic backup was set up reaches here
      // with nothing to remove. That is ordinary, not an error.
      final file = AutoBackupFile.empty(sealedKey);

      expect(file.remove('card:99'), isFalse);
    });
  });

  group('A file it does not understand is refused, not guessed at', () {
    test('rubbish is refused', () {
      expect(
        () => AutoBackupFile.decode('this is not json'),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('somebody else\'s JSON is refused', () {
      expect(
        () => AutoBackupFile.decode('{"format":"something.else"}'),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('a file from a newer Karde is refused rather than downgraded', () {
      // The dangerous case. Quietly accepting a format that has moved on, and
      // then writing it back in this one's shape, destroys whatever the newer
      // format was carrying — silently, on the next save.
      expect(
        () => AutoBackupFile.decode(jsonEncode({
          'format': 'karde.autobackup',
          'version': 99,
          'sealedPrivateKey': sealedKey,
          'records': {},
        })),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('a file with no key to open it is refused', () {
      // Otherwise Karde would go on writing to a file nobody can ever open.
      expect(
        () => AutoBackupFile.decode(jsonEncode({
          'format': 'karde.autobackup',
          'version': 1,
          'records': {},
        })),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('a missing records section reads as no records, not as damage', () {
      final file = AutoBackupFile.decode(jsonEncode({
        'format': 'karde.autobackup',
        'version': 1,
        'sealedPrivateKey': sealedKey,
      }));

      expect(file.count, 0);
    });
  });

  group('Changing the passphrase rewraps the key and nothing else', () {
    const newSealedKey = '{"format":"karde.backup","data":"REWRAPPED"}';

    test('every record is carried across untouched', () {
      // The reason a passphrase change is cheap: the records are sealed with the
      // public half of a key pair the passphrase never touches. If this ever
      // started dropping or altering records, a passphrase change would quietly
      // destroy the backup it was meant to protect.
      final file = AutoBackupFile.empty('{"format":"karde.backup","data":"OLD"}');
      file.put('card:1', '{"k":"K1","iv":"I1","d":"D1"}');
      file.put('id:7', '{"k":"K2","iv":"I2","d":"D2"}');

      final moved = AutoBackupFile.decode(
        file.withSealedPrivateKey(newSealedKey).encode(),
      );

      expect(moved.sealedPrivateKey, newSealedKey);
      expect(moved.count, 2);
      expect(moved.ids, containsAll(['card:1', 'id:7']));
      expect(moved.sealedRecords, containsAll(file.sealedRecords));
    });

    test('the original is left alone, so a failed write strands nothing', () {
      const oldSealedKey = '{"format":"karde.backup","data":"OLD"}';
      final file = AutoBackupFile.empty(oldSealedKey);
      file.put('card:1', '{"k":"K1","iv":"I1","d":"D1"}');

      final moved = file.withSealedPrivateKey(newSealedKey);
      moved.remove('card:1');

      expect(file.sealedPrivateKey, oldSealedKey);
      expect(file.count, 1);
    });

    test('the backup keeps the date it was first made', () {
      // Otherwise a passphrase change would look, to anyone checking, like the
      // history had been thrown away and started again.
      final file = AutoBackupFile.empty('{"format":"karde.backup","data":"OLD"}');
      final createdAt = file.createdAt;

      final moved = file.withSealedPrivateKey(newSealedKey);

      expect(moved.createdAt, createdAt);
    });
  });
}
