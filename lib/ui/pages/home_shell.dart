import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import 'budgets_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'transactions_page.dart';
import 'wallets_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static _HomeShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeShellState>();
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _bucket = PageStorageBucket();
  int _index = 0;

  void setIndex(int value) {
    setState(() => _index = value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  void _maybeShowTutorial() {
    final session = AppScope.of(context).sessionController;
    if (session.tutorialSeen.value) return;
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('tutorialTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ${l10n.translate('tutorialHome')}'),
              Text('• ${l10n.translate('tutorialWallets')}'),
              Text('• ${l10n.translate('tutorialTransactions')}'),
              Text('• ${l10n.translate('tutorialSettings')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('sessionContinue')),
            ),
          ],
        );
      },
    ).then((_) => session.markTutorialSeen());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = const [
      HomePage(),
      WalletsPage(),
      TransactionsPage(),
      BudgetsPage(),
      SettingsPage(),
    ];
    final destinations = [
      {'icon': Icons.home, 'label': l10n.translate('homeTitle')},
      {'icon': Icons.credit_card, 'label': l10n.translate('walletsTitle')},
      {'icon': Icons.swap_horiz, 'label': l10n.translate('transactionsTitle')},
      {'icon': Icons.pie_chart, 'label': l10n.translate('budgetsTitle')},
      {'icon': Icons.settings, 'label': l10n.translate('settingsTitle')},
    ];
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: setIndex,
        destinations: destinations
            .map(
              (entry) => NavigationDestination(
                icon: Icon(entry['icon'] as IconData),
                label: entry['label'] as String,
              ),
            )
            .toList(),
      ),
    );
  }
}
