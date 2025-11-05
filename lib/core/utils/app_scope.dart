import 'package:flutter/widgets.dart';

import '../../controllers/budgets_controller.dart';
import '../../controllers/display_controller.dart';
import '../../controllers/goals_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/recipients_controller.dart';
import '../../controllers/recurring_payments_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../controllers/wallet_controller.dart';

class AppScope extends InheritedWidget {
  const AppScope({
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
    required super.child,
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

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return oldWidget.themeController != themeController ||
        oldWidget.localeController != localeController ||
        oldWidget.transactionsController != transactionsController ||
        oldWidget.searchController != searchController ||
        oldWidget.budgetsController != budgetsController ||
        oldWidget.sessionController != sessionController ||
        oldWidget.profileController != profileController ||
        oldWidget.walletController != walletController ||
        oldWidget.displayController != displayController ||
        oldWidget.goalsController != goalsController ||
        oldWidget.recipientsController != recipientsController ||
        oldWidget.recurringPaymentsController != recurringPaymentsController;
  }
}
