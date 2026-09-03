import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/main_scaffold.dart';
import 'security_questions_setup_screen.dart';

class RecoverySetupScreen extends ConsumerStatefulWidget {
  const RecoverySetupScreen({super.key});

  @override
  ConsumerState<RecoverySetupScreen> createState() => _RecoverySetupScreenState();
}

class _RecoverySetupScreenState extends ConsumerState<RecoverySetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck || isSupported;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _canCheckBiometrics = false;
        _isLoading = false;
      });
    }
  }

  void _onOptionSelected(String option) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setRecoveryPreference(option);

    if (!mounted) return;

    if (option == 'questions') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SecurityQuestionsSetupScreen()),
      );
    } else if (option == 'none') {
      // Show warning dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: KardeColors.obsidian,
          title: Text(
            'Are you sure?',
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
              child: Text('Confirm', style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await settings.setIsFirstLaunch(false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    } else {
      // biometrics
      await settings.setIsFirstLaunch(false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
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
              const SizedBox(height: 48),
              if (_canCheckBiometrics)
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
