import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CardSurfaceStyle { glass, solid }

class DisplayController {
  DisplayController._(this.surfaceStyle, this.reduceMotion);

  static const _surfaceKey = 'surface_style';
  static const _motionKey = 'reduce_motion';

  final ValueNotifier<CardSurfaceStyle> surfaceStyle;
  final ValueNotifier<bool> reduceMotion;

  static Future<DisplayController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final styleName = prefs.getString(_surfaceKey) ?? CardSurfaceStyle.glass.name;
    final style = CardSurfaceStyle.values.firstWhere(
      (element) => element.name == styleName,
      orElse: () => CardSurfaceStyle.glass,
    );
    final motion = prefs.getBool(_motionKey) ?? false;
    final controller = DisplayController._(
      ValueNotifier(style),
      ValueNotifier(motion),
    );
    controller.surfaceStyle.addListener(() {
      prefs.setString(_surfaceKey, controller.surfaceStyle.value.name);
    });
    controller.reduceMotion.addListener(() {
      prefs.setBool(_motionKey, controller.reduceMotion.value);
    });
    return controller;
  }

  void dispose() {
    surfaceStyle.dispose();
    reduceMotion.dispose();
  }
}
