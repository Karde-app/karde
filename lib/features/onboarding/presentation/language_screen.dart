import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import 'welcome_screen.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(languageProvider);

    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'ar', 'name': 'العربية'},
    ];

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                loc.welcomeTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.welcomeSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                loc.language,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = currentLanguage == lang['code'];

                    return InkWell(
                      onTap: () {
                        ref.read(languageProvider.notifier).updateLanguage(lang['code']!);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? KardeColors.champagneGold.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? KardeColors.champagneGold : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang['name']!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: isSelected ? KardeColors.champagneGold : Colors.white,
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: KardeColors.champagneGold),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // push, not pushReplacement: the lock screen needs something
                    // to go back to, so a user who picked the wrong language can
                    // return and change it.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
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
}
