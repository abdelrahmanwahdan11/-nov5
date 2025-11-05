import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_scope.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('authCreateAccount'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.wallet, size: 88, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 32),
            Text(
              l10n.translate('authWelcomeBack'),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('guestWelcome'),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRouter.login),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(l10n.translate('authSignIn')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRouter.signup),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(l10n.translate('authSignUp')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                AppScope.of(context).sessionController.continueAsGuest();
                AppRouter.navigator(context)
                    .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
              },
              child: Text(l10n.translate('authGuest')),
            ),
          ],
        ),
      ),
    );
  }
}
