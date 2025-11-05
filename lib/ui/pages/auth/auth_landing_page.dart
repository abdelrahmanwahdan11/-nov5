import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../controllers/session_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.translate('authWelcomeTitle'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                t.translate('authWelcomeSubtitle'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.login);
                  },
                  child: Text(t.translate('login')),
                ),
              ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.signup);
                  },
                  child: Text(t.translate('createAccount')),
                ),
              ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  sessionController.continueAsGuest();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.translate('guestModeConfirmed')),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt_rounded),
                label: Text(t.translate('guest')),
              ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.forgotPassword);
                  },
                  child: Text(t.translate('forgotPassword')), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
