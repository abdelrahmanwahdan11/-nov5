import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

enum CardSurfaceStyle { glass, solid, subtle }

class DisplayController {
  DisplayController._(
    this._prefs,
    CardSurfaceStyle style,
    bool reduceMotion,
  )   : cardStyle = ValueNotifier<CardSurfaceStyle>(style),
        reduceMotionNotifier = ValueNotifier<bool>(reduceMotion);

  final SharedPreferences _prefs;
  final ValueNotifier<CardSurfaceStyle> cardStyle;
  final ValueNotifier<bool> reduceMotionNotifier;

  static Future<DisplayController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedStyle = prefs.getString(AppConstants.prefCardStyle);
    final style = CardSurfaceStyle.values.firstWhere(
      (value) => value.name == storedStyle,
      orElse: () => CardSurfaceStyle.glass,
    );
    final reduceMotion =
        prefs.getBool(AppConstants.prefReduceMotion) ?? false;
    return DisplayController._(prefs, style, reduceMotion);
  }

  Future<void> setCardStyle(CardSurfaceStyle style) async {
    if (cardStyle.value == style) return;
    cardStyle.value = style;
    await _prefs.setString(AppConstants.prefCardStyle, style.name);
  }

  Future<void> setReduceMotion(bool enabled) async {
    if (reduceMotionNotifier.value == enabled) return;
    reduceMotionNotifier.value = enabled;
    await _prefs.setBool(AppConstants.prefReduceMotion, enabled);
  }

  void dispose() {
    cardStyle.dispose();
    reduceMotionNotifier.dispose();
  }
}
