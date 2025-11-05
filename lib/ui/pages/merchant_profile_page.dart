import 'package:flutter/material.dart';

import '../../controllers/transactions_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../data/models/transaction.dart';
import '../widgets/sensitive_text.dart';

class MerchantProfilePage extends StatelessWidget {
  const MerchantProfilePage({super.key, required this.merchant});

  final String merchant;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final transactionsController = scope.transactionsController;
    final privacyListenable = scope.sessionController.privacyModeNotifier;
    final transactions = transactionsController.allTransactions
        .where((tx) => tx.merchant == merchant)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final t = AppLocalizations.of(context);

    if (transactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.translate('merchantProfileTitle', params: {'merchant': merchant}),
          ),
        ),
        body: Center(
          child: Text(t.translate('noTransactionsFound')),
        ),
      );
    }

    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final totalSpend = expenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    final averageSpend = expenses.isEmpty ? 0 : totalSpend / expenses.length;

    final categoryCounts = <String, int>{};
    final tagCounts = <String, int>{};
    for (final tx in transactions) {
      categoryCounts.update(tx.category, (value) => value + 1, ifAbsent: () => 1);
      for (final tag in tx.tags) {
        tagCounts.update(tag, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.translate('merchantProfileTitle', params: {'merchant': merchant}),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          _MerchantHeader(
            merchant: merchant,
            averageSpend: averageSpend,
            count: transactions.length,
            privacyListenable: privacyListenable,
          ),
          const SizedBox(height: 24),
          Text(
            t.translate('merchantTopCategories'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in topCategories.take(6))
                Chip(
                  label: Text('${entry.key} • ${entry.value}'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t.translate('merchantTags'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in topTags.take(8))
                Chip(
                  label: Text('#${entry.key} • ${entry.value}'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t.translate('merchantRecentActivity'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...transactions.take(8).map(
            (tx) => _MerchantTransactionTile(
              transaction: tx,
              privacyListenable: privacyListenable,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantHeader extends StatelessWidget {
  const _MerchantHeader({
    required this.merchant,
    required this.averageSpend,
    required this.count,
    required this.privacyListenable,
  });

  final String merchant;
  final double averageSpend;
  final int count;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchant,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('merchantAverageSpend'),
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SensitiveText(
                      privacyListenable: privacyListenable,
                      visibleText: averageSpend.toStringAsFixed(2),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('merchantTransactionsCount',
                          params: {'count': count.toString()}),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MerchantTransactionTile extends StatelessWidget {
  const _MerchantTransactionTile({
    required this.transaction,
    required this.privacyListenable,
  });

  final TransactionModel transaction;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final isExpense = transaction.type == TransactionType.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transaction.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SensitiveText(
                privacyListenable: privacyListenable,
                visibleText:
                    '${isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      isExpense ? theme.colorScheme.error : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            localizations.formatMediumDate(transaction.date),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            transaction.description,
            style: theme.textTheme.bodyMedium,
          ),
          if ((transaction.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              transaction.note!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
