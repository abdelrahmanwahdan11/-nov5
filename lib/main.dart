import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/budgets_controller.dart';
import 'controllers/display_controller.dart';
import 'controllers/goals_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/recipients_controller.dart';
import 'controllers/recurring_payments_controller.dart';
import 'controllers/search_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/transactions_controller.dart';
import 'controllers/wallet_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_scope.dart';
import 'ui/pages/auth/auth_landing_page.dart';
import 'ui/pages/auth/forgot_password_page.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/auth/signup_page.dart';
import 'ui/pages/budgets_page.dart';
import 'ui/pages/guides_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/onboarding_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/transactions_page.dart';
import 'ui/pages/wallets_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  final localeController = await LocaleController.load();
  final transactionsController = await TransactionsController.load();
  final searchController =
      await SearchController.load(transactionsController.allTransactions);
  final budgetsController = await BudgetsController.load();
  final sessionController = await SessionController.load();
  final profileController = await ProfileController.load();
  final walletController = await WalletController.load();
  final displayController = await DisplayController.load();
  final goalsController = await GoalsController.load();
  final recipientsController = await RecipientsController.load();
  final recurringPaymentsController = await RecurringPaymentsController.load();

  await transactionsController.updateLocale(localeController.locale.value);

  runApp(MawaidApp(
    themeController: themeController,
    localeController: localeController,
    transactionsController: transactionsController,
    searchController: searchController,
    budgetsController: budgetsController,
    sessionController: sessionController,
    profileController: profileController,
    walletController: walletController,
    displayController: displayController,
    goalsController: goalsController,
    recipientsController: recipientsController,
    recurringPaymentsController: recurringPaymentsController,
  ));
}

class MawaidApp extends StatefulWidget {
  const MawaidApp({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.transactionsController,
    required this.searchController,
    required this.budgetsController,
    required this.sessionController,
    required this.profileController,
    required this.walletController,
    required this.displayController,
    required this.goalsController,
    required this.recipientsController,
    required this.recurringPaymentsController,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final TransactionsController transactionsController;
  final SearchController searchController;
  final BudgetsController budgetsController;
  final SessionController sessionController;
  final ProfileController profileController;
  final WalletController walletController;
  final DisplayController displayController;
  final GoalsController goalsController;
  final RecipientsController recipientsController;
  final RecurringPaymentsController recurringPaymentsController;

  @override
  State<MawaidApp> createState() => _MawaidAppState();
}

class _MawaidAppState extends State<MawaidApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final String _initialRoute;
  late AppEntryState _currentEntry;
  String? _pendingRoute;
  bool _pendingFlushScheduled = false;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _currentEntry = widget.sessionController.entryState.value;
    _initialRoute = AppRouter.routeForEntry(_currentEntry);
    widget.sessionController.entryState.addListener(_handleEntryStateChange);
    widget.localeController.locale.addListener(_handleLocaleChange);
    _handleLocaleChange();
  }

  @override
  void dispose() {
    widget.sessionController.entryState
        .removeListener(_handleEntryStateChange);
    widget.localeController.locale.removeListener(_handleLocaleChange);
    widget.transactionsController.dispose();
    widget.searchController.dispose();
    widget.budgetsController.dispose();
    widget.sessionController.dispose();
    widget.profileController.dispose();
    widget.walletController.dispose();
    widget.displayController.dispose();
    widget.goalsController.dispose();
    widget.recipientsController.dispose();
    widget.recurringPaymentsController.dispose();
    super.dispose();
  }

  void _handleLocaleChange() {
    final locale = widget.localeController.locale.value;
    unawaited(widget.transactionsController.updateLocale(locale));
  }

  void _handleEntryStateChange() {
    final next = widget.sessionController.entryState.value;
    if (next == _currentEntry) return;
    _currentEntry = next;
    final route = AppRouter.routeForEntry(next);
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _pendingRoute = route;
      _schedulePendingNavigation();
      return;
    }
    _pendingRoute = null;
    navigator.pushNamedAndRemoveUntil(route, (route) => false);
  }

  void _schedulePendingNavigation() {
    if (_pendingFlushScheduled) {
      return;
    }
    _pendingFlushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingFlushScheduled = false;
      if (_pendingRoute == null) {
        return;
      }
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _schedulePendingNavigation();
        return;
      }
      final route = _pendingRoute!;
      _pendingRoute = null;
      navigator.pushNamedAndRemoveUntil(route, (route) => false);
    });
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.onboarding:
        return AppRouter.buildRoute(
          settings,
          (_) => OnboardingPage(
            themeController: widget.themeController,
            localeController: widget.localeController,
            sessionController: widget.sessionController,
          ),
        );
      case AppRouter.auth:
        return AppRouter.buildRoute(
          settings,
          (_) => AuthLandingPage(sessionController: widget.sessionController),
        );
      case AppRouter.login:
        return AppRouter.buildRoute(
          settings,
          (_) => LoginPage(sessionController: widget.sessionController),
        );
      case AppRouter.signup:
        return AppRouter.buildRoute(
          settings,
          (_) => SignupPage(sessionController: widget.sessionController),
        );
      case AppRouter.forgotPassword:
        return AppRouter.buildRoute(
          settings,
          (_) => const ForgotPasswordPage(),
        );
      case AppRouter.wallets:
        return AppRouter.buildRoute(
          settings,
          (_) => WalletsPage(
            walletController: widget.walletController,
            profileController: widget.profileController,
            privacyListenable: widget.sessionController.privacyModeNotifier,
          ),
        );
      case AppRouter.home:
      default:
        return AppRouter.buildRoute(
          settings,
          (_) => HomeShell(
            themeController: widget.themeController,
            localeController: widget.localeController,
            transactionsController: widget.transactionsController,
            searchController: widget.searchController,
            budgetsController: widget.budgetsController,
            sessionController: widget.sessionController,
            profileController: widget.profileController,
            walletController: widget.walletController,
            goalsController: widget.goalsController,
            recipientsController: widget.recipientsController,
            recurringPaymentsController: widget.recurringPaymentsController,
          ),
        );
    }
  }

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
                  navigatorKey: _navigatorKey,
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  localeResolutionCallback: (deviceLocale, supportedLocales) {
                    if (deviceLocale == null) {
                      return supportedLocales.first;
                    }
                    for (final supported in supportedLocales) {
                      if (supported.languageCode == deviceLocale.languageCode) {
                        return supported;
                      }
                    }
                    return supportedLocales.first;
                  },
                  theme: AppTheme.light(primary, locale),
                  darkTheme: AppTheme.dark(primary, locale),
                  themeMode: mode,
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).translate('appTitle'),
                  initialRoute: _initialRoute,
                  onGenerateRoute: _onGenerateRoute,
                  builder: (context, child) {
                    return AppScope(
                      themeController: widget.themeController,
                      localeController: widget.localeController,
                      transactionsController: widget.transactionsController,
                      searchController: widget.searchController,
                      budgetsController: widget.budgetsController,
                      sessionController: widget.sessionController,
                      profileController: widget.profileController,
                      walletController: widget.walletController,
                      displayController: widget.displayController,
                      goalsController: widget.goalsController,
                      recipientsController: widget.recipientsController,
                      recurringPaymentsController:
                          widget.recurringPaymentsController,
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.transactionsController,
    required this.searchController,
    required this.budgetsController,
    required this.sessionController,
    required this.profileController,
    required this.walletController,
    required this.goalsController,
    required this.recipientsController,
    required this.recurringPaymentsController,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final TransactionsController transactionsController;
  final SearchController searchController;
  final BudgetsController budgetsController;
  final SessionController sessionController;
  final ProfileController profileController;
  final WalletController walletController;
  final GoalsController goalsController;
  final RecipientsController recipientsController;
  final RecurringPaymentsController recurringPaymentsController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        key: const PageStorageKey('home-page'),
        transactionsController: widget.transactionsController,
        budgetsController: widget.budgetsController,
        searchController: widget.searchController,
        walletController: widget.walletController,
        sessionController: widget.sessionController,
        profileController: widget.profileController,
        goalsController: widget.goalsController,
        recipientsController: widget.recipientsController,
        recurringPaymentsController: widget.recurringPaymentsController,
        onOpenBudgets: () => setState(() => _currentIndex = 1),
        onOpenTransactions: () => setState(() => _currentIndex = 3),
      ),
      BudgetsPage(
        key: const PageStorageKey('budgets-page'),
        budgetsController: widget.budgetsController,
        privacyListenable: widget.sessionController.privacyModeNotifier,
        goalsController: widget.goalsController,
      ),
      GuidesPage(
        key: const PageStorageKey('guides-page'),
        profileController: widget.profileController,
      ),
      TransactionsPage(
        key: const PageStorageKey('transactions-page'),
        transactionsController: widget.transactionsController,
        searchController: widget.searchController,
        privacyListenable: widget.sessionController.privacyModeNotifier,
        recurringPaymentsController: widget.recurringPaymentsController,
      ),
      SettingsPage(
        key: const PageStorageKey('settings-page'),
        themeController: widget.themeController,
        localeController: widget.localeController,
        sessionController: widget.sessionController,
        profileController: widget.profileController,
      ),
    ];

    return ValueListenableBuilder<Color>(
      valueListenable: widget.themeController.primaryColor,
      builder: (context, primary, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: widget.localeController.locale,
          builder: (context, locale, __) {
            return Scaffold(
              body: PageStorage(
                bucket: _bucket,
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
              bottomNavigationBar: _AnimatedBottomNav(
                currentIndex: _currentIndex,
                onChanged: (value) => setState(() => _currentIndex = value),
                primaryColor: primary,
                locale: locale,
              ),
            );
          },
        );
      },
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
    final labels = [
      t.translate('navHome'),
      t.translate('navBudgets'),
      t.translate('navGuides'),
      t.translate('navTransactions'),
      t.translate('navSettings'),
    ];
    final icons = const [
      Icons.dashboard_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.auto_stories_rounded,
      Icons.receipt_long_rounded,
      Icons.settings_rounded,
    ];

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
