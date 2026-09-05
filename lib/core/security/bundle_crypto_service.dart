import 'package:flutter/services.dart';

/// The passphrase was wrong, or the backup file has been altered.
///
/// These are deliberately one condition. AES-GCM cannot tell them apart, and
/// reporting them separately would let an attacker use the app as an oracle.
class BackupPassphraseIncorrect implements Exception {
  const BackupPassphraseIncorrect();
}

/// The chosen file is not a Karde backup, or its envelope is damaged.
///
/// [details] comes from the platform channel and is for diagnostics only. It
/// is never shown: it has no locale and no meaning to a user, so the screen
/// reporting this failure uses its own translated sentence instead.
class BackupFileUnreadable implements Exception {
  final String? details;
  const BackupFileUnreadable([this.details]);

  @override
  String toString() => 'BackupFileUnreadable(${details ?? 'no detail'})';
}

/// Any other failure while sealing or opening a backup.
class BackupCryptoFailure implements Exception {
  final String details;
  const BackupCryptoFailure(this.details);
}

/// Passphrase-based encryption of the portable backup bundle.
///
/// Distinct from [EncryptionService], and deliberately so. The vault key is a
/// hardware Keystore key that can never leave the device, which is exactly what
/// makes it useless for a backup meant to be restored on a different phone. The
/// bundle is therefore sealed with a key derived from a passphrase the user
/// chooses and has to remember.
///
/// The derivation and the AES-GCM work happen natively (see `BackupCrypto.kt`):
/// 600,000 PBKDF2 rounds are fast in Kotlin and would stall the UI for many
/// seconds in Dart, and the native implementation derives from UTF-8 bytes,
/// avoiding the platform SecretKeyFactory's truncation of passphrase characters
/// to 8 bits.
class BundleCryptoService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/backup');

  /// Seals [plaintext] and returns a self-describing JSON envelope.
  Future<String> seal(String plaintext, String passphrase) async {
    try {
      final envelope = await _channel.invokeMethod<String>('encryptBundle', {
        'data': plaintext,
        'passphrase': passphrase,
      });
      if (envelope == null) throw const BackupCryptoFailure('empty result');
      return envelope;
    } on PlatformException catch (e) {
      throw _mapError(e);
    }
  }

  /// Opens an envelope produced by [seal].
  Future<String> open(String envelope, String passphrase) async {
    try {
      final plaintext = await _channel.invokeMethod<String>('decryptBundle', {
        'data': envelope,
        'passphrase': passphrase,
      });
      if (plaintext == null) throw const BackupCryptoFailure('empty result');
      return plaintext;
    } on PlatformException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(PlatformException e) {
    switch (e.code) {
      case 'BAD_PASSPHRASE':
        return const BackupPassphraseIncorrect();
      case 'MALFORMED_BACKUP':
        return BackupFileUnreadable(e.message);
      default:
        return BackupCryptoFailure(e.message ?? e.code);
    }
  }
}
