import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../storage/settings_repository.dart';
import 'pin_verification_screen.dart';

class AuthenticationService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate(BuildContext context, SettingsRepository settings) async {
    final lockType = await settings.getLockType();

    if (lockType == 'dedicated' || lockType == 'both') {
      // For 'dedicated' and 'both', Card Reveal ALWAYS uses the Karde PIN.
      // (The Phone Lock for 'both' is handled at app startup).
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinVerificationScreen(),
          fullscreenDialog: true,
        ),
      );
      return result ?? false;
    }

    // Default to local_auth (Phone Lock)
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      return await _auth.authenticate(
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
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateAppStartup(BuildContext context, SettingsRepository settings) async {
    final lockType = await settings.getLockType();
    
    // Phone lock at startup for 'phone' and 'both'
    if (lockType == 'phone' || lockType == 'both') {
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
        }
      } catch (_) {
        // Fall through to PinVerificationScreen
      }
      
      // Fallback to Karde PIN if phone lock fails or is cancelled
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

    // Karde PIN at startup for 'dedicated'
    if (lockType == 'dedicated') {
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
    
    return true;
  }
}
