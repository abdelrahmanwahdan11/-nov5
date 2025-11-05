import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'controllers/analytics_controller.dart';
import 'controllers/budgets_controller.dart';
import 'controllers/display_controller.dart';
import 'controllers/engagement_controller.dart';
import 'controllers/goals_controller.dart';
import 'controllers/help_center_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/recipients_controller.dart';
import 'controllers/recurring_payments_controller.dart';
import 'controllers/search_controller.dart';
import 'controllers/shortcuts_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/tools_controller.dart';
import 'controllers/transactions_controller.dart';
import 'controllers/wallet_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_scope.dart';
import 'core/utils/app_constants.dart';
import 'data/models/app_notification.dart';
import 'ui/pages/auth/auth_landing_page.dart';
import 'ui/pages/auth/forgot_password_page.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/auth/signup_page.dart';
import 'ui/pages/budgets_page.dart';
import 'ui/pages/guides_page.dart';
import 'ui/pages/help_center_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/insights_page.dart';
import 'ui/pages/notifications_page.dart';
import 'ui/pages/onboarding_page.dart';
import 'ui/pages/rating_page.dart';
import 'ui/pages/statement_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/merchant_profile_page.dart';
import 'ui/pages/transactions_page.dart';
import 'ui/pages/wallets_page.dart';
import 'ui/pages/calculators_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  final localeController = await LocaleController.load();
  final transactionsController = await TransactionsController.load();
  final searchController =
      await SearchController.load(transactionsController.allTransactions);
  final analyticsController =
      await AnalyticsController.load(transactionsController.allTransactions);
  final budgetsController = await BudgetsController.load();
  final sessionController = await SessionController.load();
  final profileController = await ProfileController.load();
  final walletController = await WalletController.load();
  final displayController = await DisplayController.load();
  final goalsController = await GoalsController.load();
  final recipientsController = await RecipientsController.load();
  final recurringPaymentsController = await RecurringPaymentsController.load();
  final toolsController = await ToolsController.load();
  final notificationsController = await NotificationsController.load();
  final helpCenterController = await HelpCenterController.load();
  final shortcutsController = await ShortcutsController.load();
  final engagementController = await EngagementController.load();

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
    analyticsController: analyticsController,
    toolsController: toolsController,
    notificationsController: notificationsController,
    helpCenterController: helpCenterController,
    shortcutsController: shortcutsController,
    engagementController: engagementController,
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
    required this.analyticsController,
    required this.toolsController,
    required this.notificationsController,
    required this.helpCenterController,
    required this.shortcutsController,
    required this.engagementController,
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
  final AnalyticsController analyticsController;
  final ToolsController toolsController;
  final NotificationsController notificationsController;
  final HelpCenterController helpCenterController;
  final ShortcutsController shortcutsController;
  final EngagementController engagementController;

  @override
  State<MawaidApp> createState() => _MawaidAppState();
}

class _MawaidAppState extends State<MawaidApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final String _initialRoute;
  late AppEntryState _currentEntry;
  String? _pendingRoute;
  bool _pendingFlushScheduled = false;
  late final VoidCallback _transactionsListener;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _currentEntry = widget.sessionController.entryState.value;
    _initialRoute = AppRouter.routeForEntry(_currentEntry);
    widget.sessionController.entryState.addListener(_handleEntryStateChange);
    widget.localeController.locale.addListener(_handleLocaleChange);
    _transactionsListener = () {
      widget.searchController
          .rebuildSource(widget.transactionsController.allTransactions);
      widget.analyticsController
          .rebuild(widget.transactionsController.allTransactions);
    };
    widget.transactionsController.addListener(_transactionsListener);
    _handleLocaleChange();
  }

  @override
  void dispose() {
    widget.sessionController.entryState
        .removeListener(_handleEntryStateChange);
    widget.localeController.locale.removeListener(_handleLocaleChange);
    widget.transactionsController.removeListener(_transactionsListener);
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
    widget.analyticsController.dispose();
    widget.toolsController.dispose();
    widget.notificationsController.dispose();
    widget.helpCenterController.dispose();
    widget.shortcutsController.dispose();
    widget.engagementController.dispose();
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
      case AppRouter.insights:
        return AppRouter.buildRoute(
          settings,
          (_) => InsightsPage(
            analyticsController: widget.analyticsController,
            sessionController: widget.sessionController,
          ),
        );
      case AppRouter.statement:
        return AppRouter.buildRoute(
          settings,
          (_) => StatementPage(
            analyticsController: widget.analyticsController,
            sessionController: widget.sessionController,
          ),
        );
      case AppRouter.calculators:
        return AppRouter.buildRoute(
          settings,
          (_) => CalculatorsPage(
            toolsController: widget.toolsController,
          ),
        );
      case AppRouter.notifications:
        return AppRouter.buildRoute(
          settings,
          (_) => NotificationsPage(
            notificationsController: widget.notificationsController,
          ),
        );
      case AppRouter.help:
        return AppRouter.buildRoute(
          settings,
          (_) => HelpCenterPage(
            helpCenterController: widget.helpCenterController,
          ),
        );
      case AppRouter.rate:
        return AppRouter.buildRoute(
          settings,
          (_) => RatingPage(
            engagementController: widget.engagementController,
          ),
        );
      case AppRouter.guides:
        return AppRouter.buildRoute(
          settings,
          (_) => GuidesPage(
            profileController: widget.profileController,
          ),
        );
      case AppRouter.merchantProfile:
        final merchant = (settings.arguments as String?) ?? 'Merchant';
        return AppRouter.buildRoute(
          settings,
          (_) => MerchantProfilePage(merchant: merchant),
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
            analyticsController: widget.analyticsController,
            toolsController: widget.toolsController,
            notificationsController: widget.notificationsController,
            helpCenterController: widget.helpCenterController,
            shortcutsController: widget.shortcutsController,
            engagementController: widget.engagementController,
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
                      analyticsController: widget.analyticsController,
                      toolsController: widget.toolsController,
                      notificationsController:
                          widget.notificationsController,
                      helpCenterController: widget.helpCenterController,
                      shortcutsController: widget.shortcutsController,
                      engagementController: widget.engagementController,
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

  Future<void> _maybeShowReleaseNotes() async {
    if (_releaseNotesShown ||
        !widget.engagementController.shouldShowReleaseNotes()) {
      return;
    }
    _releaseNotesShown = true;
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black45,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ReleaseNotesSheet(
          onDismissed: () => Navigator.of(context).pop(),
        );
      },
    );
    if (mounted) {
      await widget.engagementController.markReleaseNotesSeen();
    }
  }

  void _showQuickMenu(int index) {
    final tabId = ShortcutsController.tabs[index];
    final shortcuts = widget.shortcutsController.shortcutsFor(tabId);
    if (shortcuts.isEmpty) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuickShortcutSheet(
          shortcuts: shortcuts,
          onSelected: (shortcut) {
            Navigator.of(context).pop();
            _handleShortcut(shortcut);
          },
        );
      },
    );
  }

  void _handleShortcut(NavShortcutDefinition shortcut) {
    final target = shortcut.target;
    if (target.startsWith('switch:')) {
      switch (target) {
        case 'switch:insights':
          setState(() => _currentIndex = 1);
          break;
        case 'switch:budgets':
          setState(() => _currentIndex = 2);
          break;
        case 'switch:transactions':
          setState(() => _currentIndex = 3);
          break;
      }
      return;
    }
    if (target == 'show:contact') {
      _showContactSheet();
      return;
    }
    if (target.startsWith('/')) {
      Navigator.of(context).pushNamed(target);
    }
  }

  Future<void> _showContactSheet() async {
    final t = AppLocalizations.of(context);
    const email = 'support@mawaid.app';
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('contactSupportTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  t.translate('contactSupportBody'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(t.translate('contactCopyEmail')),
                  subtitle: Text(email),
                  onTap: () => Navigator.pop(context, 'copy'),
                ),
                ListTile(
                  leading: const Icon(Icons.outgoing_mail_rounded),
                  title: Text(t.translate('contactDraftMail')),
                  subtitle: Text(t.translate('contactDraftHint')),
                  onTap: () => Navigator.pop(context, 'draft'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case 'copy':
        await Clipboard.setData(const ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('contactEmailCopied'))),
        );
        break;
      case 'draft':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('contactDraftSaved'))),
        );
        break;
    }
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
    required this.analyticsController,
    required this.toolsController,
    required this.notificationsController,
    required this.helpCenterController,
    required this.shortcutsController,
    required this.engagementController,
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
  final AnalyticsController analyticsController;
  final ToolsController toolsController;
  final NotificationsController notificationsController;
  final HelpCenterController helpCenterController;
  final ShortcutsController shortcutsController;
  final EngagementController engagementController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();
  bool _releaseNotesShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowReleaseNotes();
    });
  }

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
        analyticsController: widget.analyticsController,
        onOpenInsights: () => setState(() => _currentIndex = 1),
        onOpenBudgets: () => setState(() => _currentIndex = 2),
        onOpenTransactions: () => setState(() => _currentIndex = 3),
      ),
      InsightsPage(
        key: const PageStorageKey('insights-page'),
        analyticsController: widget.analyticsController,
        sessionController: widget.sessionController,
      ),
      BudgetsPage(
        key: const PageStorageKey('budgets-page'),
        budgetsController: widget.budgetsController,
        privacyListenable: widget.sessionController.privacyModeNotifier,
        goalsController: widget.goalsController,
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
        toolsController: widget.toolsController,
        analyticsController: widget.analyticsController,
        notificationsController: widget.notificationsController,
        helpCenterController: widget.helpCenterController,
        shortcutsController: widget.shortcutsController,
        engagementController: widget.engagementController,
      ),
    ];

    return ValueListenableBuilder<Color>(
      valueListenable: widget.themeController.primaryColor,
      builder: (context, primary, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: widget.localeController.locale,
          builder: (context, locale, __) {
            return ValueListenableBuilder<List<AppNotificationModel>>(
              valueListenable: widget.notificationsController.notifications,
              builder: (context, notifications, ___) {
                final unread =
                    notifications.where((item) => !item.read).length;
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
                    onLongPress: _showQuickMenu,
                    primaryColor: primary,
                    locale: locale,
                    unreadCount: unread,
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

class _AnimatedBottomNav extends StatelessWidget {
  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.onLongPress,
    required this.primaryColor,
    required this.locale,
    required this.unreadCount,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onLongPress;
  final Color primaryColor;
  final Locale locale;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final labels = [
      t.translate('navHome'),
      t.translate('navInsights'),
      t.translate('navBudgets'),
      t.translate('navTransactions'),
      t.translate('navSettings'),
    ];
    final icons = const [
      Icons.dashboard_rounded,
      Icons.insights_rounded,
      Icons.account_balance_wallet_rounded,
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
                  onLongPress: () => onLongPress(index),
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              icons[index],
                              color: isActive
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            if (index == 0 && unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 9
                                        ? '9+'
                                        : unreadCount.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                          ],
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

class _QuickShortcutSheet extends StatelessWidget {
  const _QuickShortcutSheet({
    required this.shortcuts,
    required this.onSelected,
  });

  final List<NavShortcutDefinition> shortcuts;
  final ValueChanged<NavShortcutDefinition> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Material(
          color: theme.colorScheme.surface.withOpacity(0.95),
          elevation: 12,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('shortcutsSheetTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...shortcuts.map((shortcut) {
                  return ListTile(
                    leading: Icon(shortcut.icon),
                    title: Text(t.translate(shortcut.labelKey)),
                    onTap: () => onSelected(shortcut),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseNotesSheet extends StatelessWidget {
  const _ReleaseNotesSheet({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final notes = [
      t.translate('releaseNotesNotifications'),
      t.translate('releaseNotesHelpCenter'),
      t.translate('releaseNotesShortcuts'),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Material(
          color: theme.colorScheme.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(32),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('releaseNotesTitle',
                      params: {'version': AppConstants.currentVersion}),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ...notes.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    onPressed: onDismissed,
                    child: Text(t.translate('releaseNotesCTA')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
