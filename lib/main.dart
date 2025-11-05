import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  final localeController = await LocaleController.load();

  runApp(MawaidApp(
    themeController: themeController,
    localeController: localeController,
  ));
}

class MawaidApp extends StatefulWidget {
  const MawaidApp({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  State<MawaidApp> createState() => _MawaidAppState();
}

class _MawaidAppState extends State<MawaidApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: widget.localeController.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: widget.themeController.primaryColor,
          builder: (context, primary, __) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: widget.themeController.themeMode,
              builder: (context, mode, ___) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: AppTheme.light(primary, locale),
                  darkTheme: AppTheme.dark(primary, locale),
                  themeMode: mode,
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).translate('appTitle'),
                  home: _Shell(
                    selectedIndex: _selectedIndex,
                    onIndexChanged: (value) {
                      setState(() => _selectedIndex = value);
                    },
                    themeController: widget.themeController,
                    localeController: widget.localeController,
                    primaryColor: primary,
                    locale: locale,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.themeController,
    required this.localeController,
    required this.primaryColor,
    required this.locale,
  });

  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final ThemeController themeController;
  final LocaleController localeController;
  final Color primaryColor;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      SettingsPage(
        themeController: themeController,
        localeController: localeController,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: selectedIndex,
        onChanged: onIndexChanged,
        primaryColor: primaryColor,
        locale: locale,
      ),
    );
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.primaryColor,
    required this.locale,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final Color primaryColor;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final labels = [t.translate('welcome'), t.translate('settings')];
    final icons = const [Icons.dashboard_rounded, Icons.settings_rounded];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (index) {
              final isActive = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.fastOutSlowIn,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          color: isActive
                              ? primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        )
                            .animate(delay: (index * 80).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? primaryColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                              ),
                        )
                            .animate(delay: (index * 80 + 120).ms)
                            .fadeIn(duration: 320.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
