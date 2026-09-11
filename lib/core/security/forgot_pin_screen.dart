import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/karde_confirm_dialog.dart';
import '../storage/settings_repository.dart';
import '../storage/vault_reset.dart';
import '../../theme/theme.dart';
import '../../features/onboarding/presentation/pin_setup_screen.dart';
import '../../features/onboarding/presentation/language_screen.dart';
import 'security_questions_verification_screen.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String? _recoveryPreference;
  bool _isLoading = true;

  /// FIX 4-1: surfaces biometric recovery failures, which were previously
  /// swallowed by an empty catch.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final settings = ref.read(settingsRepositoryProvider);
    final pref = await settings.getRecoveryPreference();
    setState(() {
      _recoveryPreference = pref ?? 'none';
      _isLoading = false;
    });
  }

  Future<void> _useBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: AppLocalizations.of(context)!.resetPinBiometricReason,
        biometricOnly: true,
      );

      if (authenticated && mounted) {
        // Unlock
        final settings = ref.read(settingsRepositoryProvider);
        await settings.setFailedAttempts(0);
        await settings.setLockoutUntil(null);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PinSetupScreen(isResettingPin: true),
            ),
          );
        }
      } else if (mounted) {
        // FIX 4-1: authentication was declined or cancelled. Previously nothing
        // happened at all and the user was left staring at an unchanged screen
        // with no idea whether it had failed or simply not registered.
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.verificationNotCompleted;
        });
      }
    } catch (e) {
      // FIX 4-1: this catch was empty. A biometric hardware error, a lockout
      // after too many failures, or a corrupted enrolment all left the user
      // stuck on this screen with no feedback and no suggested way forward.
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.biometricVerificationUnavailable;
        });
      }
    }
  }

  void _wipeData(AppLocalizations loc) async {
    // FIX 5-1 / 5-4: shared dialog, so this no longer hardcodes dark-theme
    // colours that rendered white-on-white in light mode.
    final confirm = await KardeConfirmDialog.show(
      context,
      title: loc.wipeDataBtn,
      message: loc.wipeDataWarning,
      confirmLabel: loc.wipe,
      cancelLabel: loc.cancel,
    );

    if (confirm && mounted) {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.wipeAllData();
      // Same reason as the Settings path: deleting the database does not empty
      // the providers that cached it.
      resetAllVaultState(ref);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
          (route) => false,
        );
      }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: loc.goBack,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // This is the way back in for somebody who has forgotten their PIN, and
      // it had fixed spacers and no scroll view: on a short screen the options
      // would have fallen below the fold with no way to reach them. The
      // ConstrainedBox keeps the Spacer working where there is room, and it
      // scrolls where there is not.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                loc.resetPinTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.resetPinSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              
              if (_recoveryPreference == 'biometrics')
                _buildOptionCard(
                  title: loc.biometricRecovery,
                  description: loc.biometricRecoveryDesc,
                  icon: Icons.fingerprint,
                  onTap: _useBiometrics,
                ),
                
              if (_recoveryPreference == 'questions')
                _buildOptionCard(
                  title: loc.securityQuestions,
                  description: loc.securityQuestionsDesc,
                  icon: Icons.security,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityQuestionsVerificationScreen(),
                      ),
                    );
                  },
                ),
                
              if (_recoveryPreference == 'none')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.noRecoveryDesc,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // FIX 4-1: tell the user when biometric recovery did not work.
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KardeColors.ember.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KardeColors.ember.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: KardeColors.ember, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: KardeColors.ember,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _wipeData(loc),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: Text(
                    loc.wipeDataBtn,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
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
              color: Colors.white12,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: KardeColors.champagneGold,
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
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
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
