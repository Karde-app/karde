import 'package:flutter/material.dart';

class KardeColors {
  // Dark Palette
  static const obsidian = Color(0xFF0A0C11);
  static const graphite = Color(0xFF161A23);
  static const warmIvory = Color(0xFFF4F1EA);
  static const slate = Color(0xFF9AA1B0);
  static const graphiteText = Color(0xFF5C6472);

  // Light Palette
  static const lightScaffold = Color(0xFFF4F5F7); // Premium off-white
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF181B23); // Deep slate grey, softer than pure black
  static const lightSlate = Color(0xFF6B7280);

  // Brand Colors (Shared)
  static const champagneGold = Color(0xFFC9A961);
  static const signalTeal = Color(0xFF2BD1C4);
  static const ember = Color(0xFFE5555C);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(fontFamily: 'Inter');
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: KardeColors.lightScaffold,
      primaryColor: KardeColors.champagneGold,
      colorScheme: const ColorScheme.light(
        primary: KardeColors.champagneGold,
        secondary: KardeColors.signalTeal,
        surface: KardeColors.lightSurface,
        error: KardeColors.ember,
        onPrimary: KardeColors.lightText,
        onSurface: KardeColors.lightText,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.lightText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.lightText, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: KardeColors.lightText, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'Inter', color: KardeColors.lightText, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KardeColors.lightScaffold,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: KardeColors.lightText),
        titleTextStyle: TextStyle(fontFamily: 'Outfit', 
          color: KardeColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: KardeColors.lightSurface,
        selectedItemColor: KardeColors.champagneGold,
        unselectedItemColor: KardeColors.lightSlate,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KardeColors.lightSurface,
        indicatorColor: KardeColors.champagneGold.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: 'Inter', color: KardeColors.champagneGold, fontSize: 12, fontWeight: FontWeight.w500);
          }
          return TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KardeColors.champagneGold);
          }
          return const IconThemeData(color: KardeColors.lightSlate);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KardeColors.champagneGold,
          foregroundColor: KardeColors.obsidian,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: KardeColors.champagneGold.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KardeColors.champagneGold,
          textStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KardeColors.lightSurface,
        labelStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate, fontSize: 14),
        hintStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.lightSlate.withOpacity(0.7), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KardeColors.champagneGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KardeColors.ember, width: 1.5),
        ),
        errorStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.ember),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.05),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: KardeColors.champagneGold,
        textColor: KardeColors.lightText,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme.apply(fontFamily: 'Inter');
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KardeColors.obsidian,
      primaryColor: KardeColors.champagneGold,
      colorScheme: const ColorScheme.dark(
        primary: KardeColors.champagneGold,
        secondary: KardeColors.signalTeal,
        surface: KardeColors.graphite,
        error: KardeColors.ember,
        onPrimary: KardeColors.obsidian,
        onSurface: KardeColors.warmIvory,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Outfit', color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.warmIvory, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'Inter', color: KardeColors.slate, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: KardeColors.warmIvory, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.slate, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'Inter', color: KardeColors.warmIvory, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: KardeColors.slate, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Inter', color: KardeColors.slate, fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KardeColors.obsidian,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: KardeColors.warmIvory),
        titleTextStyle: TextStyle(fontFamily: 'Outfit', 
          color: KardeColors.warmIvory,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: KardeColors.obsidian,
        selectedItemColor: KardeColors.champagneGold,
        unselectedItemColor: KardeColors.graphiteText,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KardeColors.obsidian,
        indicatorColor: KardeColors.champagneGold.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: 'Inter', color: KardeColors.champagneGold, fontSize: 12, fontWeight: FontWeight.w500);
          }
          return TextStyle(fontFamily: 'Inter', color: KardeColors.graphiteText, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KardeColors.champagneGold);
          }
          return const IconThemeData(color: KardeColors.graphiteText);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KardeColors.champagneGold,
          foregroundColor: KardeColors.obsidian,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: KardeColors.champagneGold.withOpacity(0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KardeColors.champagneGold,
          textStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KardeColors.graphite,
        labelStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.slate, fontSize: 14),
        hintStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.graphiteText, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KardeColors.champagneGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KardeColors.ember, width: 1.5),
        ),
        errorStyle: TextStyle(fontFamily: 'Inter', color: KardeColors.ember),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: KardeColors.champagneGold,
        textColor: KardeColors.warmIvory,
      ),
    );
  }
}
