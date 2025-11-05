import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._values);

  final Locale locale;
  final Map<String, dynamic> _values;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) async {
    final languageCode = AppLocalizations._canonicalLanguage(locale.languageCode);
    final path = 'assets/l10n/app_\${languageCode}.arb';
    final raw = await rootBundle.loadString(path).catchError((_) async {
      return await rootBundle.loadString('assets/l10n/app_en.arb');
    });
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AppLocalizations(Locale(languageCode), data);
  }

  static String _canonicalLanguage(String code) {
    return supportedLocales.map((locale) => locale.languageCode).contains(code)
        ? code
        : 'en';
  }

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  String translate(String key, {Map<String, String>? params}) {
    final value = _values[key];
    if (value is! String) {
      return key;
    }
    if (params == null || params.isEmpty) {
      return value;
    }
    return params.entries.fold<String>(value, (current, entry) {
      return current.replaceAll('{\${entry.key}}', entry.value);
    });
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
