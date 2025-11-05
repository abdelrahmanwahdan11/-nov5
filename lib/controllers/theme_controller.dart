import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._(this.themeMode, this.primaryColor);

  static const _themeModeKey = 'theme_mode';
  static const _primaryColorKey = 'primary_color';

  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<Color> primaryColor;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themeModeKey);
    final primaryValue = prefs.getInt(_primaryColorKey);
    final mode = ThemeMode.values.firstWhere(
      (element) => element.name == themeValue,
      orElse: () => ThemeMode.system,
    );
    final color = primaryValue != null ? Color(primaryValue) : const Color(0xFF2BAA7D);
    final controller = ThemeController._(
      ValueNotifier<ThemeMode>(mode),
      ValueNotifier<Color>(color),
    );
    controller.themeMode.addListener(() {
      prefs.setString(_themeModeKey, controller.themeMode.value.name);
    });
    controller.primaryColor.addListener(() {
      prefs.setInt(_primaryColorKey, controller.primaryColor.value.value);
    });
    return controller;
  }

  void dispose() {
    themeMode.dispose();
    primaryColor.dispose();
  }
}
