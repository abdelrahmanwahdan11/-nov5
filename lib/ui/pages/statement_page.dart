import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/analytics_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/analytics.dart';
import '../../data/models/transaction.dart';
import '../widgets/sensitive_text.dart';
import '../widgets/transaction_preview_card.dart';

class StatementPage extends StatelessWidget {
  const StatementPage({
    super.key,
    required this.analyticsController,
    required this.sessionController,
  });

  final AnalyticsController analyticsController;
  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('statementTitle')),
        actions: [
          IconButton(
            tooltip: t.translate('statementCopyJson'),
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () async {
              final statement = analyticsController.statementNotifier.value;
              await Clipboard.setData(
                ClipboardData(
                  text: const JsonEncoder.withIndent('  ')
                      .convert(statement.toSerializableMap()),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.translate('statementCopied'))),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<DateTime>>(
        valueListenable: analyticsController.availableMonthsNotifier,
        builder: (context, months, _) {
          return ValueListenableBuilder<DateTime>(
            valueListenable: analyticsController.statementMonthNotifier,
            builder: (context, selected, __) {
              return ValueListenableBuilder<StatementDocument>(
                valueListenable: analyticsController.statementNotifier,
                builder: (context, statement, ___) {
                  final transactions = statement.transactions;
                  final monthLabel =
                      '${statement.month.year}-${statement.month.month.toString().padLeft(2, '0')}';
                  return ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.translate('statementHeadline',
                                  params: {'month': monthLabel}),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DropdownButton<DateTime>(
                            value: selected,
                            items: [
                              for (final month in months)
                                DropdownMenuItem(
                                  value: month,
                                  child: Text(
                                    '${month.year}-${month.month.toString().padLeft(2, '0')}',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                analyticsController.selectStatementMonth(value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _StatementSummary(
                        statement: statement,
                        privacyListenable: sessionController.privacyModeNotifier,
                        t: t,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t.translate('statementTransactions'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (transactions.isEmpty)
                        Text(t.translate('statementEmpty'))
                      else
                        ...transactions.map(
                          (tx) => TransactionPreviewCard(
                            transaction: tx,
                            privacyListenable:
                                sessionController.privacyModeNotifier,
                          )
                              .animate()
                              .fadeIn(duration: 260.ms)
                              .slideY(begin: 0.1, end: 0),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatementSummary extends StatelessWidget {
  const _StatementSummary({
    required this.statement,
    required this.privacyListenable,
    required this.t,
  });

  final StatementDocument statement;
  final ValueListenable<bool> privacyListenable;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = statement.categoryTotals;
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: t.translate('analyticsIncomeLabel'),
                    value: statement.totalIncome,
                    privacyListenable: privacyListenable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBlock(
                    label: t.translate('analyticsExpenseLabel'),
                    value: statement.totalExpense,
                    privacyListenable: privacyListenable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBlock(
                    label: t.translate('analyticsNetLabel'),
                    value: statement.net,
                    privacyListenable: privacyListenable,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('statementTopCategories'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (sortedCategories.isEmpty)
              Text(t.translate('analyticsEmptyCategories'))
            else
              Column(
                children: [
                  for (final entry in sortedCategories.take(4))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(entry.key.isEmpty
                            ? '?'
                            : entry.key.substring(0, 1)),
                      ),
                      title: Text(entry.key),
                      trailing: SensitiveText(
                        privacyListenable: privacyListenable,
                        visibleText: entry.value.toStringAsFixed(0),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.privacyListenable,
  });

  final String label;
  final double value;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        SensitiveText(
          privacyListenable: privacyListenable,
          visibleText: value.toStringAsFixed(0),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
