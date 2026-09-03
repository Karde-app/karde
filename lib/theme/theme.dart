import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KardeColors {
  static const obsidian = Color(0xFF0A0C11);
  static const graphite = Color(0xFF161A23);
  static const champagneGold = Color(0xFFC9A961);
  static const signalTeal = Color(0xFF2BD1C4);
  static const ember = Color(0xFFE5555C);
  static const warmIvory = Color(0xFFF4F1EA);
  static const slate = Color(0xFF9AA1B0);
  static const graphiteText = Color(0xFF5C6472);
}

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    // Karde is inherently a dark, obsidian vault. We apply the same core colors 
    // to both for now to ensure the brand identity is maintained.
    
    final baseTextTheme = GoogleFonts.interTextTheme();
    
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
        displayLarge: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        displayMedium: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        displaySmall: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: KardeColors.warmIvory, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: KardeColors.warmIvory, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(color: KardeColors.slate, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: KardeColors.warmIvory, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(color: KardeColors.slate, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(color: KardeColors.warmIvory, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: KardeColors.slate, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(color: KardeColors.slate, fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KardeColors.obsidian,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: KardeColors.warmIvory),
        titleTextStyle: GoogleFonts.outfit(
          color: KardeColors.warmIvory,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: KardeColors.obsidian,
        selectedItemColor: KardeColors.champagneGold,
        unselectedItemColor: KardeColors.graphiteText,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KardeColors.obsidian,
        indicatorColor: KardeColors.champagneGold.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(color: KardeColors.champagneGold, fontSize: 12, fontWeight: FontWeight.w500);
          }
          return GoogleFonts.inter(color: KardeColors.graphiteText, fontSize: 12);
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
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: KardeColors.champagneGold.withOpacity(0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KardeColors.champagneGold,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KardeColors.graphite,
        labelStyle: GoogleFonts.inter(color: KardeColors.slate, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: KardeColors.graphiteText, fontSize: 14),
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
        errorStyle: GoogleFonts.inter(color: KardeColors.ember),
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
