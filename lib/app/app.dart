import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../features/home/presentation/main_scaffold.dart';
import '../features/onboarding/presentation/language_screen.dart';
import '../core/security/window_security_service.dart';
import '../core/app_info.dart';
import '../theme/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/settings_repository.dart';

class IBankApp extends ConsumerWidget {
  const IBankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(languageProvider);
    final isFirstLaunch = ref.read(settingsRepositoryProvider).getIsFirstLaunch();

    return MaterialApp(
      // The task switcher label. The project is still called ibank internally;
      // the app has been Karde since well before this.
      title: AppInfo.name,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      home: isFirstLaunch ? const LanguageSelectionScreen() : const MainScaffold(),
      debugShowCheckedModeBanner: false,
      // Loudly mark builds where FLAG_SECURE has been disabled for development,
      // so a capture-enabled APK can never be mistaken for a shippable one.
      builder: WindowSecurityService.screenshotsAllowed
          ? (context, child) => Banner(
              message: 'SCREENSHOTS ON',
              location: BannerLocation.topEnd,
              color: const Color(0xFFD32F2F),
              child: child ?? const SizedBox.shrink(),
            )
          : null,
    );
  }
}
