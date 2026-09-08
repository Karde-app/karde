import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'system_interaction_guard.dart';

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

  /// Hides the "SCREENSHOTS ON" banner in a capture build.
  ///
  ///   flutter build apk --dart-define=KARDE_ALLOW_SCREENSHOTS=true \
  ///                     --dart-define=KARDE_STORE_SCREENSHOTS=true
  ///
  /// Exists for one job: taking the Play Store listing images, which the banner
  /// would otherwise ruin. A second flag rather than deleting the banner, so the
  /// ordinary development capture build keeps its warning and only a build made
  /// deliberately for store images loses it.
  ///
  /// **This build is still unsecured.** FLAG_SECURE is off, screenshots and
  /// screen recording work everywhere, and nothing on screen says so any more.
  /// It must never be uploaded and never left on a phone holding real items.
  /// Keep it under its own artifact name, and run the pre-upload check on the
  /// compiled library before publishing anything.
  ///
  /// Has no effect on its own: with KARDE_ALLOW_SCREENSHOTS off there is no
  /// banner to hide and FLAG_SECURE is applied as normal.
  static const bool hideCaptureBanner = bool.fromEnvironment(
    'KARDE_STORE_SCREENSHOTS',
  );

  /// Whether the warning banner should be painted.
  static bool get showCaptureBanner => screenshotsAllowed && !hideCaptureBanner;

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

  /// Whether this phone will let Karde run when it is not on the screen.
  ///
  /// Nothing to do with windows, and it lives here only because this is the
  /// channel that already reaches the activity. It answers the question that
  /// broke expiry reminders: the alarm fired exactly on time, the phone woke for
  /// it, and Samsung's power manager never started the app to handle it. The
  /// reminder appeared within seconds of the app being exempted.
  ///
  /// Assumed unrestricted when the answer cannot be had, so a phone that does
  /// not understand the question is never accused of holding reminders back.
  static Future<bool> isBatteryUnrestricted() async {
    try {
      return await _channel.invokeMethod<bool>('batteryUnrestricted') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Opens Karde's own page in Android's settings.
  ///
  /// Where a refused permission is given back. Karde cannot simply ask again: a
  /// permission refused twice is "fixed" by Android and the system dialog never
  /// appears a third time, so an app that offers to ask is promising something
  /// that will not happen.
  static Future<void> openAppSettings() async {
    try {
      await SystemInteractionGuard.run(
        () async => _channel.invokeMethod<bool>('openAppSettings'),
      );
    } catch (_) {
      // A phone that will not open its own settings is not worth a message.
    }
  }

  /// Opens the system's own battery-optimisation list.
  ///
  /// The list, not the one-tap "allow this app" dialog: that dialog needs
  /// `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, which Google restricts to a short
  /// list of app categories a vault is not on, and asking for it would put the
  /// listing at risk. This screen needs no permission at all.
  static Future<void> openBatterySettings() async {
    try {
      await SystemInteractionGuard.run(
        () async => _channel.invokeMethod<bool>('openBatterySettings'),
      );
    } catch (_) {
      // A phone that will not open the screen is not worth an error message.
    }
  }
}
