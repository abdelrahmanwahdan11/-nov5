import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/budget.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget});

  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isOver = budget.spent > budget.limit;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(budget.color),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  budget.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isOver)
                Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.error)
                    .animate()
                    .shakeY(duration: 600.ms),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${t.translate('spent')} ${budget.spent.toStringAsFixed(0)} / ${budget.limit.toStringAsFixed(0)}',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: budget.progress.clamp(0, 1),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation(Color(budget.color)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            budget.remaining >= 0
                ? '${t.translate('remaining')} ${budget.remaining.toStringAsFixed(0)}'
                : t.translate('overBudget'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: budget.remaining >= 0
                  ? theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
