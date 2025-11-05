import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../controllers/display_controller.dart';
import '../../data/models/budget.dart';
import 'sensitive_text.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.privacyListenable,
  });

  final BudgetModel budget;
  final ValueListenable<bool> privacyListenable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isOver = budget.spent > budget.limit;
    final accent = Color(budget.color);
    final displayController = AppScope.of(context).displayController;

    return ValueListenableBuilder<CardSurfaceStyle>(
      valueListenable: displayController.cardStyle,
      builder: (context, style, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: displayController.reduceMotionNotifier,
          builder: (context, reduceMotion, __) {
            Widget warningIcon = const SizedBox.shrink();
            if (isOver) {
              warningIcon = Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
              );
              if (!reduceMotion) {
                warningIcon = warningIcon
                    .animate()
                    .shakeY(duration: 600.ms, amount: 6);
              }
            }

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent,
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
                    warningIcon,
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t.translate('spent'),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                SensitiveText(
                  privacyListenable: privacyListenable,
                  visibleText:
                      '${budget.spent.toStringAsFixed(0)} / ${budget.limit.toStringAsFixed(0)}',
                  hiddenText: '•••• / ••••',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: budget.progress.clamp(0, 1),
                    backgroundColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                const SizedBox(height: 12),
                SensitiveText(
                  privacyListenable: privacyListenable,
                  visibleText: budget.remaining >= 0
                      ? '${t.translate('remaining')} ${budget.remaining.toStringAsFixed(0)}'
                      : t.translate('overBudget'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: budget.remaining >= 0
                        ? theme.textTheme.bodySmall?.color ??
                            theme.colorScheme.onSurface
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            );

            final decoration = _budgetDecoration(theme, style, accent);
            final radius = BorderRadius.circular(24);

            Widget card = Container(
              width: 240,
              padding: const EdgeInsets.all(20),
              decoration: decoration,
              child: content,
            );

            if (style == CardSurfaceStyle.glass) {
              card = ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: card,
                ),
              );
            }

            if (!reduceMotion) {
              card = card
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.1, end: 0);
            }

            return card;
          },
        );
      },
    );
  }
}

BoxDecoration _budgetDecoration(
  ThemeData theme,
  CardSurfaceStyle style,
  Color accent,
) {
  final radius = BorderRadius.circular(24);
  switch (style) {
    case CardSurfaceStyle.glass:
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.22),
            theme.colorScheme.surface.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      );
    case CardSurfaceStyle.solid:
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );
    case CardSurfaceStyle.subtle:
      return BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: radius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      );
  }
}
