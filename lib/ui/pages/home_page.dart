import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/budgets_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_timeline.dart';
import '../widgets/budget_card.dart';
import '../widgets/transaction_preview_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.transactionsController,
    required this.budgetsController,
    required this.searchController,
    required this.onOpenBudgets,
    required this.onOpenTransactions,
  });

  final TransactionsController transactionsController;
  final BudgetsController budgetsController;
  final SearchController searchController;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenTransactions;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchFieldController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFieldController.text = widget.searchController.currentQuery;
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    widget.transactionsController.applyQuery(query);
    widget.searchController.addToHistory(query);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient(brightness),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('homeGreeting'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        t.translate('homeSubtitle'),
                        style: theme.textTheme.bodyMedium,
                      )
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.2, end: 0),
                      const Spacer(),
                      _SearchBar(
                        controller: widget.searchController,
                        transactionsController: widget.transactionsController,
                        textController: _searchFieldController,
                        focusNode: _searchFocusNode,
                        onSubmitted: _handleSearch,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.translate('budgetsOverview'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onOpenBudgets,
                      child: Text(t.translate('viewAll')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<BudgetModel>>(
                  valueListenable: widget.budgetsController.budgetsNotifier,
                  builder: (context, budgets, _) {
                    if (budgets.isEmpty) {
                      return _EmptyState(
                        message: t.translate('noBudgets'),
                      );
                    }
                    return SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final budget = budgets[index];
                          return BudgetCard(budget: budget)
                              .animate(delay: (index * 80).ms)
                              .fadeIn(duration: 320.ms)
                              .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
                        },
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemCount: budgets.length,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.translate('recentActivity'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onOpenTransactions,
                      child: Text(t.translate('viewAll')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<TransactionTimelineSection>>(
                  valueListenable:
                      widget.transactionsController.timelineNotifier,
                  builder: (context, sections, _) {
                    if (sections.isEmpty) {
                      return const _SkeletonTransactions();
                    }
                    final preview = sections.take(2).toList();
                    return Column(
                      children: [
                        for (final section in preview)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      section.label,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${t.translate('totalShort')} ${section.total.toStringAsFixed(0)}',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...section.transactions.take(3).map(
                                  (tx) => TransactionPreviewCard(
                                    transaction: tx,
                                  )
                                      .animate()
                                      .fadeIn(duration: 280.ms)
                                      .slideY(begin: 0.2, end: 0),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.transactionsController,
    required this.textController,
    required this.focusNode,
    required this.onSubmitted,
  });

  final SearchController controller;
  final TransactionsController transactionsController;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.textController,
                    focusNode: widget.focusNode,
                    onChanged: widget.controller.updateQuery,
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(
                      hintText: t.translate('searchPlaceholder'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.translate('clear'),
                  onPressed: () {
                    widget.textController.clear();
                    widget.controller.updateQuery('');
                    widget.transactionsController.applyQuery(null);
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: widget.controller.suggestions,
          builder: (context, suggestions, _) {
            if (suggestions.isEmpty) {
              return const SizedBox.shrink();
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return ListTile(
                    onTap: () {
                      widget.textController.text = item;
                      widget.controller.updateQuery(item);
                      widget.onSubmitted(item);
                      widget.focusNode.unfocus();
                    },
                    leading: const Icon(Icons.history_toggle_off_rounded),
                    title: Text(item),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: suggestions.length,
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              t.translate('recentSearches'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.controller.clearHistory,
              child: Text(t.translate('clear')),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<List<String>>(
          valueListenable: widget.controller.historyNotifier,
          builder: (context, history, _) {
            if (history.isEmpty) {
              return Text(
                t.translate('noSearchHistory'),
                style: theme.textTheme.bodySmall,
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () {
                        widget.textController.text = item;
                        widget.controller.updateQuery(item);
                        widget.onSubmitted(item);
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SkeletonTransactions extends StatelessWidget {
  const _SkeletonTransactions();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4);
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(18),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms);
      }),
    );
  }
}
