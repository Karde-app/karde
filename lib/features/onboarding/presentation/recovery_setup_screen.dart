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

  /// True for a user who chose "Phone Lock" and therefore has no Karde PIN.
  ///
  /// They reach this screen too now, but what these options do for them is
  /// different enough that saying nothing would be misleading — see
  /// [_buildNoPinNote].
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

    final storedPin = await ref.read(settingsRepositoryProvider).getHashedPin();

    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheck;
      _hasNoKardePin = storedPin == null || storedPin.isEmpty;
      _isLoading = false;
    });
  }

  /// Explains what recovery does, and does not, mean without a Karde PIN.
  ///
  /// Two honest points, because getting either wrong would leave the user with a
  /// false sense of safety.
  ///
  /// These options unlock a PIN reset. Somebody with no Karde PIN has nothing to
  /// reset today, so what they are really doing is arranging the way back in
  /// against the day they turn App PIN Lock on in Settings — a real possibility,
  /// and much easier to arrange now than after they are locked out.
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
        await settings.setIsFirstLaunch(false);
        if (!mounted) return;
        // Onboarding ends here, so nothing may remain underneath. pushReplacement
        // swaps only the top route, which left the language, lock-setup and PIN
        // screens sitting below MainScaffold for the life of the install — one
        // stray pop and the user was back at "Welcome to Karde" with their vault
        // intact but apparently gone. Clear the whole stack, as the PIN-reset path
        // at pin_setup_screen.dart already does.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      }
    } else {
      // biometrics
      await settings.setIsFirstLaunch(false);
      if (!mounted) return;
      // Onboarding ends here, so nothing may remain underneath. pushReplacement
      // swaps only the top route, which left the language, lock-setup and PIN
      // screens sitting below MainScaffold for the life of the install — one
      // stray pop and the user was back at "Welcome to Karde" with their vault
      // intact but apparently gone. Clear the whole stack, as the PIN-reset path
      // at pin_setup_screen.dart already does.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
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
          child: ListView(
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
              const SizedBox(height: 32),
              if (_hasNoKardePin) _buildNoPinNote(),
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
