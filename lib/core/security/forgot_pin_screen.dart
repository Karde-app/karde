import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../l10n/app_localizations.dart';
import '../storage/settings_repository.dart';
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
        localizedReason: 'Scan your fingerprint (or face) to reset your PIN',
        biometricOnly: true,
      );

      if (authenticated && mounted) {
        // Unlock
        final settings = ref.read(settingsRepositoryProvider);
        await settings.setFailedAttempts(0);
        await settings.setIsPermanentlyLocked(false);
        await settings.setLockoutUntil(null);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PinSetupScreen(isResettingPin: true),
            ),
          );
        }
      }
    } catch (e) {
      // Biometric error, fallback
    }
  }

  void _wipeData(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KardeColors.obsidian,
        title: Text(
          loc.wipeDataBtn,
          style: const TextStyle(color: Colors.redAccent, fontFamily: 'Outfit'),
        ),
        content: Text(
          loc.wipeDataWarning,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.wipe, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.wipeAllData();

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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
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
