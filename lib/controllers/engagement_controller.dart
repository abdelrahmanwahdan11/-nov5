import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

class EngagementController {
  EngagementController._(
    this._prefs,
    int rating,
    String? feedback,
    String? lastSeenVersion,
  )   : ratingNotifier = ValueNotifier<int>(rating),
        feedbackNotifier = ValueNotifier<String>(feedback ?? ''),
        lastSeenVersionNotifier = ValueNotifier<String?>(lastSeenVersion);

  final SharedPreferences _prefs;
  final ValueNotifier<int> ratingNotifier;
  final ValueNotifier<String> feedbackNotifier;
  final ValueNotifier<String?> lastSeenVersionNotifier;

  static Future<EngagementController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rating = prefs.getInt(AppConstants.prefAppRating) ?? 0;
    final feedback = prefs.getString(AppConstants.prefAppFeedback);
    final lastSeenVersion = prefs.getString(AppConstants.prefLastSeenVersion);
    return EngagementController._(
      prefs,
      rating,
      feedback,
      lastSeenVersion,
    );
  }

  void setRating(int value) {
    ratingNotifier.value = value;
    _prefs.setInt(AppConstants.prefAppRating, value);
  }

  void setFeedback(String value) {
    feedbackNotifier.value = value;
    _prefs.setString(AppConstants.prefAppFeedback, value);
  }

  bool shouldShowReleaseNotes() {
    final lastSeen = lastSeenVersionNotifier.value;
    return lastSeen != AppConstants.currentVersion;
  }

  Future<void> markReleaseNotesSeen() async {
    lastSeenVersionNotifier.value = AppConstants.currentVersion;
    await _prefs.setString(
      AppConstants.prefLastSeenVersion,
      AppConstants.currentVersion,
    );
  }

  void dispose() {
    ratingNotifier.dispose();
    feedbackNotifier.dispose();
    lastSeenVersionNotifier.dispose();
  }
}
