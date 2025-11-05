import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  ProfileController._(this.name, this.phone);

  static const _nameKey = 'profile_name';
  static const _phoneKey = 'profile_phone';

  final ValueNotifier<String> name;
  final ValueNotifier<String> phone;

  static Future<ProfileController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = ProfileController._(
      ValueNotifier(prefs.getString(_nameKey) ?? 'Guest'),
      ValueNotifier(prefs.getString(_phoneKey) ?? ''),
    );
    controller.name.addListener(() {
      prefs.setString(_nameKey, controller.name.value);
    });
    controller.phone.addListener(() {
      prefs.setString(_phoneKey, controller.phone.value);
    });
    return controller;
  }

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}
