import 'package:flutter/material.dart';
import '../widgets/karde_feedback.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../storage/settings_repository.dart';
import 'encryption_service.dart';
import 'pin_verification_screen.dart';

class AuthenticationService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Gate access to secrets.
  ///
  /// Set [cryptoWillPrompt] when the caller immediately performs a Keystore
  /// operation that itself requires OS authentication (FIX 2-1). That operation
  /// raises its own BiometricPrompt bound to a CryptoObject, so running a
  /// biometric check here as well asks the user for the same fingerprint twice
  /// in a row. The hardware-backed prompt is the stronger of the two, so this
  /// one is skipped rather than that one.
  ///
  /// The Karde PIN is skipped on the same grounds, but only where the OS can be
  /// relied upon to prompt for this very operation — see [_osWillGate]. Users
  /// reported the old behaviour as a fault: with "Biometric unlock" switched off
  /// they still got a fingerprint prompt, immediately after typing their PIN, and
  /// nothing explained why. The device prompt is the hardware-backed gate and
  /// cannot be removed without undoing FIX 2-1, so the app-level PIN is the one
  /// that gives way. The PIN still guards opening Karde, so the vault does not
  /// lose its "something you know" factor.
  Future<bool> authenticate(
    BuildContext context,
    SettingsRepository settings, {
    bool cryptoWillPrompt = false,
  }) async {
    final requirePinLock = settings.getRequirePinLock();
    final biometricUnlock = settings.getBiometricUnlock();

    // A dedicated Karde PIN is the app-level factor for viewing secrets. Ask for
    // it first rather than treating it as a fallback after biometrics.
    if (requirePinLock) {
      if (await _osWillGate(cryptoWillPrompt)) return true;

      if (!context.mounted) return false;
      final pinResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinVerificationScreen(),
          fullscreenDialog: true,
        ),
      );
      return pinResult ?? false;
    }

    // No Karde PIN configured, and the Keystore is about to prompt anyway.
    if (await _osWillGate(cryptoWillPrompt)) return true;

    if (biometricUnlock) {
      try {
        final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

        if (canAuthenticate) {
          final authResult = await _auth.authenticate(
            localizedReason: 'Please authenticate to reveal sensitive card information.',
            authMessages: const <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: 'Authentication Required',
                cancelButton: 'Cancel',
              ),
              IOSAuthMessages(
                cancelButton: 'Cancel',
              ),
            ],
            biometricOnly: false,
          );
          if (authResult) return true;
        } else {
          if (context.mounted) {
            KardeFeedback.error(context, 'Biometrics not supported or not enrolled on this device.');
          }
        }
      } catch (e) {
        if (context.mounted) {
          KardeFeedback.error(context, 'Biometric authentication failed. Please use PIN.');
        }
      }
    }

    // Unconditional fallback: if biometrics failed/cancelled, or if both are somehow disabled, force PIN.
    if (!context.mounted) return false;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinVerificationScreen(),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }



  /// Whether the operation the caller is about to perform will itself be gated
  /// by the operating system, making an app-level gate here redundant.
  ///
  /// Deliberately stricter than "the caller says a crypto operation follows".
  /// The vault key only prompts for *every* use from API 30; below that it is
  /// authorised for a ten-second window, so a decrypt shortly after another
  /// authenticated operation raises nothing at all. Standing down on that
  /// assumption would show a card with no authentication whatsoever.
  ///
  /// Fails closed — anything unexpected means the app asks for its own factor.
  Future<bool> _osWillGate(bool cryptoWillPrompt) async {
    if (!cryptoWillPrompt) return false;
    try {
      return await EncryptionService().willPromptEveryUse();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateAppStartup(BuildContext context, SettingsRepository settings) async {
    final requirePinLock = settings.getRequirePinLock();
    final biometricUnlock = settings.getBiometricUnlock();

    if (biometricUnlock) {
      try {
        final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

        if (canAuthenticate) {
          final phoneAuthResult = await _auth.authenticate(
            localizedReason: 'Please authenticate to open Karde.',
            authMessages: const <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: 'Authentication Required',
                cancelButton: 'Use Karde PIN',
              ),
              IOSAuthMessages(
                cancelButton: 'Use Karde PIN',
              ),
            ],
            biometricOnly: false,
          );
          if (phoneAuthResult) return true;
        } else {
          if (context.mounted) {
            KardeFeedback.error(context, 'Biometrics not supported or not enrolled on this device.');
          }
        }
      } catch (e) {
        if (context.mounted) {
          KardeFeedback.error(context, 'Biometric authentication failed. Please use PIN.');
        }
      }
    }
    
    // Unconditional fallback: force PIN lock if biometrics failed/skipped, or both disabled.
    if (!context.mounted) return false;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinVerificationScreen(),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }
}
