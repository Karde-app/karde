import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/security/backup_identity_service.dart';
import 'package:ibank/core/security/bundle_crypto_service.dart';

/// The native half is proved on the device by the self-test inside
/// `BackupIdentity.create`, which is the only place the real crypto can be
/// checked against the phone's own providers. What is testable here is the layer
/// above it: that the arguments reach the platform correctly, that results are
/// parsed, and — most importantly — that each way the platform can say "no"
/// becomes the right thing for the rest of the app to catch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ibank.security/backup');
  final service = BackupIdentityService();

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

  group('Creating the pair', () {
    test('returns both halves and passes the passphrase through', () async {
      respond = (_) => jsonEncode({
            'publicKey': 'PUB',
            'sealedPrivateKey': '{"format":"karde.backup"}',
          });

      final identity = await service.create('correct horse battery staple');

      expect(identity.publicKey, 'PUB');
      expect(identity.sealedPrivateKey, '{"format":"karde.backup"}');
      expect(lastCall!.method, 'createBackupIdentity');
      expect(
        (lastCall!.arguments as Map)['passphrase'],
        'correct horse battery staple',
      );
    });

    test('a half-written pair is refused rather than stored', () async {
      // Storing a public half with no private half would give someone a backup
      // that seals perfectly and can never be opened.
      respond = (_) => jsonEncode({'publicKey': 'PUB', 'sealedPrivateKey': ''});

      expect(
        () => service.create('passphrase'),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('a phone that cannot read back its own backup stops setup', () async {
      respond = (_) => PlatformException(code: 'BACKUP_SELF_TEST_FAILED');

      expect(
        () => service.create('passphrase'),
        throwsA(isA<BackupSelfTestFailed>()),
        reason: 'This must not be flattened into a generic failure. It is the '
            'one error that means the user must not be told they are covered.',
      );
    });
  });

  group('Sealing a record', () {
    test('sends the public half and the plaintext, and no passphrase', () async {
      // The absence of a passphrase here is the design, not an oversight: this
      // runs on every save, and nothing capable of opening the backup should be
      // anywhere near it.
      respond = (_) => '{"k":"K","iv":"IV","d":"D"}';

      final sealed = await service.seal(publicKey: 'PUB', plaintext: '{"a":1}');

      expect(sealed, '{"k":"K","iv":"IV","d":"D"}');
      expect(lastCall!.method, 'sealBackupRecord');
      final args = lastCall!.arguments as Map;
      expect(args['publicKey'], 'PUB');
      expect(args['data'], '{"a":1}');
      expect(args.containsKey('passphrase'), isFalse);
    });
  });

  group('Opening records', () {
    test('opens the whole set in one call', () async {
      // One call, because recovering the private half costs 600,000 rounds of
      // key derivation and the same key opens every record.
      respond = (_) => jsonEncode(['{"one":1}', '{"two":2}']);

      final opened = await service.openAll(
        sealedPrivateKey: 'SEALED',
        passphrase: 'passphrase',
        records: ['{"k":"a"}', '{"k":"b"}'],
      );

      expect(opened, ['{"one":1}', '{"two":2}']);
      expect(lastCall!.method, 'openBackupRecords');
      expect((lastCall!.arguments as Map)['data'], '[{"k":"a"},{"k":"b"}]');
    });

    test('an empty set never reaches the platform', () async {
      respond = (_) => fail('should not have been called');

      expect(await service.openAll(
        sealedPrivateKey: 'SEALED',
        passphrase: 'passphrase',
        records: const [],
      ), isEmpty);
      expect(lastCall, isNull);
    });

    test('a wrong passphrase is reported as a wrong passphrase', () async {
      respond = (_) => PlatformException(code: 'BAD_PASSPHRASE');

      expect(
        () => service.openAll(
          sealedPrivateKey: 'SEALED',
          passphrase: 'wrong',
          records: ['{"k":"a"}'],
        ),
        throwsA(isA<BackupPassphraseIncorrect>()),
      );
    });

    test('a damaged file is not reported as a wrong passphrase', () async {
      // These must stay apart. Telling someone their passphrase is wrong when
      // the file is damaged sends them hunting for a mistake they did not make.
      respond = (_) => PlatformException(code: 'MALFORMED_BACKUP');

      expect(
        () => service.openAll(
          sealedPrivateKey: 'SEALED',
          passphrase: 'right',
          records: ['{"k":"a"}'],
        ),
        throwsA(isA<BackupFileUnreadable>()),
      );
    });

    test('anything else is a plain failure, not a passphrase accusation', () async {
      respond = (_) => PlatformException(code: 'SOMETHING_ELSE', message: 'oh dear');

      expect(
        () => service.openAll(
          sealedPrivateKey: 'SEALED',
          passphrase: 'right',
          records: ['{"k":"a"}'],
        ),
        throwsA(isA<BackupCryptoFailure>()),
      );
    });
  });
}
