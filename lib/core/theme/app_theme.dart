import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  static const _lightBackground = Color(0xFFF7F8FA);
  static const _darkBackground = Color(0xFF0E1114);

  static ThemeData light(Color primary, Locale locale) {
    final base = ThemeData.light(useMaterial3: true);
    return _baseTheme(base, primary, locale).copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primary,
        brightness: Brightness.light,
        surface: Colors.white,
        background: _lightBackground,
      ),
      scaffoldBackgroundColor: _lightBackground,
    );
  }

  static ThemeData dark(Color primary, Locale locale) {
    final base = ThemeData.dark(useMaterial3: true);
    return _baseTheme(base, primary, locale).copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primary,
        brightness: Brightness.dark,
        surface: const Color(0xFF161A1F),
        background: _darkBackground,
      ),
      scaffoldBackgroundColor: _darkBackground,
    );
  }

  static ThemeData _baseTheme(ThemeData base, Color primary, Locale locale) {
    final isArabic = locale.languageCode.toLowerCase() == 'ar';
    final textTheme = isArabic
        ? GoogleFonts.notoSansArabicTextTheme(base.textTheme)
        : GoogleFonts.interTextTheme(base.textTheme);

    final fallback = isArabic
        ? const ['Noto Sans Arabic', 'Cairo', 'Inter']
        : const ['Inter', 'Noto Sans Arabic'];

    final localizedTextTheme = textTheme.apply(
      bodyColor: base.colorScheme.onBackground,
      displayColor: base.colorScheme.onBackground,
      fontFamilyFallback: fallback,
    );

    return base.copyWith(
      textTheme: localizedTextTheme,
      primaryColor: primary,
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: base.colorScheme.onBackground,
        titleTextStyle: localizedTextTheme.titleLarge,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static LinearGradient headerGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [Color(0xFF0F241C), Color(0xFF1C1414), Color(0xFF0E1114)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFEAF7F1), Color(0xFFF7EAEA), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
