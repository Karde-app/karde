import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowSecurityService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/window');

  /// Development escape hatch for screen capture.
  ///
  /// FLAG_SECURE blocks all screenshots and screen recording, which also makes it
  /// impossible to capture the UI while working on it (`adb screencap` returns a
  /// black frame on every secured screen). Enable capture for a dev build with:
  ///
  ///   flutter build apk --dart-define=KARDE_ALLOW_SCREENSHOTS=true
  ///
  /// This defaults to false, so any build produced WITHOUT that flag — including
  /// every Play Store build — keeps FLAG_SECURE and behaves exactly as before.
  /// Never pass the flag for a build you intend to publish. When it is on, the app
  /// shows a permanent red "SCREENSHOTS ON" banner so an unsecured build cannot be
  /// mistaken for a real one.
  static const bool screenshotsAllowed = bool.fromEnvironment(
    'KARDE_ALLOW_SCREENSHOTS',
  );

  Future<void> enableSecureMode() async {
    // In a capture-enabled dev build, actively clear the flag instead of setting
    // it, so screens that request secure mode remain capturable.
    if (screenshotsAllowed) {
      await disableSecureMode();
      return;
    }
    try {
      await _channel.invokeMethod('secure');
      _lastSecureModeFailed = false;
    } on PlatformException catch (e) {
      // FIX 4-4: this was silently ignored. If FLAG_SECURE cannot be applied the
      // app carries on with screenshot and task-switcher protection disabled and
      // nobody is any the wiser — the exact opposite of the guarantee the vault
      // makes to the user. Record it and log it so it is at least observable.
      _lastSecureModeFailed = true;
      debugPrint(
        'Karde: FLAG_SECURE could not be applied (${e.code}). '
        'Screenshot protection is NOT active.',
      );
    }
  }

  Future<void> disableSecureMode() async {
    try {
      await _channel.invokeMethod('unsecure');
    } on PlatformException catch (e) {
      debugPrint('Karde: failed to clear FLAG_SECURE (${e.code}).');
    }
  }

  /// True if the most recent attempt to enable screenshot protection failed.
  /// Surfaced so the UI can warn the user that the vault is not protected.
  static bool get lastSecureModeFailed => _lastSecureModeFailed;
  static bool _lastSecureModeFailed = false;
}
