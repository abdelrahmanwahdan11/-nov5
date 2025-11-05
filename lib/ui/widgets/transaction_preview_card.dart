import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/transaction.dart';
import 'sensitive_text.dart';

class TransactionPreviewCard extends StatelessWidget {
  const TransactionPreviewCard({
    super.key,
    required this.transaction,
    required this.privacyListenable,
  });

  final TransactionModel transaction;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isExpense = transaction.type == TransactionType.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(
              isExpense ? Icons.south_east_rounded : Icons.north_east_rounded,
              color: isExpense
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: transaction.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SensitiveText(
                privacyListenable: privacyListenable,
                visibleText:
                    '${isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isExpense ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 4),
              Text(
                t.translate(transaction.status.name),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
