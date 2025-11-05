import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

class ThemeController {
  ThemeController._(this._prefs, ThemeMode initialMode, Color primary)
      : themeMode = ValueNotifier<ThemeMode>(initialMode),
        primaryColor = ValueNotifier<Color>(primary);

  final SharedPreferences _prefs;
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<Color> primaryColor;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(AppConstants.prefThemeMode);
    final storedColor = prefs.getInt(AppConstants.prefPrimaryColor);

    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == storedMode,
      orElse: () => ThemeMode.system,
    );

    final color = storedColor != null
        ? Color(storedColor)
        : AppConstants.primarySwatches.first;

    final controller = ThemeController._(prefs, themeMode, color);
    controller.themeMode.addListener(() {
      prefs.setString(AppConstants.prefThemeMode, controller.themeMode.value.name);
    });
    controller.primaryColor.addListener(() {
      prefs.setInt(AppConstants.prefPrimaryColor, controller.primaryColor.value.value);
    });
    return controller;
  }

  void toggleTheme(ThemeMode mode) {
    if (themeMode.value != mode) {
      themeMode.value = mode;
    }
  }

  void updatePrimary(Color color) {
    if (primaryColor.value != color) {
      primaryColor.value = color;
    }
  }
}
