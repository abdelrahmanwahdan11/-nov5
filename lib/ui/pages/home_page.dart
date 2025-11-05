import 'package:flutter/material.dart';

import '../../controllers/display_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet_card.dart';
import '../widgets/wallet_card_view.dart';
import 'home_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final Set<String> _flippedCards = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    final session = scope.sessionController;
    final walletController = scope.walletController;
    final displayController = scope.displayController;
    final transactionsController = scope.transactionsController;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ValueListenableBuilder<String>(
              valueListenable: session.displayName,
              builder: (context, name, _) {
                final greeting = l10n.translate('homeHello', params: {'name': name});
                return Text(greeting, style: Theme.of(context).textTheme.headlineMedium);
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.translate('homeBalances'),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ValueListenableBuilder<List<WalletCardModel>>(
              valueListenable: walletController.cards,
              builder: (context, cards, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: walletController.primaryCardId,
                  builder: (context, primaryId, __) {
                    return ValueListenableBuilder<CardSurfaceStyle>(
                      valueListenable: displayController.surfaceStyle,
                      builder: (context, style, ___) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: session.privacyMode,
                          builder: (context, privacy, ____) {
                            return PageView.builder(
                              controller: _pageController,
                              itemCount: cards.length + 1,
                              itemBuilder: (context, index) {
                                if (index == cards.length) {
                                  return _AddCardButton(onPressed: () => _showAddCardDialog(context));
                                }
                                final card = cards[index];
                                final isFlipped = _flippedCards.contains(card.id);
                                final isPrimary = primaryId == card.id;
                                return AnimatedPadding(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: WalletCardView(
                                    card: card,
                                    flipped: isFlipped,
                                    isPrimary: isPrimary,
                                    privacyMode: privacy,
                                    surfaceStyle: style,
                                    primaryLabel: l10n.translate('walletPrimary'),
                                    onToggle: () {
                                      setState(() {
                                        if (isFlipped) {
                                          _flippedCards.remove(card.id);
                                        } else {
                                          _flippedCards.add(card.id);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChip(
                  label: Text(l10n.translate('homeAddCard')),
                  avatar: const Icon(Icons.add),
                  onPressed: () => _showAddCardDialog(context),
                ),
                ActionChip(
                  label: Text(l10n.translate('transactionsFilter')),
                  avatar: const Icon(Icons.filter_list),
                  onPressed: () => HomeShell.of(context)?.setIndex(2),
                ),
                ActionChip(
                  label: Text(l10n.translate('budgetsTitle')),
                  avatar: const Icon(Icons.pie_chart_outline),
                  onPressed: () => HomeShell.of(context)?.setIndex(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.translate('transactionsTitle'),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          AnimatedBuilder(
            animation: transactionsController,
            builder: (context, _) {
              final transactions =
                  transactionsController.filteredTransactions.take(3).toList();
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.translate('transactionsEmpty')),
                );
              }
              return Column(
                children: transactions
                    .map((transaction) => _TransactionTile(transaction: transaction))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    final labelController = TextEditingController();
    final numberController = TextEditingController();
    final balanceController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('walletAddTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: l10n.translate('walletLabel')),
              ),
              TextField(
                controller: numberController,
                decoration: InputDecoration(labelText: l10n.translate('walletNumber')),
              ),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(labelText: l10n.translate('walletBalance')),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: currencyController,
                decoration: InputDecoration(labelText: l10n.translate('walletCurrency')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('walletCancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final balance = double.tryParse(balanceController.text) ?? 0;
                scope.walletController.addCard(
                  WalletCardModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: labelController.text.isEmpty
                        ? l10n.translate('walletLabel')
                        : labelController.text,
                    number: numberController.text.isEmpty
                        ? '0000 **** ****'
                        : numberController.text,
                    balance: balance,
                    currency: currencyController.text,
                    colors: const [Color(0xFF2BAA7D), Color(0xFF16302B)],
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.translate('walletSave')),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final amountPrefix = transaction.isExpense ? '-' : '+';
    final amountColor = transaction.isExpense
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: CircleAvatar(child: Text(transaction.title.characters.first)),
      title: Text(transaction.title),
      subtitle: Text(transaction.category),
      trailing: Text(
        '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.translate('homeAddCard')),
      ),
    );
  }
}
