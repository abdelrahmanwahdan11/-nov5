import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../controllers/wallet_controller.dart';
import '../../data/models/wallet_card.dart';
import '../../core/localization/app_localizations.dart';

class WalletCardCarousel extends StatefulWidget {
  const WalletCardCarousel({
    super.key,
    required this.controller,
    required this.localization,
  });

  final WalletController controller;
  final AppLocalizations localization;

  @override
  State<WalletCardCarousel> createState() => _WalletCardCarouselState();
}

class _WalletCardCarouselState extends State<WalletCardCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final cards = widget.controller.cardsNotifier.value;
    final initialIndex = cards.isEmpty
        ? 0
        : widget.controller.activeCardIndex.value.clamp(0, cards.length - 1);
    _pageController = PageController(viewportFraction: 0.78, initialPage: initialIndex);
    widget.controller.activeCardIndex.addListener(_handleActiveIndexChange);
  }

  void _handleActiveIndexChange() {
    if (!_pageController.hasClients) return;
    final target = widget.controller.activeCardIndex.value;
    final current = _pageController.page?.round() ?? _pageController.initialPage ?? 0;
    if (target == current) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    widget.controller.activeCardIndex.removeListener(_handleActiveIndexChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WalletCardModel>>(
      valueListenable: widget.controller.cardsNotifier,
      builder: (context, cards, _) {
        if (cards.isEmpty) {
          return Center(
            child: Text(
              localization.translate('noWalletCards'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: widget.controller.setActiveIndex,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ValueListenableBuilder<int>(
                valueListenable: widget.controller.activeCardIndex,
                builder: (context, activeIndex, __) {
                  final isActive = index == activeIndex;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      vertical: isActive ? 0 : 14,
                      horizontal: 8,
                    ),
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: widget.controller.flippedCards,
                      builder: (context, flipped, ___) {
                        final isFlipped = flipped.contains(card.id);
                        return _WalletFlipCard(
                          card: card,
                          isActive: isActive,
                          isFlipped: isFlipped,
                          onTap: () => widget.controller.toggleFlip(card.id),
                          localization: widget.localization,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _WalletFlipCard extends StatelessWidget {
  const _WalletFlipCard({
    required this.card,
    required this.isActive,
    required this.isFlipped,
    required this.onTap,
    required this.localization,
  });

  final WalletCardModel card;
  final bool isActive;
  final bool isFlipped;
  final VoidCallback onTap;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final front = _WalletCardFront(
      card: card,
      isActive: isActive,
      localization: localization,
    );
    final back = _WalletCardBack(
      card: card,
      theme: theme,
      localization: localization,
    );

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final isFront = value < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value),
            child: isFront
                ? front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: back,
                  ),
          );
        },
      ),
    );
  }
}

class _WalletCardFront extends StatelessWidget {
  const _WalletCardFront({
    required this.card,
    required this.isActive,
    required this.localization,
  });

  final WalletCardModel card;
  final bool isActive;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [card.startColor(), card.endColor()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: card.startColor().withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                card.network,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            card.maskedNumber,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('walletBalanceLabel'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${card.currency} ${card.balance.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    localization.translate('walletExpiryLabel'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    card.expiry,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletCardBack extends StatelessWidget {
  const _WalletCardBack({
    required this.card,
    required this.theme,
    required this.localization,
  });

  final WalletCardModel card;
  final ThemeData theme;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.35),
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WalletMetaLabel(
                label: localization.translate('walletHolderLabel'),
                value: card.holderName,
                alignment: CrossAxisAlignment.start,
              ),
              _WalletMetaLabel(
                label: localization.translate('walletNetworkLabel'),
                value: card.network,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _WalletMetaLabel(
            label: localization.translate('walletNumberLabel'),
            value: card.cardNumber,
            alignment: CrossAxisAlignment.start,
          ),
          const SizedBox(height: 24),
          _WalletMetaLabel(
            label: localization.translate('walletNotesLabel'),
            value: localization.translate('walletNotesValue'),
            alignment: CrossAxisAlignment.start,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              localization.translate('walletSwipeHint'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _WalletMetaLabel extends StatelessWidget {
  const _WalletMetaLabel({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
