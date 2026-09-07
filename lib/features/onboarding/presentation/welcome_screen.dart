import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import 'lock_setup_screen.dart';

/// The first thing a new user reads, and the point at which they agree to how
/// Karde handles their information.
///
/// **This screen does not grant any Android permission, and nothing can.** The
/// user asked for the pattern where accepting an agreement lets the install
/// proceed with everything allowed. That has not existed on Android since
/// version 6: permissions like notifications and the camera are granted by the
/// system, one at a time, only when the app asks, and only through the system's
/// own dialog. An "I agree" in here is invisible to the operating system.
///
/// What it does do is the half that is real and worth having: it puts what Karde
/// is and what it promises in front of somebody before they hand it a passport,
/// and it makes the privacy policy reachable at the moment that matters rather
/// than buried in Settings under About.
///
/// It deliberately does **not** list the permissions Karde may later ask for. A
/// list here would be read as a menu of things being taken, and would arrive
/// long before any of them make sense. Each request is explained where it
/// happens instead — see the notification permission, which is asked the first
/// time there is genuinely a reminder to give.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: KardeColors.champagneGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: KardeColors.champagneGold, size: 36),
              ),
              const SizedBox(height: 28),
              Text(
                loc.welcomeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.onboardingWelcomeBody,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(loc.onboardingReadPolicy),
                style: TextButton.styleFrom(
                  foregroundColor: KardeColors.champagneGold,
                  padding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.onboardingAgreeNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Recorded against the version, so a future policy that
                    // materially changes what Karde does can ask again rather
                    // than assume an answer given to a different document.
                    ref
                        .read(settingsRepositoryProvider)
                        .setAcceptedPolicyVersion(AppInfo.version);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LockSetupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KardeColors.champagneGold,
                    foregroundColor: KardeColors.obsidian,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.onboardingAgreeContinue,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
