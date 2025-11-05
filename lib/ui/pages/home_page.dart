import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/budgets_controller.dart';
import '../../controllers/goals_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/recipients_controller.dart';
import '../../controllers/recurring_payments_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_constants.dart';
import '../../data/models/budget.dart';
import '../../data/models/recipient.dart';
import '../../data/models/savings_goal.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_timeline.dart';
import '../../data/models/wallet_card.dart';
import '../../data/models/recurring_payment.dart';
import '../widgets/budget_card.dart';
import '../widgets/transaction_preview_card.dart';
import '../widgets/wallet_card_carousel.dart';
import '../widgets/wallet_card_composer.dart';
import '../widgets/sensitive_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.transactionsController,
    required this.budgetsController,
    required this.searchController,
    required this.walletController,
    required this.sessionController,
    required this.profileController,
    required this.goalsController,
    required this.recipientsController,
    required this.recurringPaymentsController,
    required this.onOpenBudgets,
    required this.onOpenTransactions,
  });

  final TransactionsController transactionsController;
  final BudgetsController budgetsController;
  final SearchController searchController;
  final WalletController walletController;
  final SessionController sessionController;
  final ProfileController profileController;
  final GoalsController goalsController;
  final RecipientsController recipientsController;
  final RecurringPaymentsController recurringPaymentsController;
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

  void _presentAddCardSheet(AppLocalizations t) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: WalletCardComposer(
            localization: t,
            currencyOptions: AppConstants.walletCurrencies,
            networkOptions: AppConstants.walletNetworks,
            onSubmit: (title, amount, selectedCurrency, selectedNetwork) {
              final holder = widget.profileController.nameNotifier.value;
              final card = widget.walletController.composeCard(
                title: title,
                balance: amount,
                currency: selectedCurrency,
                network: selectedNetwork,
                holderName: holder.isEmpty ? 'Mawaid' : holder,
              );
              widget.walletController.addCard(card);
              return true;
            },
          ),
        );
      },
    ).then((accepted) {
      if (accepted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('walletCardAdded'))),
        );
      }
    });
  }

  Future<void> _handleQuickSend(RecipientModel recipient) async {
    final t = AppLocalizations.of(context);
    final amountController = TextEditingController(
      text: recipient.quickAmount.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.translate('quickSendTitleRecipient',
              params: {'name': recipient.name})),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.translate('quickSendAmountLabel'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return t.translate('required');
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return t.translate('invalidNumber');
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.translate('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(
                    context,
                    double.parse(amountController.text),
                  );
                }
              },
              child: Text(t.translate('confirm')),
            ),
          ],
        );
      },
    );

    if (amount == null || amount <= 0) {
      return;
    }

    await widget.recipientsController.setQuickAmount(recipient.id, amount);

    final tx = TransactionModel(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}_${recipient.id}',
      title: t.translate('quickSendTransactionTitle'),
      description: recipient.name,
      amount: amount,
      currency: recipient.currency,
      category: 'Transfers',
      tags: ['quick-send', 'favorite'],
      date: DateTime.now(),
      type: TransactionType.expense,
      status: TransactionStatus.completed,
      merchant: recipient.handle,
    );

    await widget.transactionsController.addManualTransaction(tx);
    widget.searchController
        .rebuildSource(widget.transactionsController.allTransactions);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.translate('quickSendSuccess', params: {
            'name': recipient.name,
            'amount': amount.toStringAsFixed(0),
          }),
        ),
      ),
    );
  }

  Future<void> _manageFavorites() async {
    final t = AppLocalizations.of(context);
    final recipients = widget.recipientsController.allRecipients;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  t.translate('quickSendManage'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipients.length,
                    itemBuilder: (context, index) {
                      final person = recipients[index];
                      return SwitchListTile(
                        value: person.isFavorite,
                        onChanged: (_) => widget.recipientsController
                            .toggleFavorite(person.id),
                        title: Text(person.name),
                        subtitle: Text(person.handle),
                        secondary: CircleAvatar(
                          backgroundImage: NetworkImage(person.avatarUrl),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 260,
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ValueListenableBuilder<String>(
                                        valueListenable:
                                            widget.profileController.nameNotifier,
                                        builder: (context, name, _) {
                                          final firstName = name.trim().isEmpty
                                              ? ''
                                              : name.split(' ').first;
                                          final greetingTemplate =
                                              t.translate('homeGreetingName');
                                          final greeting = greetingTemplate.replaceAll(
                                            '{name}',
                                            firstName.isEmpty ? name : firstName,
                                          );
                                          return Text(
                                            greeting,
                                            style: theme.textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(duration: 400.ms)
                                              .slideY(begin: 0.3, end: 0);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      ValueListenableBuilder<String>(
                                        valueListenable:
                                            widget.profileController.titleNotifier,
                                        builder: (context, role, _) {
                                          final subtitle = t
                                              .translate('homeSubtitleRole')
                                              .replaceAll('{role}', role);
                                          return Text(
                                            subtitle,
                                            style: theme.textTheme.bodyMedium,
                                          )
                                              .animate()
                                              .fadeIn(duration: 420.ms)
                                              .slideY(begin: 0.2, end: 0);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      widget.sessionController.privacyModeNotifier,
                                  builder: (context, hidden, __) {
                                    final icon = hidden
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded;
                                    final tooltip = hidden
                                        ? t.translate('privacyQuickToggleOff')
                                        : t.translate('privacyQuickToggleOn');
                                    return IconButton(
                                      tooltip: tooltip,
                                      onPressed: () async {
                                        HapticFeedback.selectionClick();
                                        await widget.sessionController
                                            .setPrivacyMode(!hidden);
                                        if (!mounted) return;
                                        final message = !hidden
                                            ? t.translate('privacyHiddenToast')
                                            : t.translate('privacyVisibleToast');
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                      },
                                      icon: Icon(icon),
                                    );
                                  },
                                ),
                              ],
                            ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.translate('walletTitle'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<List<WalletCardModel>>(
                                  valueListenable: widget.walletController.cardsNotifier,
                                  builder: (context, cards, _) {
                                    final countDescription = t
                                        .translate('walletCountLabel')
                                        .replaceAll('{count}', cards.length.toString());
                                    return Text(
                                      countDescription,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurface.withOpacity(0.65),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: t.translate('walletAddCard'),
                                onPressed: () => _presentAddCardSheet(t),
                                icon: const Icon(Icons.add_card_rounded),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppRouter.wallets);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(t.translate('walletManage')),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WalletCardCarousel(
                        controller: widget.walletController,
                        localization: t,
                        privacyListenable:
                            widget.sessionController.privacyModeNotifier,
                      ),
                      ValueListenableBuilder<List<RecipientModel>>(
                        valueListenable:
                            widget.recipientsController.favoritesNotifier,
                        builder: (context, favorites, _) {
                          if (favorites.isEmpty) {
                            return const SizedBox(height: 24);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _QuickSendStrip(
                                favorites: favorites,
                                localization: t,
                                onSend: _handleQuickSend,
                                onManage: _manageFavorites,
                              ),
                            ],
                          );
                        },
                      ),
                      ValueListenableBuilder<List<SavingsGoalModel>>(
                        valueListenable: widget.goalsController.goalsNotifier,
                        builder: (context, goals, _) {
                          if (goals.isEmpty) {
                            return const SizedBox(height: 20);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _GoalsPeek(
                                goals: goals,
                                localization: t,
                                onViewAll: widget.onOpenBudgets,
                              ),
                            ],
                          );
                        },
                      ),
                      ValueListenableBuilder<List<RecurringPaymentModel>>(
                        valueListenable:
                            widget.recurringPaymentsController.paymentsNotifier,
                        builder: (context, scheduled, _) {
                          if (scheduled.isEmpty) {
                            return const SizedBox(height: 20);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _UpcomingRecurringBanner(
                                payment: (List<RecurringPaymentModel>.from(scheduled)
                                      ..sort((a, b) => a.nextDate.compareTo(b.nextDate)))[0],
                                localization: t,
                                onOpenTransactions: widget.onOpenTransactions,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
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
                                return BudgetCard(
                                  budget: budget,
                                  privacyListenable:
                                      widget.sessionController.privacyModeNotifier,
                                )
                                    .animate(delay: (index * 80).ms)
                                    .fadeIn(duration: 320.ms)
                                    .slideX(
                                      begin: 0.2,
                                      end: 0,
                                      curve: Curves.easeOut,
                                    );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
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
                        valueListenable: widget.transactionsController.timelineNotifier,
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
                                            child: SensitiveText(
                                              privacyListenable: widget
                                                  .sessionController.privacyModeNotifier,
                                              visibleText:
                                                  '${t.translate('totalShort')} ${section.total.toStringAsFixed(0)}',
                                              style: theme.textTheme.labelSmall?.copyWith(
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
                                          privacyListenable: widget
                                              .sessionController.privacyModeNotifier,
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
                      const SizedBox(height: 24),
                      _CoachCard(
                        t: t,
                        onShowGuide: widget.sessionController.requestCoachReveal,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.sessionController.showCoachNotifier,
          builder: (context, show, _) {
            if (!show) {
              return const SizedBox.shrink();
            }
            return _HomeCoachOverlay(
              t: t,
              onDismiss: () => unawaited(widget.sessionController.markCoachSeen()),
            );
          },
        ),
      ],
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

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.t, required this.onShowGuide});

  final AppLocalizations t;
  final VoidCallback onShowGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('coachTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('coachDescription'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onShowGuide,
                  child: Text(t.translate('coachShowMe')),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.translate('coachRemind'))),
                    );
                  },
                  child: Text(t.translate('coachRemindLater')),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.2, end: 0);
  }
}

class _QuickSendStrip extends StatelessWidget {
  const _QuickSendStrip({
    required this.favorites,
    required this.localization,
    required this.onSend,
    required this.onManage,
  });

  final List<RecipientModel> favorites;
  final AppLocalizations localization;
  final void Function(RecipientModel recipient) onSend;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final t = localization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.translate('quickSendTitle'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onManage,
              child: Text(t.translate('quickSendManage')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipient = favorites[index];
              return _QuickSendCard(
                recipient: recipient,
                localization: t,
                onSend: () => onSend(recipient),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickSendCard extends StatelessWidget {
  const _QuickSendCard({
    required this.recipient,
    required this.localization,
    required this.onSend,
  });

  final RecipientModel recipient;
  final AppLocalizations localization;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountLabel = localization.translate('quickSendAmountShort', params: {
      'amount': recipient.quickAmount.toStringAsFixed(0),
      'currency': recipient.currency,
    });

    return Container(
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(recipient.avatarUrl),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              amountLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onSend,
                child: Text(localization.translate('quickSendAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsPeek extends StatelessWidget {
  const _GoalsPeek({
    required this.goals,
    required this.localization,
    required this.onViewAll,
  });

  final List<SavingsGoalModel> goals;
  final AppLocalizations localization;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTarget = goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
    final totalSaved = goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
    final highlight = goals.take(2).toList();
    final summary = localization.translate('goalsPeekSummary', params: {
      'saved': totalSaved.toStringAsFixed(0),
      'target': totalTarget.toStringAsFixed(0),
    });

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  localization.translate('goalsPeekTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(localization.translate('viewAll')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final goal in highlight)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.onSurface.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(goal.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRecurringBanner extends StatelessWidget {
  const _UpcomingRecurringBanner({
    required this.payment,
    required this.localization,
    required this.onOpenTransactions,
  });

  final RecurringPaymentModel payment;
  final AppLocalizations localization;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next =
        '${payment.nextDate.month.toString().padLeft(2, '0')}/${payment.nextDate.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('upcomingRecurringTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${payment.title} — ${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  localization.translate('recurringNext', params: {'date': next}),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onOpenTransactions,
            child: Text(localization.translate('upcomingRecurringButton')),
          ),
        ],
      ),
    );
  }
}

class _HomeCoachOverlay extends StatelessWidget {
  const _HomeCoachOverlay({required this.t, required this.onDismiss});

  final AppLocalizations t;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      _CoachHint(Icons.credit_card_rounded, t.translate('coachStepWallet')),
      _CoachHint(Icons.pie_chart_rounded, t.translate('coachStepBudgets')),
      _CoachHint(Icons.timeline_rounded, t.translate('coachStepTimeline')),
    ];

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('coachOverlayTitle'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.translate('coachOverlaySubtitle'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...steps.map(
                      (step) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(step.icon, color: theme.colorScheme.primary),
                        ),
                        title: Text(step.label),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        child: Text(t.translate('coachGotIt')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachHint {
  const _CoachHint(this.icon, this.label);

  final IconData icon;
  final String label;
}

