import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_constants.dart';
import '../../data/models/wallet_card.dart';
import '../widgets/wallet_card_composer.dart';

class WalletsPage extends StatefulWidget {
  const WalletsPage({
    super.key,
    required this.walletController,
    required this.profileController,
  });

  final WalletController walletController;
  final ProfileController profileController;

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  Future<void> _showAddCardSheet(AppLocalizations t) async {
    final holder = widget.profileController.nameNotifier.value;
    final result = await showModalBottomSheet<bool>(
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
            onSubmit: (title, amount, currency, network) {
              final card = widget.walletController.composeCard(
                title: title,
                balance: amount,
                currency: currency,
                network: network,
                holderName: holder.isEmpty ? 'Mawaid' : holder,
              );
              widget.walletController.addCard(card);
              return true;
            },
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('walletCardAdded'))),
      );
    }
  }

  Future<void> _confirmRemoveCard(
    WalletCardModel card,
    AppLocalizations t,
  ) async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(t.translate('walletRemoveTitle')),
              content: Text(
                t
                    .translate('walletRemoveMessage')
                    .replaceAll('{title}', card.title),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(t.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(t.translate('delete')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldRemove) {
      widget.walletController.removeCard(card.id);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('walletCardRemoved'))),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex, AppLocalizations t) {
    widget.walletController.reorderCards(oldIndex, newIndex);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.translate('walletReordered'))),
    );
  }

  void _markPrimary(int index, AppLocalizations t) {
    widget.walletController.setActiveIndex(index);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.translate('walletPrimaryUpdated'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('walletManagerTitle')),
        actions: [
          IconButton(
            tooltip: t.translate('walletAddCard'),
            icon: const Icon(Icons.add_card_rounded),
            onPressed: () => _showAddCardSheet(t),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardSheet(t),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.translate('walletAddCard')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ValueListenableBuilder<List<WalletCardModel>>(
            valueListenable: widget.walletController.cardsNotifier,
            builder: (context, cards, _) {
              if (cards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.translate('noWalletCards'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.translate('walletManagerSubtitle'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('walletStackPreviewTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      child: _WalletStackPreview(
                        key: ValueKey(cards.map((e) => e.id).join('-')),
                        cards: cards,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.translate('walletReorderHint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: cards.length,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(oldIndex, newIndex, t),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Card(
                          key: ValueKey(card.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  card.startColor().withOpacity(0.25),
                              child: Text(card.currency),
                            ),
                            title: Text(card.title),
                            subtitle: Text(
                              t
                                  .translate('walletListMeta')
                                  .replaceAll('{balance}', card.balance.toStringAsFixed(2))
                                  .replaceAll('{currency}', card.currency)
                                  .replaceAll('{network}', card.network),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      widget.walletController.activeCardIndex,
                                  builder: (context, active, __) {
                                    final isPrimary = active == index;
                                    return Tooltip(
                                      message: isPrimary
                                          ? t.translate('walletPrimaryBadge')
                                          : t.translate('walletSetPrimary'),
                                      child: ActionChip(
                                        label: Text(
                                          isPrimary
                                              ? t.translate('walletPrimaryBadge')
                                              : t.translate('walletSetPrimary'),
                                        ),
                                        onPressed: isPrimary
                                            ? null
                                            : () => _markPrimary(index, t),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: t.translate('delete'),
                                  onPressed: () => _confirmRemoveCard(card, t),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WalletStackPreview extends StatelessWidget {
  const _WalletStackPreview({
    super.key,
    required this.cards,
  });

  final List<WalletCardModel> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final preview = cards.take(4).toList();
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < preview.length; i++)
          Positioned.fill(
            top: i * 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1 - (i * 0.12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      preview[i].startColor(),
                      preview[i].endColor(),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: preview[i].startColor().withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      preview[i].title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.translate('walletBalanceLabel'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${preview[i].balance.toStringAsFixed(2)} ${preview[i].currency}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t.translate('walletExpiryLabel'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              preview[i].expiry,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
