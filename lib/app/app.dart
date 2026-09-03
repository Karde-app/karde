import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../features/home/presentation/main_scaffold.dart';
import '../features/onboarding/presentation/language_screen.dart';
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
      title: 'iBank',
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
        Locale('am'),
      ],
      home: isFirstLaunch ? const LanguageSelectionScreen() : const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}
