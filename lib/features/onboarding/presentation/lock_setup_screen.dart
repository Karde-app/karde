import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import 'pin_setup_screen.dart';
import 'recovery_setup_screen.dart';

class LockSetupScreen extends ConsumerStatefulWidget {
  const LockSetupScreen({super.key});

  @override
  ConsumerState<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends ConsumerState<LockSetupScreen>
    with WidgetsBindingObserver {
  String _selectedLock = 'phone'; // 'phone', 'dedicated', 'both'

  /// Null until checked. False means the phone itself has no screen lock, so the
  /// Keystore will not hold the vault key and nothing can be stored yet.
  bool? _deviceLockPresent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDeviceLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The warning tells the user to go and set a screen lock. Re-check when they
    // come back, so the warning clears itself instead of making them guess
    // whether Karde noticed.
    if (state == AppLifecycleState.resumed) _checkDeviceLock();
  }

  Future<void> _checkDeviceLock() async {
    final available = await EncryptionService().canUseVault();
    if (!mounted) return;
    setState(() {
      _deviceLockPresent = available;
      // "Phone Lock" cannot work without one, and choosing it would leave the
      // user with no Karde PIN either — no gate at all. Steer them to a PIN.
      if (!available && _selectedLock == 'phone') _selectedLock = 'dedicated';
    });
  }

  /// Explains, before any choice is made, that these options govern how Karde
  /// locks itself — and that without a device screen lock the vault cannot store
  /// anything at all, whichever option is picked.
  ///
  /// Onboarding previously said nothing, so a user with no screen lock completed
  /// setup, reached the home screen, and only hit the wall at "Add a card".
  Widget _buildNoDeviceLockWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KardeColors.ember.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KardeColors.ember.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: KardeColors.ember, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "This phone has no screen lock.\n\n"
              "Karde keeps your encryption key in the phone's security chip, and "
              "that chip will not hold a key unless the phone itself is locked. "
              "Until you set a PIN, pattern, password or fingerprint in your "
              "phone's settings, Karde cannot save or open any items.\n\n"
              "You can finish setting up now, then add a screen lock and come "
              "back.",
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Onboarding had no way back from here, so a mis-tapped language
              // could only be undone by reinstalling. Shown only when there is
              // in fact something behind this screen.
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Back to language',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                loc.setupLockTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.setupLockSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  children: [
                    if (_deviceLockPresent == false) _buildNoDeviceLockWarning(),
                    _buildLockOption(
                      loc.phoneLock,
                      loc.phoneLockDesc,
                      Icons.fingerprint,
                      'phone',
                      // Without a device lock this option is not merely weaker,
                      // it is inoperable: there is no phone lock to defer to.
                      enabled: _deviceLockPresent != false,
                    ),
                    const SizedBox(height: 16),
                    _buildLockOption(
                      loc.kardePin,
                      loc.kardePinDesc,
                      Icons.dialpad,
                      'dedicated',
                    ),
                    const SizedBox(height: 16),
                    _buildLockOption(
                      loc.bothLocks,
                      loc.bothLocksDesc,
                      Icons.security,
                      'both',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final settings = ref.read(settingsRepositoryProvider);
                    await settings.setLockType(_selectedLock);
                    
                    if (_selectedLock == 'phone') {
                      await settings.setRequirePinLock(false);
                      await settings.setBiometricUnlock(true);
                    } else if (_selectedLock == 'dedicated') {
                      await settings.setRequirePinLock(true);
                      await settings.setBiometricUnlock(false);
                    } else {
                      await settings.setRequirePinLock(true);
                      await settings.setBiometricUnlock(true);
                    }
                    
                    if (!mounted) return;

                    if (_selectedLock == 'dedicated' || _selectedLock == 'both') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                      );
                    } else {
                      // "Phone Lock" used to end onboarding right here, skipping
                      // PIN setup, recovery setup and security questions in one
                      // step — so the user reached the app with no recovery
                      // configured at all, and no screen ever offered to set one
                      // up afterwards.
                      //
                      // They still get no Karde PIN, which is the whole point of
                      // the option. What they now also get is the recovery screen,
                      // so a way back in exists before it is needed rather than
                      // being discovered to be absent afterwards. That screen
                      // finishes onboarding on whichever path the user takes.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RecoverySetupScreen()),
                      );
                    }
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
                    loc.continueBtn,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockOption(
    String title,
    String description,
    IconData icon,
    String value, {
    bool enabled = true,
  }) {
    final isSelected = _selectedLock == value;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedLock = value;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? KardeColors.champagneGold.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? KardeColors.champagneGold : Colors.transparent,
              width: 1.5,
            ),
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? KardeColors.champagneGold : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? KardeColors.obsidian : Colors.white,
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
                      fontFamily: 'Inter',
                      color: isSelected ? KardeColors.champagneGold : Colors.white,
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
