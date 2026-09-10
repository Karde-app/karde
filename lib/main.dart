import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/startup_failure_app.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/settings_repository.dart';

/// Karde deliberately has no crash reporting. Adding one would mean adding the
/// INTERNET permission, and "this app cannot reach the network" is the whole
/// promise. The consequence is that anything failing silently is invisible to
/// us for ever, so startup is wrapped: a throw shows a screen that says so
/// rather than leaving a black rectangle the user cannot interpret or report.
void main() {
  runZonedGuarded(_bootstrap, (error, stack) {
    debugPrint('Karde: uncaught error — $error\n$stack');
    _showStartupFailure();
  });
}

/// True once [IBankApp] is actually on screen.
///
/// This is the guard that keeps the failure screen honest. Without it, any
/// async error later in the app's life — a plugin timing out, a stray future —
/// would tear down whatever the user was doing and replace it with "Karde
/// could not start", which by then would be a lie.
bool _appStarted = false;

/// Shown at most once. A retry that fails again must not replace the message
/// the user is already reading, and a loop here would be worse than the black
/// screen this exists to prevent.
bool _failureShown = false;

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework errors are printed but deliberately *not* escalated to the zone
  // handler. A single overflowing row must not take the whole app down.
  FlutterError.onError = FlutterError.presentError;

  try {
    final sharedPreferences = await SharedPreferences.getInstance();

    // Frees anybody left permanently locked out by an earlier build. Karde no
    // longer has a permanent lock at all, and someone still carrying the old
    // flag cannot reach their own cards until it goes.
    await SettingsRepository(sharedPreferences, const FlutterSecureStorage())
        .releaseAnyPermanentLock();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const IBankApp(),
      ),
    );
    _appStarted = true;
    _failureShown = false;
  } catch (error, stack) {
    // Reaching here means the vault was never opened, so nothing the user
    // saved can have been touched.
    debugPrint('Karde: startup failed — $error\n$stack');
    _showStartupFailure();
  }
}

void _showStartupFailure() {
  if (_appStarted || _failureShown) return;
  _failureShown = true;
  runApp(StartupFailureApp(onRetry: () {
    _failureShown = false;
    _bootstrap();
  }));
}
