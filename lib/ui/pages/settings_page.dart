import 'package:flutter/material.dart';

import '../../controllers/display_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    final themeController = scope.themeController;
    final localeController = scope.localeController;
    final sessionController = scope.sessionController;
    final displayController = scope.displayController;
    final profileController = scope.profileController;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.translate('settingsTitle'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Text(l10n.translate('settingsAppearance'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController.themeMode,
            builder: (context, mode, _) {
              return DropdownButtonFormField<ThemeMode>(
                value: mode,
                decoration: InputDecoration(labelText: l10n.translate('settingsTheme')),
                items: ThemeMode.values
                    .map(
                      (candidate) => DropdownMenuItem(
                        value: candidate,
                        child: Text(_themeModeLabel(candidate, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    themeController.themeMode.value = value;
                  }
                },
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<Color>(
            valueListenable: themeController.primaryColor,
            builder: (context, color, _) {
              final colors = [
                const Color(0xFF2BAA7D),
                const Color(0xFF0067C0),
                const Color(0xFFE65C4F),
                const Color(0xFF9C27B0),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.translate('settingsPrimaryColor')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: colors
                        .map(
                          (candidate) => GestureDetector(
                            onTap: () => themeController.primaryColor.value = candidate,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: candidate,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: candidate == color
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.translate('settingsLanguage'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<Locale>(
            valueListenable: localeController.locale,
            builder: (context, locale, _) {
              return DropdownButtonFormField<String>(
                value: locale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (code) {
                  if (code != null) {
                    localeController.locale.value = Locale(code);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.translate('settingsAccount'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: profileController.name,
            builder: (context, name, _) {
              return TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: l10n.translate('settingsDisplayName')),
                onChanged: (value) => profileController.name.value = value,
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: profileController.phone,
            builder: (context, phone, _) {
              return TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                onChanged: (value) => profileController.phone.value = value,
              );
            },
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<bool>(
            valueListenable: sessionController.privacyMode,
            builder: (context, privacy, _) {
              return SwitchListTile(
                value: privacy,
                onChanged: (value) => sessionController.privacyMode.value = value,
                title: Text(l10n.translate('settingsPrivacy')),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: displayController.reduceMotion,
            builder: (context, reduceMotion, _) {
              return SwitchListTile(
                value: reduceMotion,
                onChanged: (value) => displayController.reduceMotion.value = value,
                title: const Text('Reduce motion'),
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<CardSurfaceStyle>(
            valueListenable: displayController.surfaceStyle,
            builder: (context, style, _) {
              return DropdownButtonFormField<CardSurfaceStyle>(
                value: style,
                decoration: const InputDecoration(labelText: 'Card style'),
                items: CardSurfaceStyle.values
                    .map(
                      (candidate) => DropdownMenuItem(
                        value: candidate,
                        child: Text(candidate == CardSurfaceStyle.glass ? 'Glass' : 'Solid'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    displayController.surfaceStyle.value = value;
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: sessionController.signOut,
            child: Text(l10n.translate('logout')),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.translate('themeLight');
      case ThemeMode.dark:
        return l10n.translate('themeDark');
      case ThemeMode.system:
      default:
        return l10n.translate('themeSystem');
    }
  }
}
