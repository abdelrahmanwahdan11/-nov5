import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/localization/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.sessionController,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final SessionController sessionController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  List<_OnboardingSlide> get _slides => const [
        _OnboardingSlide(
          icon: Icons.auto_awesome_rounded,
          titleKey: 'onboardingTitle1',
          bodyKey: 'onboardingBody1',
        ),
        _OnboardingSlide(
          icon: Icons.savings_rounded,
          titleKey: 'onboardingTitle2',
          bodyKey: 'onboardingBody2',
        ),
        _OnboardingSlide(
          icon: Icons.explore_rounded,
          titleKey: 'onboardingTitle3',
          bodyKey: 'onboardingBody3',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final next = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _completeOnboarding() async {
    await widget.sessionController.markOnboardingSeen();
  }

  void _goToNext() {
    if (_currentIndex == _slides.length - 1) {
      unawaited(_completeOnboarding());
    } else {
      final next = _currentIndex + 1;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: Text(t.translate('onboardingSkip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _OnboardingCard(slide: slide);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 10,
                  width: _currentIndex == index ? 26 : 12,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ).animate().fadeIn(duration: 260.ms).scale(),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _ThemeSwitcher(controller: widget.themeController, t: t),
                  const SizedBox(height: 16),
                  _LocaleSwitcher(controller: widget.localeController, t: t),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToNext,
                      child: Text(
                        _currentIndex == _slides.length - 1
                            ? t.translate('onboardingStart')
                            : t.translate('onboardingNext'),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 96,
            color: theme.colorScheme.primary,
          ).animate().fadeIn(duration: 420.ms).scale(begin: const Offset(0.6, 0.6)),
          const SizedBox(height: 32),
          Text(
            t.translate(slide.titleKey),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            t.translate(slide.bodyKey),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher({required this.controller, required this.t});

  final ThemeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller.themeMode,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('onboardingTheme'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: ThemeMode.values.map((value) {
                final isActive = value == mode;
                final labelKey = switch (value) {
                  ThemeMode.system => 'systemMode',
                  ThemeMode.light => 'lightMode',
                  ThemeMode.dark => 'darkMode',
                };
                return ChoiceChip(
                  label: Text(t.translate(labelKey)),
                  selected: isActive,
                  onSelected: (_) => controller.toggleTheme(value),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _LocaleSwitcher extends StatelessWidget {
  const _LocaleSwitcher({required this.controller, required this.t});

  final LocaleController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: controller.locale,
      builder: (context, locale, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('onboardingLanguage'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(t.translate('english')),
                ),
                ButtonSegment(
                  value: const Locale('ar'),
                  label: Text(t.translate('arabic')),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (value) {
                controller.updateLocale(value.first);
              },
            ),
          ],
        );
      },
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;
}
