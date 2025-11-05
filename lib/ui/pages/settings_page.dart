import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ListView(
          children: [
            Text(
              t.translate('settings'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 24),
            _ThemeSection(controller: themeController, t: t),
            const SizedBox(height: 24),
            _LocaleSection(controller: localeController, t: t),
            const SizedBox(height: 24),
            _PrimaryColorSection(controller: themeController, t: t),
          ],
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.controller, required this.t});

  final ThemeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller.themeMode,
      builder: (context, mode, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('theme'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                      selected: isActive,
                      label: Text(t.translate(labelKey)),
                      onSelected: (_) => controller.toggleTheme(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}

class _LocaleSection extends StatelessWidget {
  const _LocaleSection({required this.controller, required this.t});

  final LocaleController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: controller.locale,
      builder: (context, locale, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('language'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                  onSelectionChanged: (selection) {
                    final newLocale = selection.first;
                    controller.updateLocale(newLocale);
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}

class _PrimaryColorSection extends StatelessWidget {
  const _PrimaryColorSection({required this.controller, required this.t});

  final ThemeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: controller.primaryColor,
      builder: (context, color, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('primaryColor'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.translate('pickAColor'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.primarySwatches.map((option) {
                    final isActive = option == color;
                    return GestureDetector(
                      onTap: () => controller.updatePrimary(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.fastOutSlowIn,
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: option,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isActive
                            ? Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}
