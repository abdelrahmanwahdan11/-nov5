import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/recurring_payments_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../data/models/recurring_payment.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_filter_definition.dart';
import '../../data/models/transaction_timeline.dart';
import '../widgets/sensitive_text.dart';
import '../widgets/sticky_header_delegate.dart';

typedef _FilterComposerLauncher = Future<void> Function({TransactionFilterDefinition? definition});

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
            actions: isSelecting
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.print_rounded),
                      tooltip: t.translate('statementTitle'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRouter.statement);
                      },
                    ),
                  ],
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
                            const SizedBox(height: 16),
                            _SavedFiltersPanel(
                              controller: widget.transactionsController,
                              onCompose: _openFilterComposer,
                            ),
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
                    Tooltip(
                      message: t.translate('viewMerchantProfile'),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.merchantProfile,
                            arguments: transaction.merchant,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            transaction.merchant,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
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
            if ((transaction.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                t.translate('noteLabel'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              _NoteBubble(note: transaction.note!),
            ],
            if (transaction.attachmentUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                t.translate('attachmentLabel'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              _AttachmentPreview(
                url: transaction.attachmentUrl!,
                tooltip: t.translate('viewAttachment'),
              ),
            ],
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


class _SavedFiltersPanel extends StatelessWidget {
  const _SavedFiltersPanel({
    required this.controller,
    required this.onCompose,
  });

  final TransactionsController controller;
  final _FilterComposerLauncher onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return ValueListenableBuilder<TransactionFilterDefinition?>(
      valueListenable: controller.activeView,
      builder: (context, active, _) {
        return ValueListenableBuilder<List<TransactionFilterDefinition>>(
          valueListenable: controller.savedViews,
          builder: (context, views, __) {
            final children = <Widget>[
              Row(
                children: [
                  Text(
                    t.translate('advancedFiltersTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => onCompose(),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(t.translate('editFilters')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ];

            if (active != null) {
              final isSaved = views.any((view) => view.id == active.id);
              children.add(_ActiveFilterBanner(
                controller: controller,
                filter: active,
                isSaved: isSaved,
                onCompose: onCompose,
              ));
              children.add(const SizedBox(height: 12));
            }

            if (views.isEmpty) {
              children.add(Text(
                t.translate('noSavedViews'),
                style: theme.textTheme.titleSmall,
              ));
              children.add(const SizedBox(height: 4));
              children.add(Text(
                t.translate('noSavedViewsHint'),
                style: theme.textTheme.bodySmall,
              ));
            } else {
              children.add(Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final view in views)
                    _SavedViewCard(
                      controller: controller,
                      view: view,
                      onCompose: onCompose,
                    ),
                ],
              ));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        );
      },
    );
  }
}

class _ActiveFilterBanner extends StatelessWidget {
  const _ActiveFilterBanner({
    required this.controller,
    required this.filter,
    required this.isSaved,
    required this.onCompose,
  });

  final TransactionsController controller;
  final TransactionFilterDefinition filter;
  final bool isSaved;
  final _FilterComposerLauncher onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final summary = _filterSummary(context, filter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${t.translate('activeFilterTitle')}: ${filter.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.clearAdvancedFilter,
                child: Text(t.translate('clearFilter')),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              style: theme.textTheme.bodySmall,
            ),
          ],
          Row(
            children: [
              if (isSaved)
                TextButton(
                  onPressed: () => onCompose(definition: filter),
                  child: Text(t.translate('editView')),
                )
              else
                TextButton(
                  onPressed: () => onCompose(definition: filter),
                  child: Text(t.translate('saveViewAction')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedViewCard extends StatelessWidget {
  const _SavedViewCard({
    required this.controller,
    required this.view,
    required this.onCompose,
  });

  final TransactionsController controller;
  final TransactionFilterDefinition view;
  final _FilterComposerLauncher onCompose;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<TransactionFilterDefinition?>(
      valueListenable: controller.activeView,
      builder: (context, active, _) {
        final isActive = active?.id == view.id;
        return Container(
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.16)
                : theme.colorScheme.surfaceVariant.withOpacity(0.24),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withOpacity(0.45)
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.applyAdvancedFilter(
                    view,
                    updateBaseFilters: true,
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.translate('savedViewApplied'))),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                icon: const Icon(Icons.filter_alt_rounded, size: 18),
                label: Text(view.name),
              ),
              IconButton(
                tooltip: t.translate('editView'),
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: () => onCompose(definition: view),
              ),
              IconButton(
                tooltip: t.translate('deleteView'),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.deleteView(view.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        t.translate('savedViewDeleted', params: {'name': view.name}),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

String _filterSummary(BuildContext context, TransactionFilterDefinition filter) {
  final t = AppLocalizations.of(context);
  final localizations = MaterialLocalizations.of(context);
  final parts = <String>[];

  if (filter.minAmount != null) {
    parts.add('${t.translate('minAmountLabel')}: ${filter.minAmount!.toStringAsFixed(2)}');
  }
  if (filter.maxAmount != null) {
    parts.add('${t.translate('maxAmountLabel')}: ${filter.maxAmount!.toStringAsFixed(2)}');
  }
  if (filter.startDate != null || filter.endDate != null) {
    final start = filter.startDate ?? filter.endDate!;
    final end = filter.endDate ?? filter.startDate!;
    final formatted =
        '${localizations.formatMediumDate(start)} – ${localizations.formatMediumDate(end)}';
    parts.add('${t.translate('dateRange')}: $formatted');
  }
  if (filter.type != null) {
    parts.add(filter.type == TransactionType.expense
        ? t.translate('filterTypeExpense')
        : t.translate('filterTypeIncome'));
  }
  if (filter.status != null) {
    parts.add(t.translate(filter.status!.name));
  }
  if (filter.merchant != null) {
    parts.add('${t.translate('merchantContains')}: ${filter.merchant}');
  }
  if (filter.category != null) {
    parts.add('${t.translate('category')}: ${filter.category}');
  }
  if (filter.tags.isNotEmpty) {
    parts.add('${t.translate('tags')}: ${filter.tags.join(', ')}');
  }

  return parts.join(' • ');
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        note,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.url,
    required this.tooltip,
  });

  final String url;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) {
              return Dialog(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterComposerSheet extends StatefulWidget {
  const _FilterComposerSheet({
    required this.controller,
    this.initialDefinition,
  });

  final TransactionsController controller;
  final TransactionFilterDefinition? initialDefinition;

  @override
  State<_FilterComposerSheet> createState() => _FilterComposerSheetState();
}

class _FilterComposerSheetState extends State<_FilterComposerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;
  late final TextEditingController _merchantController;
  TransactionType? _type;
  TransactionStatus? _status;
  DateTimeRange? _dateRange;
  bool _includeCategory = false;
  bool _includeTags = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDefinition ?? widget.controller.activeView.value;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _minAmountController = TextEditingController(
      text: initial?.minAmount != null ? initial!.minAmount!.toStringAsFixed(2) : '',
    );
    _maxAmountController = TextEditingController(
      text: initial?.maxAmount != null ? initial!.maxAmount!.toStringAsFixed(2) : '',
    );
    _merchantController = TextEditingController(text: initial?.merchant ?? '');
    _type = initial?.type;
    _status = initial?.status;
    if (initial?.startDate != null || initial?.endDate != null) {
      _dateRange = DateTimeRange(
        start: initial?.startDate ?? initial!.endDate!,
        end: initial?.endDate ?? initial!.startDate!,
      );
    }
    _includeCategory = initial?.category != null;
    _includeTags = initial?.tags.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _apply({required bool save}) async {
    final t = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final min = double.tryParse(_minAmountController.text.trim());
    final max = double.tryParse(_maxAmountController.text.trim());

    if (min != null && max != null && min > max) {
      setState(() => _error = t.translate('invalidRangeError'));
      return;
    }
    if (save && name.isEmpty) {
      setState(() => _error = t.translate('missingNameError'));
      return;
    }

    setState(() => _error = null);

    final id = save
        ? widget.initialDefinition?.id ?? 'view_${DateTime.now().millisecondsSinceEpoch}'
        : widget.initialDefinition?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveName = name.isEmpty
        ? t.translate('quickFilterDraft')
        : name;

    final definition = TransactionFilterDefinition(
      id: id,
      name: effectiveName,
      category: _includeCategory ? widget.controller.categoryFilter.value : null,
      tags: _includeTags ? widget.controller.tagFilters.value.toList() : const [],
      minAmount: min,
      maxAmount: max,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      type: _type,
      status: _status,
      merchant: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
    );

    if (save) {
      await widget.controller.saveView(definition);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.translate('savedViewCreated', params: {'name': definition.name}),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('savedViewApplied'))),
      );
    }

    await widget.controller.applyAdvancedFilter(
      definition,
      updateBaseFilters: _includeCategory || _includeTags,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final hasCategory = widget.controller.categoryFilter.value != null;
    final hasTags = widget.controller.tagFilters.value.isNotEmpty;

    final rangeLabel = _dateRange == null
        ? t.translate('selectDates')
        : '${MaterialLocalizations.of(context).formatMediumDate(_dateRange!.start)} – ${MaterialLocalizations.of(context).formatMediumDate(_dateRange!.end)}';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: media.viewInsets.bottom + 24,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.translate('editFilters'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t.translate('saveViewAction'),
                    hintText: t.translate('quickFilterDraft'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: t.translate('minAmountLabel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: t.translate('maxAmountLabel'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(rangeLabel),
                ),
                const SizedBox(height: 16),
                Text(
                  t.translate('transactionTypeLabel'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(t.translate('typeAny')),
                      selected: _type == null,
                      onSelected: (_) => setState(() => _type = null),
                    ),
                    ChoiceChip(
                      label: Text(t.translate('filterTypeIncome')),
                      selected: _type == TransactionType.income,
                      onSelected: (_) => setState(() => _type = TransactionType.income),
                    ),
                    ChoiceChip(
                      label: Text(t.translate('filterTypeExpense')),
                      selected: _type == TransactionType.expense,
                      onSelected: (_) => setState(() => _type = TransactionType.expense),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t.translate('transactionStatusLabel'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(t.translate('statusAny')),
                      selected: _status == null,
                      onSelected: (_) => setState(() => _status = null),
                    ),
                    ChoiceChip(
                      label: Text(t.translate('completed')),
                      selected: _status == TransactionStatus.completed,
                      onSelected: (_) =>
                          setState(() => _status = TransactionStatus.completed),
                    ),
                    ChoiceChip(
                      label: Text(t.translate('pending')),
                      selected: _status == TransactionStatus.pending,
                      onSelected: (_) =>
                          setState(() => _status = TransactionStatus.pending),
                    ),
                    ChoiceChip(
                      label: Text(t.translate('scheduled')),
                      selected: _status == TransactionStatus.scheduled,
                      onSelected: (_) =>
                          setState(() => _status = TransactionStatus.scheduled),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    labelText: t.translate('merchantContains'),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _includeCategory && hasCategory,
                  onChanged: hasCategory
                      ? (value) => setState(() => _includeCategory = value ?? false)
                      : null,
                  title: Text(t.translate('includeCurrentCategory')),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _includeTags && hasTags,
                  onChanged: hasTags
                      ? (value) => setState(() => _includeTags = value ?? false)
                      : null,
                  title: Text(t.translate('includeCurrentTags')),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _apply(save: false),
                        child: Text(t.translate('applyFilters')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _apply(save: true),
                        child: Text(t.translate('saveViewAction')),
                      ),
                    ),
                  ],
                ),
                if (widget.initialDefinition != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await widget.controller.deleteView(widget.initialDefinition!.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t.translate(
                              'savedViewDeleted',
                              params: {'name': widget.initialDefinition!.name},
                            ),
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(t.translate('deleteView')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
