import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/budgets_controller.dart';
import 'controllers/display_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/transactions_controller.dart';
import 'controllers/wallet_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final themeController = await ThemeController.load();
  final localeController = await LocaleController.load();
  final sessionController = await SessionController.load();
  final walletController = await WalletController.load();
  final budgetsController = await BudgetsController.load();
  final transactionsController = await TransactionsController.load();
  final profileController = await ProfileController.load();
  final displayController = await DisplayController.load();

  runApp(MawaidApp(
    themeController: themeController,
    localeController: localeController,
    sessionController: sessionController,
    walletController: walletController,
    budgetsController: budgetsController,
    transactionsController: transactionsController,
    profileController: profileController,
    displayController: displayController,
  ));
}

class MawaidApp extends StatefulWidget {
  const MawaidApp({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.sessionController,
    required this.walletController,
    required this.budgetsController,
    required this.transactionsController,
    required this.profileController,
    required this.displayController,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final SessionController sessionController;
  final WalletController walletController;
  final BudgetsController budgetsController;
  final TransactionsController transactionsController;
  final ProfileController profileController;
  final DisplayController displayController;

  @override
  State<MawaidApp> createState() => _MawaidAppState();
}

class _MawaidAppState extends State<MawaidApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.sessionController.entryState.addListener(_handleEntryState);
  }

  @override
  void dispose() {
    widget.sessionController.entryState.removeListener(_handleEntryState);
    widget.sessionController.dispose();
    widget.themeController.dispose();
    widget.localeController.dispose();
    widget.walletController.dispose();
    widget.budgetsController.dispose();
    widget.transactionsController.dispose();
    widget.profileController.dispose();
    widget.displayController.dispose();
    super.dispose();
  }

  void _handleEntryState() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    final route = AppRouter.routeForEntry(widget.sessionController.entryState.value);
    navigator.pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: widget.themeController.primaryColor,
      builder: (context, color, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: widget.themeController.themeMode,
          builder: (context, mode, __) {
            return ValueListenableBuilder<Locale>(
              valueListenable: widget.localeController.locale,
              builder: (context, locale, ___) {
                final initialRoute =
                    AppRouter.routeForEntry(widget.sessionController.entryState.value);
                return AppScope(
                  themeController: widget.themeController,
                  localeController: widget.localeController,
                  sessionController: widget.sessionController,
                  walletController: widget.walletController,
                  budgetsController: widget.budgetsController,
                  transactionsController: widget.transactionsController,
                  profileController: widget.profileController,
                  displayController: widget.displayController,
                  child: MaterialApp(
                    navigatorKey: _navigatorKey,
                    debugShowCheckedModeBanner: false,
                    title: 'Mawaid',
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    onGenerateRoute: AppRouter.onGenerate,
                    initialRoute: initialRoute,
                    theme: AppTheme.light(color),
                    darkTheme: AppTheme.dark(color),
                    themeMode: mode,
                    builder: (context, child) {
                      final direction = locale.languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr;
                      return Directionality(
                        textDirection: direction,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: child,
                        ),
                      );
                    },
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
