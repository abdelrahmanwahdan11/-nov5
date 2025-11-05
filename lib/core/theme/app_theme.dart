import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return _baseTheme(Brightness.light, scheme);
  }

  static ThemeData dark(Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return _baseTheme(Brightness.dark, scheme);
  }

  static ThemeData _baseTheme(Brightness brightness, ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold),
    );
    final arabicTextTheme = GoogleFonts.notoSansArabicTextTheme(textTheme);

    final theme = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? const Color(0xFF0E1114) : const Color(0xFFF7F8FA),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: scheme.primary,
        secondaryColor: scheme.secondary,
        brightness: brightness,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );

    return theme.copyWith(
      textTheme: brightness == Brightness.dark ? arabicTextTheme : textTheme,
    );
  }
}
