import 'package:flutter/material.dart';

import '../../../core/storage/settings_repository.dart';
import '../../home/presentation/main_scaffold.dart';

/// The last step of onboarding, wherever onboarding happens to have come from.
///
/// Three routes reach the end — Phone Lock finishes at the lock screen, Karde
/// PIN and Both finish after recovery setup — and each used to enter the app on
/// its own. Adding a step to the end of onboarding then meant adding it three
/// times, and the third one is the one that gets forgotten.
///
/// **Backup setup is deliberately not here.** It was, briefly, on the reasoning
/// that a backup cannot usefully be arranged after the thing it protects is
/// gone. True, but it asked the wrong thing of the wrong moment: someone who has
/// not yet seen a single screen is being asked to invent a passphrase, write it
/// down, and go and choose a folder, for a copy of a vault that is still empty.
/// That is where people put the phone down and do not come back.
///
/// So the offer moved to where it means something — the home screen, once there
/// is something to lose, and Settings, whenever they go looking. Nothing is
/// protected any less: an empty vault has nothing to back up, and the prompt
/// appears the moment that stops being true.
Future<void> finishOnboarding(
  BuildContext context,
  SettingsRepository settings,
) async {
  await settings.setIsFirstLaunch(false);
  if (!context.mounted) return;
  // Nothing may remain underneath: pushReplacement swaps only the top route,
  // leaving the language picker below the app for the life of the install,
  // where one stray pop puts the user back at "Welcome to Karde" with their
  // vault apparently gone.
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainScaffold()),
    (route) => false,
  );
}
