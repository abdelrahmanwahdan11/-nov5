import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';
import '../../core/utils/app_scope.dart';
import '../../ui/pages/auth/auth_landing_page.dart';
import '../../ui/pages/auth/forgot_password_page.dart';
import '../../ui/pages/auth/login_page.dart';
import '../../ui/pages/auth/signup_page.dart';
import '../../ui/pages/home_shell.dart';
import '../../ui/pages/onboarding_page.dart';

class AppRouter {
  static const onboarding = '/onboarding';
  static const authLanding = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot';
  static const home = '/home';

  static String routeForEntry(AppEntryState state) {
    switch (state) {
      case AppEntryState.onboarding:
        return onboarding;
      case AppEntryState.authentication:
        return authLanding;
      case AppEntryState.home:
        return home;
    }
  }

  static Route<dynamic> onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case authLanding:
        return MaterialPageRoute(builder: (_) => const AuthLandingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeShell());
    }
  }

  static NavigatorState navigator(BuildContext context) {
    return Navigator.of(context);
  }
}

extension NavigatorSession on BuildContext {
  SessionController get session => AppScope.of(this).sessionController;
}
