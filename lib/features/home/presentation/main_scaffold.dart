import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/presentation/vault_screen.dart';
import 'dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../core/security/authentication_service.dart';
import '../../../core/storage/settings_repository.dart';
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const VaultScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  static const Duration _gracePeriod = Duration(seconds: 15);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      _lockTimer = null;
      
      if (!_isAppAuthenticated && !_isAuthenticating && mounted) {
        _authenticateStartup();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Start grace period timer if not already running
      if (_isAppAuthenticated && _lockTimer == null) {
        _lockTimer = Timer(_gracePeriod, () {
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
    _isAuthenticating = true;
    
    final settings = ref.read(settingsRepositoryProvider);
    final authService = AuthenticationService();
    final result = await authService.authenticateAppStartup(context, settings);
    
    _isAuthenticating = false;
    
    if (result) {
      if (mounted) {
        setState(() => _isAppAuthenticated = true);
      }
    } else {
      SystemNavigator.pop(); // Close app if auth fails or is cancelled
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAppAuthenticated) {
      return const Scaffold(backgroundColor: KardeColors.graphite);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
