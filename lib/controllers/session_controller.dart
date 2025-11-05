import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/routing/app_router.dart';
import '../core/utils/app_constants.dart';

class SessionController {
  SessionController._(
    this._prefs,
    AppEntryState initialState,
    bool isGuest,
    bool isAuthenticated,
    bool hasSeenCoach,
  )   : entryState = ValueNotifier<AppEntryState>(initialState),
        isGuestNotifier = ValueNotifier<bool>(isGuest),
        showCoachNotifier = ValueNotifier<bool>(!hasSeenCoach),
        _isAuthenticated = isAuthenticated,
        _hasSeenCoach = hasSeenCoach;

  final SharedPreferences _prefs;
  final ValueNotifier<AppEntryState> entryState;
  final ValueNotifier<bool> isGuestNotifier;
  final ValueNotifier<bool> showCoachNotifier;
  bool _isAuthenticated;
  bool _hasSeenCoach;

  static Future<SessionController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding =
        prefs.getBool(AppConstants.prefSeenOnboarding) ?? false;
    final isGuest = prefs.getBool(AppConstants.prefIsGuest) ?? false;
    final isAuthenticated =
        prefs.getBool(AppConstants.prefIsAuthenticated) ?? false;
    final hasSeenCoach = prefs.getBool(AppConstants.prefSeenCoach) ?? false;

    final initialState = !seenOnboarding
        ? AppEntryState.onboarding
        : (isGuest || isAuthenticated)
            ? AppEntryState.home
            : AppEntryState.auth;

    return SessionController._(
      prefs,
      initialState,
      isGuest,
      isAuthenticated,
      hasSeenCoach,
    );
  }

  bool get isGuest => isGuestNotifier.value;

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(AppConstants.prefSeenOnboarding, true);
    if (_isAuthenticated || isGuest) {
      entryState.value = AppEntryState.home;
    } else {
      entryState.value = AppEntryState.auth;
    }
  }

  Future<void> continueAsGuest() async {
    await _prefs.setBool(AppConstants.prefSeenOnboarding, true);
    await _prefs.setBool(AppConstants.prefIsGuest, true);
    await _prefs.setBool(AppConstants.prefIsAuthenticated, false);
    _isAuthenticated = false;
    isGuestNotifier.value = true;
    entryState.value = AppEntryState.home;
  }

  Future<void> signIn() async {
    await _prefs.setBool(AppConstants.prefSeenOnboarding, true);
    await _prefs.setBool(AppConstants.prefIsAuthenticated, true);
    await _prefs.setBool(AppConstants.prefIsGuest, false);
    _isAuthenticated = true;
    isGuestNotifier.value = false;
    entryState.value = AppEntryState.home;
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    isGuestNotifier.value = false;
    await _prefs
      ..setBool(AppConstants.prefIsAuthenticated, false)
      ..setBool(AppConstants.prefIsGuest, false);
    entryState.value = AppEntryState.auth;
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(AppConstants.prefSeenOnboarding, false);
    entryState.value = AppEntryState.onboarding;
  }

  Future<void> markCoachSeen() async {
    if (_hasSeenCoach) {
      showCoachNotifier.value = false;
      return;
    }
    _hasSeenCoach = true;
    showCoachNotifier.value = false;
    await _prefs.setBool(AppConstants.prefSeenCoach, true);
  }

  void requestCoachReveal() {
    _hasSeenCoach = false;
    showCoachNotifier.value = true;
    _prefs.setBool(AppConstants.prefSeenCoach, false);
  }

  bool get hasSeenCoach => _hasSeenCoach;

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppConstants.prefSeenOnboarding) ?? false;

  void dispose() {
    entryState.dispose();
    isGuestNotifier.dispose();
    showCoachNotifier.dispose();
  }
}
