import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/main_scaffold.dart';
import 'pin_setup_screen.dart';

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
    final loc = AppLocalizations.of(context)!;
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
          Expanded(
            child: Text(
              loc.noScreenLockWarning,
              style: const TextStyle(
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

  /// Says, where the choice is actually being made, that a Karde PIN can still
  /// be added later.
  ///
  /// Phone Lock now finishes onboarding on its own, so nothing else in the flow
  /// mentions the Karde PIN again. Without this the option reads as a decision
  /// that cannot be revisited, and a user who wanted both ends up picking "Both"
  /// out of caution rather than because they want a second PIN today.
  Widget _buildPinLaterNote() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: KardeColors.champagneGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.phoneLockPinHint,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.45,
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
                    tooltip: loc.backToLanguage,
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
                    if (_selectedLock == 'phone') _buildPinLaterNote(),
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
                    
                    // Written through the notifiers, not straight to the
                    // repository. Each notifier reads its value from storage
                    // once, in its constructor, and holds it as state — so a
                    // direct write updates storage and leaves the copy in memory
                    // saying something else.
                    //
                    // Seen on the device: after erasing the vault and choosing
                    // Phone Lock again, Settings showed "App PIN lock" on and
                    // "Biometric unlock" off — the defaults the notifiers had
                    // rebuilt from the wiped preferences, and the exact opposite
                    // of what had just been chosen. Karde itself behaved
                    // correctly, because authentication reads storage, but
                    // Settings described a vault the user did not have.
                    final requirePin = ref.read(requirePinLockProvider.notifier);
                    final biometric = ref.read(biometricUnlockProvider.notifier);
                    if (_selectedLock == 'phone') {
                      await requirePin.updateRequirePinLock(false);
                      await biometric.updateBiometricUnlock(true);
                    } else if (_selectedLock == 'dedicated') {
                      await requirePin.updateRequirePinLock(true);
                      await biometric.updateBiometricUnlock(false);
                    } else {
                      await requirePin.updateRequirePinLock(true);
                      await biometric.updateBiometricUnlock(true);
                    }
                    
                    if (!mounted) return;

                    if (_selectedLock == 'dedicated' || _selectedLock == 'both') {
                      // Both of these create a Karde PIN, and the PIN screen
                      // hands on to recovery setup afterwards — recovery there
                      // means something, because there is a PIN to reset.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                      );
                    } else {
                      // "Phone Lock" finishes onboarding here.
                      //
                      // It briefly went to the recovery screen instead. The
                      // reasoning was that this user would otherwise reach the app
                      // with no recovery configured and never be offered any. But
                      // every option on that screen recovers a Karde PIN, and this
                      // user has none: the questions would reset a PIN that does
                      // not exist, and offering the phone's own lock as the way
                      // back from the phone's own lock is circular. Karde does not
                      // hold the device passcode or the fingerprints, so if those
                      // are lost the way back is through Android, not through
                      // anything Karde could have set up in advance.
                      //
                      // So the screen was premature rather than helpful. The offer
                      // is made at the moment it starts to mean something instead:
                      // Settings can add a Karde PIN at any time, and that path
                      // goes on to recovery setup. _buildPinLaterNote says so here
                      // so the possibility is not a secret.
                      await settings.setIsFirstLaunch(false);
                      if (!context.mounted) return;
                      // Nothing may remain underneath: pushReplacement swaps only
                      // the top route, leaving the language picker below the app
                      // for the life of the install, where one stray pop puts the
                      // user back at "Welcome to Karde" with their vault
                      // apparently gone.
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScaffold()),
                        (route) => false,
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
