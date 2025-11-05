import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

class LocaleController {
  LocaleController._(this._prefs, Locale initial)
      : locale = ValueNotifier<Locale>(initial);

  final SharedPreferences _prefs;
  final ValueNotifier<Locale> locale;

  static const Locale defaultLocale = Locale('en');

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConstants.prefLocale);
    final locale = stored != null ? Locale(stored) : defaultLocale;
    final controller = LocaleController._(prefs, locale);
    controller.locale.addListener(() {
      prefs.setString(AppConstants.prefLocale, controller.locale.value.languageCode);
    });
    return controller;
  }

  void updateLocale(Locale newLocale) {
    if (locale.value != newLocale) {
      locale.value = newLocale;
    }
  }
}
