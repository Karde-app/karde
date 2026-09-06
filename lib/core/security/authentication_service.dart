import 'package:flutter/material.dart';
import '../widgets/karde_feedback.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../../l10n/app_localizations.dart';
import '../storage/settings_repository.dart';
import 'encryption_service.dart';
import 'pin_verification_screen.dart';
import 'system_interaction_guard.dart';

/// What a biometric prompt's failure actually means for the user.
///
/// Separate from the wording, and top-level, so the decision can be tested on
/// its own — it is the kind of thing that regresses quietly and is only noticed
/// when a user is accused of failing at something they chose not to do.
enum BiometricFailure {
  /// Say nothing. The user stopped on purpose, or the system stopped for them.
  silent,

  /// There is nothing on this phone to check a fingerprint against.
  notEnrolled,

  /// The phone has suspended fingerprint unlock for a while.
  lockedOut,

  /// Something else went wrong with the phone's own check.
  unavailable,
}

/// Decides what a [LocalAuthExceptionCode] means for the person holding the phone.
///
/// Deciding to stop is not a failure. Pressing Back, tapping the prompt's own
/// cancel button, or letting it time out all raise an exception exactly as a
/// mismatched fingerprint would, and Karde used to answer every one of them with
/// "Biometric authentication failed" or "Could not confirm it was you, try
/// again". The user had not failed at anything; they had changed their mind, and
/// Karde told them off for it. Those cases are [BiometricFailure.silent], and
/// whatever happens next — the PIN screen, or simply staying put — is answer
/// enough on its own.
///
/// The genuine faults are kept apart from each other rather than flattened into
/// one message, because they call for different things from the user: enrol a
/// fingerprint, wait, or try something else entirely.
///
/// Anything unrecognised is [BiometricFailure.unavailable], which blames the
/// phone rather than the user. The plugin documents this enum as open to new
/// values, and a wrong guess here becomes an accusation.
BiometricFailure classifyBiometricFailure(LocalAuthExceptionCode code) {
  switch (code) {
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.userRequestedFallback:
    case LocalAuthExceptionCode.timeout:
    case LocalAuthExceptionCode.authInProgress:
      return BiometricFailure.silent;

    case LocalAuthExceptionCode.noBiometricsEnrolled:
    case LocalAuthExceptionCode.noBiometricHardware:
    case LocalAuthExceptionCode.noCredentialsSet:
      return BiometricFailure.notEnrolled;

    case LocalAuthExceptionCode.temporaryLockout:
    case LocalAuthExceptionCode.biometricLockout:
      return BiometricFailure.lockedOut;

    default:
      return BiometricFailure.unavailable;
  }
}

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
    final loc = AppLocalizations.of(context)!;
    final requirePinLock = settings.getRequirePinLock();
    final biometricUnlock = settings.getBiometricUnlock();
    final hasKardePin = await settings.hasKardePin();

    // A dedicated Karde PIN is the app-level factor for viewing secrets. Ask for
    // it first rather than treating it as a fallback after biometrics.
    // The same guard as the startup path, for the same reason. If the switch is
    // ever on with no PIN stored, the verification screen finds no hash, offers
    // to CREATE one, and counts that creation as having authenticated the user.
    // That hole has been closed twice already elsewhere; this was the last place
    // still relying on the state being unreachable rather than on a guard.
    if (requirePinLock && hasKardePin) {
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
          // Guarded for the reason SystemInteractionGuard exists: this prompt is
          // system UI Karde raised on purpose, and the activity going inactive
          // behind it is indistinguishable from the user walking away. Unguarded,
          // a slow authentication arms the auto-lock timer behind the very prompt
          // being answered. The vault's own prompts were fixed; this path was
          // missed.
          final authResult = await SystemInteractionGuard.run(
            () => _auth.authenticate(
            localizedReason: loc.authReasonRevealCard,
            authMessages: <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: loc.authRequiredTitle,
                cancelButton: loc.cancel,
              ),
              IOSAuthMessages(
                cancelButton: loc.cancel,
              ),
            ],
              biometricOnly: false,
            ),
          );
          if (authResult) return true;
        } else {
          if (context.mounted) {
            KardeFeedback.error(context, loc.biometricsNotEnrolled);
          }
        }
      } on LocalAuthException catch (e) {
        final message = _messageFor(e, loc);
        if (message != null && context.mounted) {
          KardeFeedback.error(context, message);
        }
      } catch (e) {
        if (context.mounted) KardeFeedback.error(context, loc.biometricUnavailableNow);
      }
    }

    // Fall back to the Karde PIN — but only if there is one.
    //
    // Without this guard, somebody who chose "Phone Lock" and never set a Karde
    // PIN could dismiss the fingerprint prompt, be offered the PIN screen, be
    // sent to CREATE a PIN because none existed, and have that creation count as
    // a successful authentication. Declining the only real factor became a way
    // in. When there is no second factor to fall back to, the answer is no.
    if (!hasKardePin) return false;
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



  /// The wording for [classifyBiometricFailure], or null to say nothing.
  String? _messageFor(LocalAuthException e, AppLocalizations loc) {
    switch (classifyBiometricFailure(e.code)) {
      case BiometricFailure.silent:
        return null;
      case BiometricFailure.notEnrolled:
        return loc.biometricsNotEnrolled;
      case BiometricFailure.lockedOut:
        return loc.biometricLockedOut;
      case BiometricFailure.unavailable:
        return loc.biometricUnavailableNow;
    }
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
    final loc = AppLocalizations.of(context)!;
    final hasKardePin = await settings.hasKardePin();
    final biometricUnlock = settings.getBiometricUnlock();
    final requirePinLock = settings.getRequirePinLock();

    if (biometricUnlock) {
      try {
        final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

        if (canAuthenticate) {
          // "Use Karde PIN" is only true for someone who has one. Offering it to
          // a Phone Lock user named a way in that does not exist, and the button
          // led nowhere.
          final cancelLabel = hasKardePin ? loc.useKardePin : loc.cancel;
          final phoneAuthResult = await SystemInteractionGuard.run(
            () => _auth.authenticate(
            localizedReason: loc.authReasonOpenKarde,
            authMessages: <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: loc.authRequiredTitle,
                cancelButton: cancelLabel,
              ),
              IOSAuthMessages(
                cancelButton: cancelLabel,
              ),
            ],
              biometricOnly: false,
            ),
          );
          if (phoneAuthResult) return true;
        } else {
          if (context.mounted) {
            KardeFeedback.error(context, loc.biometricsNotEnrolled);
          }
        }
      } on LocalAuthException catch (e) {
        final message = _messageFor(e, loc);
        if (message != null && context.mounted) {
          KardeFeedback.error(context, message);
        }
      } catch (e) {
        if (context.mounted) KardeFeedback.error(context, loc.biometricUnavailableNow);
      }
    }

    // Fall back to the Karde PIN — but only if the user asked for one, and only
    // if there is one.
    //
    // The switch used to be ignored here entirely. Opening the app asked for the
    // PIN whenever a PIN existed, so turning "App PIN lock" off changed nothing
    // about opening the app — the one thing its label promises. Reported from
    // the device: switched off, restarted, still asked for the Karde PIN.
    //
    // And only if there is one, for the reason spelled out in [authenticate]:
    // someone who chose Phone Lock has no Karde PIN, and sending them to the PIN
    // screen anyway found no stored hash, offered to CREATE a PIN, and let that
    // creation open the app. Cancelling the prompt was itself a way in.
    //
    // With neither switch on there is no app-level gate to apply, which is
    // exactly what the two switches say. Nothing is exposed by honouring that:
    // every item is still sealed by the Keystore and still demands
    // authentication of its own before it can be read.
    if (!requirePinLock) return !biometricUnlock;
    if (!hasKardePin) return false;
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
