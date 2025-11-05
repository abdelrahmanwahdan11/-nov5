import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

class ProfileController {
  ProfileController._(
    this._prefs,
    String name,
    String title,
    String bio,
  )   : nameNotifier = ValueNotifier<String>(name),
        titleNotifier = ValueNotifier<String>(title),
        bioNotifier = ValueNotifier<String>(bio);

  final SharedPreferences _prefs;
  final ValueNotifier<String> nameNotifier;
  final ValueNotifier<String> titleNotifier;
  final ValueNotifier<String> bioNotifier;

  static Future<ProfileController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.prefProfileName) ?? 'Laila Youssef';
    final title =
        prefs.getString(AppConstants.prefProfileTitle) ?? 'Product Designer';
    final bio = prefs.getString(AppConstants.prefProfileBio) ??
        'Creating mindful financial journeys for modern lifestyles.';

    final controller = ProfileController._(prefs, name, title, bio);
    controller._wirePersistence();
    return controller;
  }

  void _wirePersistence() {
    nameNotifier.addListener(() {
      _prefs.setString(AppConstants.prefProfileName, nameNotifier.value);
    });
    titleNotifier.addListener(() {
      _prefs.setString(AppConstants.prefProfileTitle, titleNotifier.value);
    });
    bioNotifier.addListener(() {
      _prefs.setString(AppConstants.prefProfileBio, bioNotifier.value);
    });
  }

  void updateProfile({required String name, required String title, String? bio}) {
    nameNotifier.value = name;
    titleNotifier.value = title;
    if (bio != null) {
      bioNotifier.value = bio;
    }
  }

  void dispose() {
    nameNotifier.dispose();
    titleNotifier.dispose();
    bioNotifier.dispose();
  }
}
