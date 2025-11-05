import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/budgets_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_timeline.dart';
import '../../data/models/wallet_card.dart';
import '../widgets/budget_card.dart';
import '../widgets/transaction_preview_card.dart';
import '../widgets/wallet_card_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.transactionsController,
    required this.budgetsController,
    required this.searchController,
    required this.walletController,
    required this.sessionController,
    required this.profileController,
    required this.onOpenBudgets,
    required this.onOpenTransactions,
  });

  final TransactionsController transactionsController;
  final BudgetsController budgetsController;
  final SearchController searchController;
  final WalletController walletController;
  final SessionController sessionController;
  final ProfileController profileController;
  final VoidCallback onOpenBudgets;
  final VoidCallback onOpenTransactions;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchFieldController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  static const _currencyOptions = ['USD', 'EUR', 'AED', 'SAR'];
  static const _networkOptions = ['VISA', 'Mastercard', 'UnionPay', 'Amethyst'];
  static const List<List<int>> _cardGradients = [
    [0xFF2BAA7D, 0xFF58C6A3],
    [0xFF3A7BFF, 0xFF7FA6FF],
    [0xFF9B5DE5, 0xFFB48BFF],
    [0xFFFF8A3D, 0xFFFFB37A],
  ];

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
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currency = ValueNotifier<String>(_currencyOptions.first);
    final network = ValueNotifier<String>(_networkOptions.first);
    showModalBottomSheet<void>(
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
          child: _AddWalletCardSheet(
            titleController: titleController,
            amountController: amountController,
            currency: currency,
            network: network,
            onSubmit: (title, amount, selectedCurrency, selectedNetwork) {
              final random = Random();
              final digits = List.generate(4, (_) => random.nextInt(9000) + 1000)
                  .join(' ');
              final expiryMonth = (random.nextInt(12) + 1).toString().padLeft(2, '0');
              final expiryYear = (DateTime.now().year + 2 + random.nextInt(5))
                  .toString()
                  .substring(2);
              final gradient =
                  _cardGradients[random.nextInt(_cardGradients.length)];
              widget.walletController.addCard(
                WalletCardModel(
                  id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  holderName: widget.profileController.nameNotifier.value,
                  cardNumber: digits,
                  balance: amount,
                  currency: selectedCurrency,
                  gradient: gradient,
                  expiry: '$expiryMonth/$expiryYear',
                  network: selectedNetwork,
                ),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.translate('walletCardAdded'))),
              );
            },
            t: t,
          ),
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      amountController.dispose();
      currency.dispose();
      network.dispose();
    });
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
                            ValueListenableBuilder<String>(
                              valueListenable: widget.profileController.nameNotifier,
                              builder: (context, name, _) {
                                final firstName =
                                    name.trim().isEmpty ? '' : name.split(' ').first;
                                final greetingTemplate =
                                    t.translate('homeGreetingName');
                                final greeting = greetingTemplate
                                    .replaceAll('{name}', firstName.isEmpty ? name : firstName);
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
                              valueListenable: widget.profileController.titleNotifier,
                              builder: (context, role, _) {
                                final subtitle =
                                    t.translate('homeSubtitleRole').replaceAll('{role}', role);
                                return Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium,
                                )
                                    .animate()
                                    .fadeIn(duration: 420.ms)
                                    .slideY(begin: 0.2, end: 0);
                              },
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
                          IconButton(
                            tooltip: t.translate('walletAddCard'),
                            onPressed: () => _presentAddCardSheet(t),
                            icon: const Icon(Icons.add_card_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WalletCardCarousel(
                        controller: widget.walletController,
                        localization: t,
                      ),
                      const SizedBox(height: 28),
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
                                            child: Text(
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

class _AddWalletCardSheet extends StatefulWidget {
  const _AddWalletCardSheet({
    required this.titleController,
    required this.amountController,
    required this.currency,
    required this.network,
    required this.onSubmit,
    required this.t,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final ValueNotifier<String> currency;
  final ValueNotifier<String> network;
  final void Function(String title, double amount, String currency, String network)
      onSubmit;
  final AppLocalizations t;

  @override
  State<_AddWalletCardSheet> createState() => _AddWalletCardSheetState();
}

class _AddWalletCardSheetState extends State<_AddWalletCardSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final parsed = double.tryParse(widget.amountController.text.replaceAll(',', '.'));
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.t.translate('invalidAmount'))),
      );
      return;
    }
    widget.onSubmit(
      widget.titleController.text.trim(),
      parsed,
      widget.currency.value,
      widget.network.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.t.translate('walletAddTitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.titleController,
            decoration: InputDecoration(
              labelText: widget.t.translate('walletNameLabel'),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.t.translate('required');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.t.translate('walletAmountLabel'),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.t.translate('required');
              }
              return double.tryParse(value.replaceAll(',', '.')) == null
                  ? widget.t.translate('invalidAmount')
                  : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.currency.value,
            decoration: InputDecoration(
              labelText: widget.t.translate('walletCurrencyLabel'),
            ),
            items: _HomePageState._currencyOptions
                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                .toList(),
            onChanged: (value) {
              if (value != null) widget.currency.value = value;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: widget.network.value,
            decoration: InputDecoration(
              labelText: widget.t.translate('walletNetworkLabel'),
            ),
            items: _HomePageState._networkOptions
                .map((net) => DropdownMenuItem(value: net, child: Text(net)))
                .toList(),
            onChanged: (value) {
              if (value != null) widget.network.value = value;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(widget.t.translate('walletSaveCard')),
            ),
          ),
        ],
      ),
    );
  }
}
