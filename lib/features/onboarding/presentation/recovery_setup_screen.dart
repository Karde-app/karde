import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import 'onboarding_finish.dart';
import 'security_questions_setup_screen.dart';

class RecoverySetupScreen extends ConsumerStatefulWidget {
  /// True when reached from Settings rather than from onboarding.
  ///
  /// Onboarding ends on this screen, so there it clears the stack and enters the
  /// app. From Settings there is no onboarding to end: the user came here after
  /// creating a Karde PIN, and finishing has to hand them back to the Settings
  /// screen they started from. Entering a fresh MainScaffold instead would drop
  /// them on the dashboard and make Karde ask them to authenticate all over
  /// again.
  final bool fromSettings;

  const RecoverySetupScreen({super.key, this.fromSettings = false});

  @override
  ConsumerState<RecoverySetupScreen> createState() => _RecoverySetupScreenState();
}

class _RecoverySetupScreenState extends ConsumerState<RecoverySetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isLoading = true;

  /// Whether the user has no Karde PIN.
  ///
  /// Every route into this screen now creates a PIN first — onboarding arrives
  /// via PIN setup, and Settings arrives straight after a PIN is created — so in
  /// practice this stays false. It is kept as a guard rather than an assumption
  /// because the screen is pushable from anywhere, and getting here without a PIN
  /// would otherwise offer the phone's own lock as the way to recover from the
  /// phone's own lock, and offer to reset a PIN that does not exist. Neither is
  /// something to show a user by accident.
  ///
  /// Read from [SettingsRepository.hasKardePin]. Never from the "App PIN lock"
  /// setting, which reports an intention rather than a fact.
  bool _hasNoKardePin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool canCheck = false;
    try {
      canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      canCheck = false;
    }

    final hasPin = await ref.read(settingsRepositoryProvider).hasKardePin();

    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheck;
      _hasNoKardePin = !hasPin;
      _isLoading = false;
    });
  }

  /// Explains what recovery does, and does not, mean without a Karde PIN.
  ///
  /// The safety net for [_hasNoKardePin]; see that field for when it can show.
  /// Two honest points, because getting either wrong would leave the user with a
  /// false sense of safety.
  ///
  /// These options unlock a PIN reset. Somebody with no Karde PIN has nothing to
  /// reset today, so what they are really doing is arranging the way back in
  /// against the day they turn App PIN Lock on in Settings.
  ///
  /// And none of them protect the vault contents. The encryption key lives in the
  /// phone's secure hardware, tied to the phone's own screen lock; if that lock is
  /// removed or reset, Android destroys the key and no security question can bring
  /// it back. The only thing that survives that is an encrypted backup.
  Widget _buildNoPinNote() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: KardeColors.champagneGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.recoveryNoPinNote,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onOptionSelected(String option) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setRecoveryPreference(option);

    if (!mounted) return;

    if (option == 'questions') {
      // From Settings the questions screen returns here, and this screen has
      // nothing left to say — send the user back where they came from rather
      // than leaving them staring at the choice they just made.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SecurityQuestionsSetupScreen(
            isChanging: widget.fromSettings,
          ),
        ),
      );
      if (!mounted) return;
      if (widget.fromSettings && await settings.hasSecurityQuestions()) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } else if (option == 'none') {
      // Show warning dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: KardeColors.obsidian,
          title: Text(
            AppLocalizations.of(context)!.areYouSure,
            style: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
          ),
          content: Text(
            AppLocalizations.of(context)!.noRecoveryDesc,
            style: const TextStyle(color: Colors.white70, fontFamily: 'Inter'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        if (widget.fromSettings) {
          Navigator.pop(context);
          return;
        }
        await finishOnboarding(context, settings);
      }
    } else {
      // biometrics
      if (widget.fromSettings) {
        Navigator.pop(context);
        return;
      }
      await finishOnboarding(context, settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: KardeColors.graphite,
        body: Center(child: CircularProgressIndicator(color: KardeColors.champagneGold)),
      );
    }

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              // Onboarding had no way back from here, so a lock type chosen by
              // mistake could not be undone. Shown only when there is in fact
              // something behind this screen.
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: loc.goBack,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                loc.recoverySetupTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.recoverySetupSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              if (_hasNoKardePin) _buildNoPinNote(),
              if (_canCheckBiometrics && !_hasNoKardePin)
                _buildOptionCard(
                  title: loc.biometricRecovery,
                  description: loc.biometricRecoveryDesc,
                  icon: Icons.fingerprint,
                  onTap: () => _onOptionSelected('biometrics'),
                ),
              _buildOptionCard(
                title: loc.securityQuestions,
                description: loc.securityQuestionsDesc,
                icon: Icons.security,
                onTap: () => _onOptionSelected('questions'),
              ),
              _buildOptionCard(
                title: loc.noRecovery,
                description: loc.noRecoveryDesc,
                icon: Icons.warning_amber_rounded,
                isWarning: true,
                onTap: () => _onOptionSelected('none'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KardeColors.obsidian,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWarning ? Colors.redAccent.withOpacity(0.3) : Colors.white12,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isWarning ? Colors.redAccent : KardeColors.champagneGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isWarning ? Colors.redAccent : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
