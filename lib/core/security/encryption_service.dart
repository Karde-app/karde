import 'package:flutter/services.dart';

import 'system_interaction_guard.dart';

/// The user dismissed the OS authentication prompt. Not an error condition —
/// callers should simply stop, without showing a failure message.
class VaultAuthCancelled implements Exception {
  const VaultAuthCancelled();
}

/// The device has no secure lock screen, so an auth-gated key cannot exist.
/// FIX 2-1 / 4-2: surfaced as its own type so the UI can explain the real
/// problem instead of dumping a raw Java IllegalStateException at the user.
class VaultUnavailable implements Exception {
  const VaultUnavailable();
}

/// The Keystore key was permanently invalidated (lock screen removed, or
/// biometric enrolment reset). Existing vault data can no longer be decrypted.
class VaultKeyInvalidated implements Exception {
  const VaultKeyInvalidated();
}

/// Any other cryptographic failure.
class VaultCryptoFailure implements Exception {
  final String details;
  const VaultCryptoFailure(this.details);
}

class EncryptionService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/encryption');

  /// True while an OS authentication prompt raised by this service is on screen.
  ///
  /// Showing BiometricPrompt drives the Flutter activity `inactive`, which looks
  /// identical to the user backgrounding the app. Without this flag the auto-lock
  /// grace timer runs while the user is still standing at the vault's own prompt,
  /// so a slow authentication locks the app behind the very prompt being answered
  /// — producing a second, redundant prompt the moment the first one succeeds.
  ///
  /// The counter itself now lives in [SystemInteractionGuard], because the backup
  /// file picker needs exactly the same suppression. This getter is kept as the
  /// name the vault code already reads.
  static bool get isPromptInFlight => SystemInteractionGuard.isActive;

  /// Whether this device can hold the auth-gated vault key at all.
  ///
  /// FIX 4-2: checked before the user fills in a form, so a device without a
  /// secure lock screen is told up front rather than after typing a full card.
  /// Opens the phone's own security settings, where a screen lock is set.
  ///
  /// Karde has several places that tell the user their phone needs a screen
  /// lock, and until now every one of them stopped at saying so. Returns false
  /// if the phone has no such screen to open, so the caller can leave the button
  /// out rather than offering one that does nothing.
  Future<bool> openSecuritySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openSecuritySettings') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> canUseVault() async {
    try {
      return await _channel.invokeMethod<bool>('canUseVaultKey') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Whether every single use of the vault key is guaranteed to raise its own OS
  /// prompt.
  ///
  /// True only on API 30+, where the key is built with per-use authentication.
  /// On API 24–29 the key falls back to a ten-second validity window, so a
  /// second decrypt inside that window succeeds silently. Also false when the
  /// device has no secure lock screen, since then the key cannot be used at all.
  ///
  /// [AuthenticationService] consults this before deciding it may skip the Karde
  /// PIN on the grounds that the Keystore will prompt anyway. Assuming that
  /// without checking would, on an older device with the window still open,
  /// reveal secrets with no authentication at all.
  ///
  /// Fails closed: any error means "no, do not skip your own gate".
  Future<bool> willPromptEveryUse() async {
    try {
      return await _channel.invokeMethod<bool>('willPromptEveryUse') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Whether the fingerprints or faces on this phone changed since Karde last
  /// looked.
  ///
  /// Purely informational, and deliberately so. Enrolling a finger needs the
  /// phone's own screen lock, so it is something the owner agreed to — and the
  /// vault key already accepts that same screen lock, so a new fingerprint grants
  /// an attacker nothing they could not already do. Karde therefore reports the
  /// change rather than reacting to it. Nothing is locked, and no stored record
  /// is touched.
  ///
  /// Raises no authentication prompt, and returns false on the first ever call,
  /// which only establishes the baseline.
  ///
  /// Fails closed in the quiet direction: any error reports "nothing changed",
  /// because a diagnostic must never invent an alarm.
  Future<bool> biometricsChanged() async {
    try {
      return await _channel.invokeMethod<bool>('biometricsChanged') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<String> encrypt(String plaintext) {
    return SystemInteractionGuard.run(() async {
      try {
        final encrypted = await _channel.invokeMethod<String>(
          'encrypt',
          {'data': plaintext},
        );
        if (encrypted == null) throw const VaultCryptoFailure('empty result');
        return encrypted;
      } on PlatformException catch (e) {
        throw _mapError(e);
      }
    });
  }

  Future<String> decrypt(String encryptedText) {
    return SystemInteractionGuard.run(() async {
      try {
        final decrypted = await _channel.invokeMethod<String>(
          'decrypt',
          {'data': encryptedText},
        );
        if (decrypted == null) throw const VaultCryptoFailure('empty result');
        return decrypted;
      } on PlatformException catch (e) {
        throw _mapError(e);
      }
    });
  }

  Exception _mapError(PlatformException e) => mapVaultPlatformError(e);
}

/// Turns a failure from the native vault channel into one of the typed vault
/// exceptions above.
///
/// Shared with [VaultImageService], which drives the same Keystore key over the
/// same channel and must classify a dismissed prompt or a missing lock screen
/// identically — a photo that failed to decrypt because the user pressed Cancel
/// has to stay as silent as a card that did.
Exception mapVaultPlatformError(PlatformException e) {
  switch (e.code) {
    case 'AUTH_CANCELLED':
      return const VaultAuthCancelled();
    case 'NO_SECURE_LOCK_SCREEN':
      return const VaultUnavailable();
    case 'KEY_INVALIDATED':
      return const VaultKeyInvalidated();
    default:
      return VaultCryptoFailure(e.message ?? e.code);
  }
}
