import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/session_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/app_scope.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  late Timer _timer;
  int _index = 0;

  final _pages = const [0, 1, 2];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final next = (_index + 1) % _pages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    final scope = AppScope.of(context);
    scope.sessionController.completeOnboarding();
    AppRouter.navigator(context)
        .pushNamedAndRemoveUntil(AppRouter.authLanding, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _complete,
                child: Text(l10n.translate('onboardingSkip')),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  _OnboardingSlide(
                    title: l10n.translate('onboardingTitle1'),
                    subtitle: l10n.translate('onboardingSubtitle1'),
                    icon: Icons.wallet,
                  ),
                  _OnboardingSlide(
                    title: l10n.translate('onboardingTitle2'),
                    subtitle: l10n.translate('onboardingSubtitle2'),
                    icon: Icons.timeline,
                  ),
                  _OnboardingSlide(
                    title: l10n.translate('onboardingTitle3'),
                    subtitle: l10n.translate('onboardingSubtitle3'),
                    icon: Icons.palette,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _complete,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _index == _pages.length - 1
                      ? l10n.translate('onboardingStart')
                      : l10n.translate('onboardingNext'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 90, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
