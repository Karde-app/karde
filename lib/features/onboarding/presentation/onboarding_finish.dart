import 'package:flutter/material.dart';

import '../../../core/storage/settings_repository.dart';
import '../../backup/presentation/backup_setup_screen.dart';
import '../../home/presentation/main_scaffold.dart';

/// The last step of onboarding, wherever onboarding happens to have come from.
///
/// Three routes reach the end — Phone Lock finishes at the lock screen, Karde
/// PIN and Both finish after recovery setup — and each used to enter the app on
/// its own. Adding a step to the end of onboarding then meant adding it three
/// times, and the third one is the one that gets forgotten.
///
/// Backup setup is that step. It is asked for last because it is the only part
/// of setup that cannot usefully be added *after* the thing it protects is gone:
/// a screen lock or a PIN can be changed whenever the user likes, but a backup
/// arranged after the phone is lost protects nothing.
Future<void> finishOnboarding(
  BuildContext context,
  SettingsRepository settings,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BackupSetupScreen(
        onDone: () async {
          await settings.setIsFirstLaunch(false);
          if (!context.mounted) return;
          // Nothing may remain underneath: pushReplacement swaps only the top
          // route, leaving the language picker below the app for the life of the
          // install, where one stray pop puts the user back at "Welcome to
          // Karde" with their vault apparently gone.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScaffold()),
            (route) => false,
          );
        },
      ),
    ),
  );
}
