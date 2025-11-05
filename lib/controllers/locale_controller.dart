import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._(this.locale);

  static const _localeKey = 'locale';

  final ValueNotifier<Locale> locale;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey) ?? 'en';
    final controller = LocaleController._(ValueNotifier(Locale(code)));
    controller.locale.addListener(() {
      prefs.setString(_localeKey, controller.locale.value.languageCode);
    });
    return controller;
  }

  void dispose() {
    locale.dispose();
  }
}
