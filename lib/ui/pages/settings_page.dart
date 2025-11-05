import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/display_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/app_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.sessionController,
    required this.profileController,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final SessionController sessionController;
  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final displayController = AppScope.of(context).displayController;

    return ValueListenableBuilder<bool>(
      valueListenable: displayController.reduceMotionNotifier,
      builder: (context, reduceMotion, _) {
        Widget heading = Text(
          t.translate('settings'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
        if (!reduceMotion) {
          heading = heading
              .animate()
              .fadeIn(duration: 360.ms)
              .slideY(begin: 0.2, end: 0);
        }

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ListView(
              children: [
                heading,
                const SizedBox(height: 24),
                _ProfileSection(
                  profileController: profileController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 24),
                _ThemeSection(
                  controller: themeController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 24),
                _LocaleSection(
                  controller: localeController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 24),
                _PrimaryColorSection(
                  controller: themeController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 24),
                _DisplayPreferencesSection(
                  controller: displayController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 24),
                _ExperienceSection(
                  sessionController: sessionController,
                  t: t,
                  reduceMotion: reduceMotion,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.profileController,
    required this.t,
    required this.reduceMotion,
  });

  final ProfileController profileController;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: profileController.nameNotifier,
      builder: (context, name, _) {
        final trimmedName = name.trim();
        final safeName =
            trimmedName.isEmpty ? t.translate('settingsDisplayName') : trimmedName;
        final initial = trimmedName.isEmpty ? '?' : trimmedName[0];
        return ValueListenableBuilder<String>(
          valueListenable: profileController.titleNotifier,
          builder: (context, role, __) {
            return ValueListenableBuilder<String>(
              valueListenable: profileController.bioNotifier,
              builder: (context, bio, ___) {
                Widget card = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('settingsProfileTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.translate('settingsProfileSubtitle'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.15),
                            child: Text(
                              initial,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          title: Text(safeName),
                          subtitle: Text(role),
                        ),
                        if (bio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 8),
                            child: Text(
                              bio,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _showProfileEditor(context),
                            icon: const Icon(Icons.edit_rounded),
                            label: Text(t.translate('settingsEditProfile')),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (!reduceMotion) {
                  card = card
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.2, end: 0);
                }
                return card;
              },
            );
          },
        );
      },
    );
  }

  void _showProfileEditor(BuildContext context) {
    final nameController =
        TextEditingController(text: profileController.nameNotifier.value);
    final roleController =
        TextEditingController(text: profileController.titleNotifier.value);
    final bioController =
        TextEditingController(text: profileController.bioNotifier.value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: _ProfileEditorForm(
            nameController: nameController,
            roleController: roleController,
            bioController: bioController,
            onSubmit: (name, role, bio) {
              profileController.updateProfile(
                name: name,
                title: role,
                bio: bio,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.translate('settingsProfileSaved'))),
              );
            },
            t: t,
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      roleController.dispose();
      bioController.dispose();
    });
  }
}

class _ProfileEditorForm extends StatefulWidget {
  const _ProfileEditorForm({
    required this.nameController,
    required this.roleController,
    required this.bioController,
    required this.onSubmit,
    required this.t,
  });

  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController bioController;
  final void Function(String name, String role, String bio) onSubmit;
  final AppLocalizations t;

  @override
  State<_ProfileEditorForm> createState() => _ProfileEditorFormState();
}

class _ProfileEditorFormState extends State<_ProfileEditorForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        widget.nameController.text.trim(),
        widget.roleController.text.trim(),
        widget.bioController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: widget.nameController,
            decoration: InputDecoration(
              labelText: widget.t.translate('settingsDisplayName'),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.t.translate('required');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.roleController,
            decoration: InputDecoration(
              labelText: widget.t.translate('settingsRoleTitle'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.bioController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: widget.t.translate('settingsBio'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(widget.t.translate('settingsSaveChanges')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({
    required this.sessionController,
    required this.t,
    required this.reduceMotion,
  });

  final SessionController sessionController;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: sessionController.isGuestNotifier,
      builder: (context, isGuest, _) {
        final description = isGuest
            ? t.translate('guestModeDescription')
            : t.translate('signedInDescription');
        final primaryActionLabel =
            isGuest ? t.translate('login') : t.translate('signOut');

        Widget card = Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('account'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isGuest) {
                            Navigator.of(context)
                                .pushNamed(AppRouter.login);
                          } else {
                            await sessionController.signOut();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.translate('signedOut')),
                              ),
                            );
                          }
                        },
                        child: Text(primaryActionLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await sessionController.resetOnboarding();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(t.translate('onboardingRestarted')),
                            ),
                          );
                        },
                        child: Text(t.translate('replayOnboarding')),
                      ),
                    ),
                  ],
                ),
                if (isGuest)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton(
                      onPressed: () async {
                        await sessionController.continueAsGuest();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(t.translate('guestModeConfirmed')),
                          ),
                        );
                      },
                      child: Text(t.translate('stayAsGuest')),
                    ),
                  ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: sessionController.privacyModeNotifier,
                  builder: (context, hidden, __) {
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: hidden,
                      onChanged: (value) async {
                        await sessionController.setPrivacyMode(value);
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        if (messenger == null) return;
                        final message = value
                            ? t.translate('privacyHiddenToast')
                            : t.translate('privacyVisibleToast');
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                      },
                      title: Text(t.translate('privacyMode')),
                      subtitle: Text(t.translate('privacyModeDescription')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: sessionController.showCoachNotifier,
                  builder: (context, showCoach, __) {
                    final isEnabled = showCoach || !sessionController.hasSeenCoach;
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isEnabled,
                      onChanged: (value) {
                        if (value) {
                          sessionController.requestCoachReveal();
                        } else {
                          unawaited(sessionController.markCoachSeen());
                        }
                      },
                      title: Text(t.translate('settingsCoachLabel')),
                      subtitle: Text(t.translate('settingsCoachDescription')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        if (!reduceMotion) {
          card = card
              .animate()
              .fadeIn(duration: 360.ms)
              .slideY(begin: 0.2, end: 0);
        }
        return card;
      },
    );
  }
}

class _DisplayPreferencesSection extends StatelessWidget {
  const _DisplayPreferencesSection({
    required this.controller,
    required this.t,
    required this.reduceMotion,
  });

  final DisplayController controller;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('settingsDisplayPreferencesTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('settingsCardStyleLabel'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<CardSurfaceStyle>(
              valueListenable: controller.cardStyle,
              builder: (context, style, _) {
                return SegmentedButton<CardSurfaceStyle>(
                  segments: [
                    ButtonSegment(
                      value: CardSurfaceStyle.glass,
                      label: Text(
                        t.translate('settingsCardStyleGlass'),
                      ),
                    ),
                    ButtonSegment(
                      value: CardSurfaceStyle.solid,
                      label: Text(
                        t.translate('settingsCardStyleSolid'),
                      ),
                    ),
                    ButtonSegment(
                      value: CardSurfaceStyle.subtle,
                      label: Text(
                        t.translate('settingsCardStyleSubtle'),
                      ),
                    ),
                  ],
                  selected: {style},
                  onSelectionChanged: (selection) {
                    controller.setCardStyle(selection.first);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: controller.reduceMotionNotifier,
              builder: (context, value, _) {
                return SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: value,
                  onChanged: (enabled) => controller.setReduceMotion(enabled),
                  title: Text(t.translate('settingsReduceMotionLabel')),
                  subtitle: Text(t.translate('settingsReduceMotionSubtitle')),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      card = card
          .animate()
          .fadeIn(duration: 360.ms)
          .slideY(begin: 0.2, end: 0);
    }
    return card;
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({
    required this.controller,
    required this.t,
    required this.reduceMotion,
  });

  final ThemeController controller;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller.themeMode,
      builder: (context, mode, _) {
        Widget card = Card(
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
        );
        if (!reduceMotion) {
          card = card
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.2, end: 0);
        }
        return card;
      },
    );
  }
}

class _LocaleSection extends StatelessWidget {
  const _LocaleSection({
    required this.controller,
    required this.t,
    required this.reduceMotion,
  });

  final LocaleController controller;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: controller.locale,
      builder: (context, locale, _) {
        Widget card = Card(
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
        );
        if (!reduceMotion) {
          card = card
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.2, end: 0);
        }
        return card;
      },
    );
  }
}

class _PrimaryColorSection extends StatelessWidget {
  const _PrimaryColorSection({
    required this.controller,
    required this.t,
    required this.reduceMotion,
  });

  final ThemeController controller;
  final AppLocalizations t;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: controller.primaryColor,
      builder: (context, color, _) {
        Widget card = Card(
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
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 240),
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
        );
        if (!reduceMotion) {
          card = card
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.2, end: 0);
        }
        return card;
      },
    );
  }
}
