import 'package:flutter/material.dart';

import '../../controllers/transactions_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final TextEditingController _searchController;
  TransactionsController? _controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = AppScope.of(context).transactionsController;
      _searchController.text = _controller!.query.value;
      _searchController.addListener(() {
        _controller!.query.value = _searchController.text;
      });
      _controller!.query.addListener(_syncSearchField);
    }
  }

  void _syncSearchField() {
    final query = _controller!.query.value;
    if (_searchController.text != query) {
      _searchController.value = _searchController.value.copyWith(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller?.query.removeListener(_syncSearchField);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).transactionsController;
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.translate('transactionsSearchHint'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    controller.query.value = '';
                  },
                ),
              ),
              onSubmitted: controller.updateHistory,
            ),
          ),
          ValueListenableBuilder<List<String>>(
            valueListenable: controller.history,
            builder: (context, history, _) {
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final term = history[index];
                    return ActionChip(
                      label: Text(term),
                      onPressed: () {
                        _searchController.text = term;
                        controller.query.value = term;
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: history.length,
                ),
              );
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final transactions = controller.filteredTransactions;
                if (transactions.isEmpty) {
                  return Center(child: Text(l10n.translate('transactionsEmpty')));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
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
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
