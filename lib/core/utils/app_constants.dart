import 'package:flutter/material.dart';

class AppConstants {
  static const String prefThemeMode = 'theme_mode';
  static const String prefPrimaryColor = 'primary_color';
  static const String prefLocale = 'locale';
  static const String prefSeenOnboarding = 'seen_onboarding';
  static const String prefIsGuest = 'is_guest';
  static const String prefIsAuthenticated = 'is_authenticated';
  static const String prefBudgets = 'budgets';
  static const String prefSearchHistory = 'search_history';
  static const String prefLastCategoryFilter = 'last_category_filter';
  static const String prefLastTagFilters = 'last_tag_filters';

  static const List<Color> primarySwatches = [
    Color(0xFF2BAA7D),
    Color(0xFF2E89FF),
    Color(0xFFFF8A3D),
    Color(0xFF9B5DE5),
    Color(0xFFEF4565),
    Color(0xFF1FA7FF),
  ];
}
