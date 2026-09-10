import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_info.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// Shown when Karde could not finish starting.
///
/// The point of this screen is that a startup failure is *visible*. Karde
/// carries no crash reporting — that would mean a network permission, and the
/// whole promise of the app is that it has none — so a failure nobody can see
/// is a failure nobody will ever report. Before this existed, a throw during
/// startup left a black screen and no way to tell anyone.
///
/// Two deliberate choices:
///
/// - It follows the **phone's** language rather than the one chosen in Karde.
///   The stored preference lives behind the very thing that just failed, so
///   there is nothing to read it from.
/// - It says the saved items are safe. A person whose vault app refuses to
///   open will assume the worst, and the reassurance is true: a failure here
///   happens before anything is written.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.onRetry});

  /// Attempts startup again. Deliberately not a "restart the app" button —
  /// an app cannot restart itself on Android, and offering something that
  /// does nothing is worse than offering nothing.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      debugShowCheckedModeBanner: false,
      home: _StartupFailureScreen(onRetry: onRetry),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  loc.startupFailedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.startupFailedBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(loc.startupFailedRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
