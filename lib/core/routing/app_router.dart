import 'package:flutter/material.dart';

enum AppEntryState { onboarding, auth, home }

class AppRouter {
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot';
  static const home = '/home';
  static const wallets = '/wallets';

  static String routeForEntry(AppEntryState state) {
    switch (state) {
      case AppEntryState.onboarding:
        return onboarding;
      case AppEntryState.auth:
        return auth;
      case AppEntryState.home:
        return home;
    }
  }

  static PageRoute<T> buildRoute<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
