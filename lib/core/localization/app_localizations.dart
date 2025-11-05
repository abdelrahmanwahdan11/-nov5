import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, String> _strings;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static Map<String, String>? _englishFallback;

  static Future<void> _ensureFallbackLoaded() async {
    if (_englishFallback != null) {
      return;
    }
    final data = await rootBundle.loadString('assets/l10n/app_en.arb');
    final Map<String, dynamic> decoded = json.decode(data) as Map<String, dynamic>;
    _englishFallback = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static Future<AppLocalizations> load(Locale locale) async {
    await _ensureFallbackLoaded();
    final localization = AppLocalizations(locale);
    final languageCode = locale.languageCode.toLowerCase();

    if (languageCode == 'en') {
      localization._strings = Map<String, String>.from(_englishFallback!);
      return localization;
    }

    final data = await rootBundle.loadString('assets/l10n/app_$languageCode.arb');
    final Map<String, dynamic> decoded = json.decode(data) as Map<String, dynamic>;
    final localizedStrings = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    localization._strings = {
      ..._englishFallback!,
      ...localizedStrings,
    };

    return localization;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key, {Map<String, String>? params}) {
    var value = _strings[key] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((placeholder, replacement) {
        value = value.replaceAll('{$placeholder}', replacement);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
