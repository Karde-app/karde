import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../cards/presentation/vault_screen.dart';
import 'dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../core/security/authentication_service.dart';
import '../../../core/security/system_interaction_guard.dart';
import '../../../core/security/window_security_service.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/security/vault_health_provider.dart';
import '../../../theme/theme.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isAppAuthenticated = false;
  bool _isAuthenticating = false;

  final _windowSecurity = WindowSecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FIX 3: Enable FLAG_SECURE on startup — prevents screenshots and Task Switcher leaks
    _windowSecurity.enableSecureMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authenticateStartup();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Timer? _lockTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      _lockTimer = null;

      // Both of these describe the phone, not Karde, and the user changes the
      // phone in Android's settings — with Karde sitting in the background.
      // Neither was ever re-checked, so the dashboard went on showing whatever
      // was true when Karde last started: a security warning already dealt with,
      // or worse, a clean bill of health after the screen lock had been turned
      // off. Coming back to Karde is the only moment it can find out.
      ref.invalidate(vaultHealthProvider);
      ref.invalidate(biometricChangeNoticeProvider);

      if (!_isAppAuthenticated && !_isAuthenticating && mounted) {
        _authenticateStartup();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // System UI that Karde raised itself — the vault's BiometricPrompt, or the
      // backup file picker — drives this activity inactive, which is
      // indistinguishable from the user leaving the app. Starting the auto-lock
      // timer then means a slow authentication locks the app behind the prompt
      // the user is currently answering, and they get a second prompt the moment
      // the first succeeds. Don't arm the timer while our own system UI is up.
      if (SystemInteractionGuard.isActive) return;

      // FIX 5: Read grace period from user's setting instead of hardcoded 15s
      if (_isAppAuthenticated && _lockTimer == null) {
        final gracePeriodSeconds = ref.read(autoHideDurationProvider);
        _lockTimer = Timer(Duration(seconds: gracePeriodSeconds), () {
          if (mounted) {
            setState(() {
              _isAppAuthenticated = false;
            });
          }
        });
      }
    }
  }

  Future<void> _authenticateStartup() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final settings = ref.read(settingsRepositoryProvider);
    final authService = AuthenticationService();
    final result = await authService.authenticateAppStartup(context, settings);

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (result) {
      setState(() => _isAppAuthenticated = true);
    }
    // FIX 4: Do NOT call SystemNavigator.pop(). Stay on lock screen so user can retry.
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // FIX 1: Screens list is inside build() so it rebuilds on locale change (fixes language switching)
    final screens = [
      const DashboardScreen(),
      const VaultScreen(),
      const SettingsScreen(),
    ];

    if (!_isAppAuthenticated) {
      // FIX 4: Proper lock screen with "Try Again" instead of closing the app
      return Scaffold(
        backgroundColor: KardeColors.obsidian,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KardeColors.champagneGold.withOpacity(0.1),
                    border: Border.all(color: KardeColors.champagneGold.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.lock_outline, color: KardeColors.champagneGold, size: 36),
                ),
                const SizedBox(height: 24),
                Text(
                  loc.kardeIsLocked,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.authenticateToAccess,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 220,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticateStartup,
                    icon: _isAuthenticating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.fingerprint),
                    label: Text(_isAuthenticating ? loc.authenticating : loc.unlockKarde),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(
                    loc.exitApp,
                    style: const TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: loc.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card),
            label: loc.vaultTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: loc.settingsTab,
          ),
        ],
      ),
    );
  }
}
