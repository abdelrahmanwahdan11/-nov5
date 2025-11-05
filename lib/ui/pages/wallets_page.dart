import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../data/models/wallet_card.dart';

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('walletsTitle'),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<WalletCardModel>>(
                valueListenable: scope.walletController.cards,
                builder: (context, cards, _) {
                  if (cards.isEmpty) {
                    return Center(child: Text(l10n.translate('transactionsEmpty')));
                  }
                  return ReorderableListView.builder(
                    itemCount: cards.length,
                    onReorder: scope.walletController.reorder,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isPrimary = scope.walletController.primaryCardId.value == card.id;
                      return Card(
                        key: ValueKey(card.id),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(card.label),
                          subtitle: Text(card.number),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'primary':
                                  scope.walletController.makePrimary(card.id);
                                  break;
                                case 'remove':
                                  scope.walletController.removeCard(card.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'primary',
                                child: Text(l10n.translate('walletMakePrimary')),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(l10n.translate('walletDelete')),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                          titleTextStyle: Theme.of(context).textTheme.titleMedium,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          selected: isPrimary,
                          selectedTileColor:
                              Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
