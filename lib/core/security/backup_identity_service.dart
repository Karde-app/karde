import 'dart:convert';

import 'package:flutter/services.dart';

import 'bundle_crypto_service.dart';

/// This phone wrote a backup it could not read back.
///
/// Kept apart from every other failure because it is not the user's doing and
/// there is nothing they can do about it. Setup must not complete: letting it
/// through would leave someone believing they were covered by backups that will
/// never open.
class BackupSelfTestFailed implements Exception {
  const BackupSelfTestFailed();
}

/// The two halves of the automatic-backup key pair.
///
/// [publicKey] is not a secret and is stored in the clear. It can seal a new
/// record and can do nothing else, so it is safe to keep to hand all day — which
/// is what lets Karde write a backup on every save without asking for anything.
///
/// [sealedPrivateKey] is the other half, wrapped in a passphrase envelope. It
/// travels inside the backup file, so a restore on a new phone needs the file and
/// the passphrase and nothing more.
class BackupIdentity {
  const BackupIdentity({
    required this.publicKey,
    required this.sealedPrivateKey,
  });

  final String publicKey;
  final String sealedPrivateKey;

  factory BackupIdentity.fromJson(Map<String, dynamic> json) {
    final publicKey = json['publicKey'];
    final sealedPrivateKey = json['sealedPrivateKey'];
    if (publicKey is! String ||
        publicKey.isEmpty ||
        sealedPrivateKey is! String ||
        sealedPrivateKey.isEmpty) {
      throw const BackupFileUnreadable('backup identity is incomplete');
    }
    return BackupIdentity(
      publicKey: publicKey,
      sealedPrivateKey: sealedPrivateKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'sealedPrivateKey': sealedPrivateKey,
      };
}

/// Sealing and opening individual records of an automatic backup.
///
/// Separate from [BundleCryptoService], which seals the whole vault as one lump
/// under the passphrase. That shape cannot be written on every save: rebuilding
/// it means reading every item back out of the vault, and the vault key demands
/// one authentication prompt per item. Ten saved cards would be ten fingerprint
/// touches for a single edit.
///
/// So a record is sealed at the moment the user saves it, while Karde still has
/// it in plain form and needs nothing from the Keystore — which costs no prompts
/// at all. See `BackupIdentity.kt` for why that requires a key pair rather than a
/// passphrase-derived key held in memory.
class BackupIdentityService {
  static const MethodChannel _channel =
      MethodChannel('com.ibank.security/backup');

  /// Generates the pair. Slow on purpose — 3072-bit RSA — but only ever once.
  Future<BackupIdentity> create(String passphrase) async {
    final raw = await _invoke('createBackupIdentity', {
      'passphrase': passphrase,
    });
    return BackupIdentity.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Seals one record. No passphrase, no prompt, no secret in memory.
  Future<String> seal({
    required String publicKey,
    required String plaintext,
  }) {
    return _invoke('sealBackupRecord', {
      'publicKey': publicKey,
      'data': plaintext,
    });
  }

  /// Opens every record in one call.
  ///
  /// Not one at a time: recovering the private half costs 600,000 rounds of key
  /// derivation, and paying that per record would multiply a restore's wait by
  /// the number of items for no benefit, since the same key opens all of them.
  Future<List<String>> openAll({
    required String sealedPrivateKey,
    required String passphrase,
    required List<String> records,
  }) async {
    if (records.isEmpty) return const [];
    final raw = await _invoke('openBackupRecords', {
      'sealedPrivateKey': sealedPrivateKey,
      'passphrase': passphrase,
      'data': '[${records.join(',')}]',
    });
    return (jsonDecode(raw) as List).cast<String>();
  }

  /// Shares the error vocabulary of [BundleCryptoService] deliberately: to the
  /// user, "wrong passphrase" and "unreadable file" mean the same thing here as
  /// they do for a manual backup, and one set of messages covers both.
  Future<String> _invoke(String method, Map<String, dynamic> arguments) async {
    try {
      final value = await _channel.invokeMethod<String>(method, arguments);
      if (value == null) throw const BackupCryptoFailure('empty result');
      return value;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'BAD_PASSPHRASE':
          throw const BackupPassphraseIncorrect();
        case 'MALFORMED_BACKUP':
          throw BackupFileUnreadable(e.message ?? 'malformed backup');
        case 'BACKUP_SELF_TEST_FAILED':
          throw const BackupSelfTestFailed();
        default:
          throw BackupCryptoFailure(e.message ?? e.code);
      }
    }
  }
}
