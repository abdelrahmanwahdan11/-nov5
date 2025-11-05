import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/recurring_payments_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/recurring_payment.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_timeline.dart';
import '../widgets/sensitive_text.dart';
import '../widgets/sticky_header_delegate.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.transactionsController,
    required this.searchController,
    required this.privacyListenable,
    required this.recurringPaymentsController,
  });

  final TransactionsController transactionsController;
  final SearchController searchController;
  final ValueListenable<bool> privacyListenable;
  final RecurringPaymentsController recurringPaymentsController;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchController.currentQuery,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    widget.transactionsController.applyQuery(query);
    widget.searchController.addToHistory(query);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.transactionsController.selectedTransactions,
      builder: (context, selected, _) {
        final isSelecting = selected.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              isSelecting
                  ? t.translate('selectedCount',
                      params: {'count': selected.length.toString()})
                  : t.translate('transactionsTitle'),
            ),
            leading: isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: widget.transactionsController.clearSelection,
                  )
                : null,
          ),
          body: Stack(
            children: [
              _buildTimeline(isSelecting, selected),
              if (isSelecting)
                _SelectionActionBar(
                  count: selected.length,
                  onArchive: () => _bulkArchive(selected),
                  onTag: () => _bulkTag(selected),
                  onCancel: widget.transactionsController.clearSelection,
                ),
            ],
          ),
          floatingActionButton:
              ValueListenableBuilder<List<TransactionsUndoEntry>>(
            valueListenable: widget.transactionsController.undoHistory,
            builder: (context, stack, __) {
              if (stack.isEmpty) {
                return const SizedBox.shrink();
              }
              final last = stack.first;
              final label = last.type == TransactionsActionType.archive
                  ? t.translate('undoArchiveLabel',
                      params: {'count': last.before.length.toString()})
                  : t.translate('undoTagLabel',
                      params: {'count': last.before.length.toString()});
              return FloatingActionButton.extended(
                onPressed: _undoLastAction,
                icon: const Icon(Icons.undo_rounded),
                label: Text(label),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeline(bool isSelecting, Set<String> selected) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: widget.transactionsController.isLoading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<TransactionTimelineSection>>(
          valueListenable: widget.transactionsController.timelineNotifier,
          builder: (context, sections, __) {
            return RefreshIndicator(
              onRefresh: widget.transactionsController.refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 280) {
                    widget.transactionsController.loadMore();
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SearchField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              onChanged: widget.searchController.updateQuery,
                              onSubmitted: _onSearch,
                              searchController: widget.searchController,
                              transactionsController: widget.transactionsController,
                            ),
                            const SizedBox(height: 12),
                            _CategoryFilterBar(
                              controller: widget.transactionsController,
                            ),
                            const SizedBox(height: 12),
                            _TagFilterWrap(controller: widget.transactionsController),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder<List<RecurringPaymentModel>>(
                        valueListenable:
                            widget.recurringPaymentsController.paymentsNotifier,
                        builder: (context, payments, __) {
                          if (payments.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            child: _RecurringSection(
                              payments: payments,
                              onExecute: _handleExecuteRecurring,
                              onSkip: _handleSkipRecurring,
                            ),
                          );
                        },
                      ),
                    ),
                    if (sections.isEmpty && isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: _TransactionsSkeleton(),
                        ),
                      ),
                    if (sections.isEmpty && !isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 60),
                          child: _EmptyTimeline(
                            message: t.translate('noTransactionsFound'),
                          ),
                        ),
                      ),
                    ...sections.asMap().entries.expand((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: StickyHeaderDelegate(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    section.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SensitiveText(
                                      privacyListenable:
                                          widget.privacyListenable,
                                      visibleText:
                                          '${t.translate('totalShort')} ${section.total.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, txIndex) {
                                final tx = section.transactions[txIndex];
                                final isSelected = selected.contains(tx.id);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: txIndex == section.transactions.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: _TransactionTile(
                                    transaction: tx,
                                    onAction: _handleArchive,
                                    privacyListenable: widget.privacyListenable,
                                    onToggleSelection: () => _toggleSelection(tx),
                                    selectionMode: isSelecting,
                                    isSelected: isSelected,
                                  )
                                      .animate(
                                        delay: (index * 50 + txIndex * 30).ms,
                                      )
                                      .fadeIn(duration: 260.ms)
                                      .slideY(begin: 0.15, end: 0),
                                );
                              },
                              childCount: section.transactions.length,
                            ),
                          ),
                        ),
                      ];
                    }),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator.adaptive()
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleSelection(TransactionModel tx) {
    HapticFeedback.selectionClick();
    widget.transactionsController.toggleSelection(tx.id);
  }

  Future<void> _bulkArchive(Set<String> selected) async {
    if (selected.isEmpty) return;
    await widget.transactionsController.bulkArchive(selected);
    widget.searchController
        .rebuildSource(widget.transactionsController.allTransactions);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.translate('bulkArchived', params: {'count': selected.length.toString()}),
        ),
      ),
    );
  }

  Future<void> _bulkTag(Set<String> selected) async {
    if (selected.isEmpty) return;
    await widget.transactionsController.bulkApplyTag(selected, 'focus');
    widget.searchController
        .rebuildSource(widget.transactionsController.allTransactions);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.translate('bulkTagged', params: {'count': selected.length.toString()}),
        ),
      ),
    );
  }

  Future<void> _undoLastAction() async {
    await widget.transactionsController.undoLastAction();
    widget.searchController
        .rebuildSource(widget.transactionsController.allTransactions);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.translate('undoApplied'))),
    );
  }

  Future<void> _handleExecuteRecurring(RecurringPaymentModel payment) async {
    final tx = await widget.recurringPaymentsController.execute(payment.id);
    if (tx == null) return;
    await widget.transactionsController.addManualTransaction(tx);
    widget.searchController
        .rebuildSource(widget.transactionsController.allTransactions);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.translate('recurringExecuted', params: {'title': payment.title}),
        ),
      ),
    );
  }

  Future<void> _handleSkipRecurring(RecurringPaymentModel payment) async {
    await widget.recurringPaymentsController.postpone(payment.id);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.translate('recurringDeferred', params: {'title': payment.title}),
        ),
      ),
    );
  }

  Future<bool> _handleArchive(TransactionModel tx, DismissDirection direction) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    if (direction == DismissDirection.startToEnd) {
      final updated = await widget.transactionsController.categorizeTransaction(tx);
      widget.searchController
          .rebuildSource(widget.transactionsController.allTransactions);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${t.translate('categorized')} • ${updated.title}'),
          action: SnackBarAction(
            label: t.translate('undo'),
            onPressed: () => widget.transactionsController.updateTransaction(tx),
          ),
        ),
      );
      return false;
    } else {
      await widget.transactionsController.archiveTransaction(tx);
      widget.searchController
          .rebuildSource(widget.transactionsController.allTransactions);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${t.translate('archived')} • ${tx.title}'),
          action: SnackBarAction(
            label: t.translate('undo'),
            onPressed: () => widget.transactionsController.restoreTransaction(tx),
          ),
        ),
      );
      return true;
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.searchController,
    required this.transactionsController,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final SearchController searchController;
  final TransactionsController transactionsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: t.translate('searchTransactions'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    transactionsController.applyQuery(null);
                    focusNode.unfocus();
                  },
                  tooltip: t.translate('clear'),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: searchController.suggestions,
          builder: (context, suggestions, _) {
            if (suggestions.isEmpty) {
              return const SizedBox.shrink();
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.history_toggle_off_rounded),
                    title: Text(suggestion),
                    onTap: () {
                      controller.text = suggestion;
                      onChanged(suggestion);
                      onSubmitted(suggestion);
                      focusNode.unfocus();
                    },
                  );
                },
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
          },
        ),
      ],
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categories = controller.categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<String?>(
      valueListenable: controller.categoryFilter,
      builder: (context, selected, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(t.translate('allCategories')),
                  selected: selected == null,
                  onSelected: (_) => controller.selectCategory(null),
                ),
              ),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: selected == category,
                    onSelected: (_) => controller.selectCategory(
                      selected == category ? null : category,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagFilterWrap extends StatelessWidget {
  const _TagFilterWrap({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    final tags = controller.availableTags.toList()..sort();
    final t = AppLocalizations.of(context);

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.tagFilters,
      builder: (context, selected, _) {
        if (selected.isNotEmpty || tags.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.translate('tags'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: controller.clearTags,
                      child: Text(t.translate('clear')),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    FilterChip(
                      label: Text('#$tag'),
                      selected: selected.contains(tag),
                      onSelected: (_) => controller.toggleTag(tag),
                    ),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onAction,
    required this.privacyListenable,
    required this.onToggleSelection,
    required this.selectionMode,
    required this.isSelected,
  });

  final TransactionModel transaction;
  final Future<bool> Function(TransactionModel tx, DismissDirection direction)
      onAction;
  final ValueListenable<bool> privacyListenable;
  final VoidCallback onToggleSelection;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;

    return GestureDetector(
      onLongPress: onToggleSelection,
      onTap: () {
        if (selectionMode) {
          onToggleSelection();
        }
      },
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction:
            selectionMode ? DismissDirection.none : DismissDirection.horizontal,
        background: _DismissBackground(
          color: theme.colorScheme.secondaryContainer,
          icon: Icons.sell_rounded,
          alignment: Alignment.centerLeft,
          text: AppLocalizations.of(context).translate('categorize'),
        ),
        secondaryBackground: _DismissBackground(
          color: theme.colorScheme.errorContainer,
          icon: Icons.archive_rounded,
          alignment: Alignment.centerRight,
          text: AppLocalizations.of(context).translate('archive'),
        ),
        confirmDismiss: (direction) => onAction(transaction, direction),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.6)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: selectionMode
                        ? Container(
                            key: const ValueKey('select'),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          )
                        : CircleAvatar(
                            key: const ValueKey('icon'),
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.12),
                            child: Icon(
                              isExpense
                                  ? Icons.south_east_rounded
                                  : Icons.north_east_rounded,
                              color: isExpense
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        transaction.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.description,
                        style: theme.textTheme.bodySmall,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isExpense
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.merchant,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(transaction.category),
                ),
                ...transaction.tags.map(
                  (tag) => Chip(
                    label: Text('#$tag'),
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

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.count,
    required this.onArchive,
    required this.onTag,
    required this.onCancel,
  });

  final int count;
  final VoidCallback onArchive;
  final VoidCallback onTag;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('selectionActive',
                        params: {'count': count.toString()}),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onArchive,
                          icon: const Icon(Icons.archive_outlined),
                          label: Text(t.translate('bulkArchive')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onTag,
                          icon: const Icon(Icons.sell_outlined),
                          label: Text(t.translate('bulkTag')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: t.translate('cancel'),
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringSection extends StatelessWidget {
  const _RecurringSection({
    required this.payments,
    required this.onExecute,
    required this.onSkip,
  });

  final List<RecurringPaymentModel> payments;
  final void Function(RecurringPaymentModel payment) onExecute;
  final void Function(RecurringPaymentModel payment) onSkip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.translate('recurringTitle'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              t.translate('recurringHint'),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _RecurringCard(
                payment: payment,
                onExecute: () => onExecute(payment),
                onSkip: () => onSkip(payment),
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn(duration: 280.ms)
                  .slideX(
                    begin: Directionality.of(context) == TextDirection.ltr
                        ? 0.12
                        : -0.12,
                    end: 0,
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.payment,
    required this.onExecute,
    required this.onSkip,
  });

  final RecurringPaymentModel payment;
  final VoidCallback onExecute;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final next =
        '${payment.nextDate.month.toString().padLeft(2, '0')}/${payment.nextDate.day.toString().padLeft(2, '0')}';
    final frequencyLabel = t.translate('frequency_${payment.frequency.name}');

    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Color(payment.color).withOpacity(0.9),
            Color(payment.color).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            payment.recipient,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.translate('recurringNext', params: {'date': next}),
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const Spacer(),
          Text(
            frequencyLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onExecute,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(t.translate('executeNow')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: t.translate('skip'),
                onPressed: onSkip,
                icon: const Icon(Icons.snooze_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4);
    return Column(
      children: List.generate(4, (index) {
        return Container(
          height: 120,
          margin: EdgeInsets.only(bottom: index == 3 ? 0 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: baseColor,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms);
      }),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.inbox_rounded, size: 88, color: theme.disabledColor),
        const SizedBox(height: 16),
        Text(
          message,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
