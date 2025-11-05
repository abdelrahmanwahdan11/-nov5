import 'package:flutter/widgets.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../controllers/budgets_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/display_controller.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.sessionController,
    required this.transactionsController,
    required this.walletController,
    required this.budgetsController,
    required this.profileController,
    required this.displayController,
    required super.child,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final SessionController sessionController;
  final TransactionsController transactionsController;
  final WalletController walletController;
  final BudgetsController budgetsController;
  final ProfileController profileController;
  final DisplayController displayController;

  static AppScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(result != null, 'AppScope not found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return themeController != oldWidget.themeController ||
        localeController != oldWidget.localeController ||
        sessionController != oldWidget.sessionController ||
        transactionsController != oldWidget.transactionsController ||
        walletController != oldWidget.walletController ||
        budgetsController != oldWidget.budgetsController ||
        profileController != oldWidget.profileController ||
        displayController != oldWidget.displayController;
  }
}
