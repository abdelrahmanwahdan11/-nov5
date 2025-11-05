import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEntryState { onboarding, authentication, home }

enum AuthState { guest, authenticated, unauthenticated }

class SessionController {
  SessionController._(
    this.entryState,
    this.authState,
    this.displayName,
    this.privacyMode,
    this.tutorialSeen,
  );

  static const _onboardingKey = 'seen_onboarding';
  static const _authKey = 'auth_state';
  static const _displayNameKey = 'display_name';
  static const _privacyKey = 'privacy_mode';
  static const _tutorialKey = 'tutorial_seen';

  final ValueNotifier<AppEntryState> entryState;
  final ValueNotifier<AuthState> authState;
  final ValueNotifier<String> displayName;
  final ValueNotifier<bool> privacyMode;
  final ValueNotifier<bool> tutorialSeen;

  static Future<SessionController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    final auth = prefs.getString(_authKey);
    final displayName = prefs.getString(_displayNameKey) ?? 'Guest';
    final privacy = prefs.getBool(_privacyKey) ?? false;
    final tutorial = prefs.getBool(_tutorialKey) ?? false;
    final authState = _decodeAuthState(auth);
    final entry = !seenOnboarding
        ? AppEntryState.onboarding
        : (authState == AuthState.authenticated ? AppEntryState.home : AppEntryState.authentication);
    final controller = SessionController._(
      ValueNotifier(entry),
      ValueNotifier(authState),
      ValueNotifier(displayName),
      ValueNotifier(privacy),
      ValueNotifier(tutorial),
    );
    controller.authState.addListener(() {
      prefs.setString(_authKey, controller.authState.value.name);
      prefs.setBool(_onboardingKey, true);
      controller.entryState.value = controller.authState.value == AuthState.authenticated
          ? AppEntryState.home
          : AppEntryState.authentication;
    });
    controller.entryState.addListener(() {
      if (controller.entryState.value == AppEntryState.home) {
        prefs.setBool(_onboardingKey, true);
      }
    });
    controller.displayName.addListener(() {
      prefs.setString(_displayNameKey, controller.displayName.value);
    });
    controller.privacyMode.addListener(() {
      prefs.setBool(_privacyKey, controller.privacyMode.value);
    });
    controller.tutorialSeen.addListener(() {
      prefs.setBool(_tutorialKey, controller.tutorialSeen.value);
    });
    return controller;
  }

  static AuthState _decodeAuthState(String? stored) {
    switch (stored) {
      case 'authenticated':
        return AuthState.authenticated;
      case 'guest':
        return AuthState.guest;
      default:
        return AuthState.unauthenticated;
    }
  }

  void completeOnboarding() {
    entryState.value = authState.value == AuthState.authenticated
        ? AppEntryState.home
        : AppEntryState.authentication;
  }

  void signIn({required String name}) {
    displayName.value = name;
    authState.value = AuthState.authenticated;
  }

  void continueAsGuest() {
    displayName.value = 'Guest';
    authState.value = AuthState.guest;
  }

  void signOut() {
    authState.value = AuthState.unauthenticated;
  }

  void markTutorialSeen() {
    tutorialSeen.value = true;
  }

  void dispose() {
    entryState.dispose();
    authState.dispose();
    displayName.dispose();
    privacyMode.dispose();
    tutorialSeen.dispose();
  }
}
