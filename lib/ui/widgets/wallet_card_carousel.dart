import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../controllers/display_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../data/models/wallet_card.dart';
import 'sensitive_text.dart';

class WalletCardCarousel extends StatefulWidget {
  const WalletCardCarousel({
    super.key,
    required this.controller,
    required this.localization,
    required this.privacyListenable,
  });

  final WalletController controller;
  final AppLocalizations localization;
  final ValueListenable<bool> privacyListenable;

  @override
  State<WalletCardCarousel> createState() => _WalletCardCarouselState();
}

class _WalletCardCarouselState extends State<WalletCardCarousel> {
  late final PageController _pageController;
  late DisplayController _displayController;
  bool _didAttachDisplay = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttachDisplay) {
      _displayController = AppScope.of(context).displayController;
      _didAttachDisplay = true;
    }
  }

  void _handleActiveIndexChange() {
    if (!_pageController.hasClients) return;
    final target = widget.controller.activeCardIndex.value;
    final current = _pageController.page?.round() ?? _pageController.initialPage ?? 0;
    if (target == current) return;
    if (_displayController.reduceMotionNotifier.value) {
      _pageController.jumpToPage(target);
      return;
    }
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
    return ValueListenableBuilder<CardSurfaceStyle>(
      valueListenable: _displayController.cardStyle,
      builder: (context, style, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _displayController.reduceMotionNotifier,
          builder: (context, reduceMotion, __) {
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
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 320),
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
                                  onTap: () =>
                                      widget.controller.toggleFlip(card.id),
                                  localization: widget.localization,
                                  privacyListenable: widget.privacyListenable,
                                  style: style,
                                  reduceMotion: reduceMotion,
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
          },
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
    required this.privacyListenable,
    required this.style,
    required this.reduceMotion,
  });

  final WalletCardModel card;
  final bool isActive;
  final bool isFlipped;
  final VoidCallback onTap;
  final AppLocalizations localization;
  final ValueListenable<bool> privacyListenable;
  final CardSurfaceStyle style;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final front = _WalletCardFront(
      card: card,
      isActive: isActive,
      localization: localization,
      privacyListenable: privacyListenable,
      style: style,
      reduceMotion: reduceMotion,
    );
    final back = _WalletCardBack(
      card: card,
      theme: theme,
      localization: localization,
      style: style,
      reduceMotion: reduceMotion,
    );

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
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
    required this.privacyListenable,
    required this.style,
    required this.reduceMotion,
  });

  final WalletCardModel card;
  final bool isActive;
  final AppLocalizations localization;
  final ValueListenable<bool> privacyListenable;
  final CardSurfaceStyle style;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = _frontDecoration(theme, card, style, isActive);
    Widget cardSurface = AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: decoration,
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
                  SensitiveText(
                    privacyListenable: privacyListenable,
                    visibleText:
                        '${card.currency} ${card.balance.toStringAsFixed(2)}',
                    hiddenText: '••••',
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
    if (style == CardSurfaceStyle.glass) {
      cardSurface = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: cardSurface,
        ),
      );
    }
    return cardSurface;
  }
}

class _WalletCardBack extends StatelessWidget {
  const _WalletCardBack({
    required this.card,
    required this.theme,
    required this.localization,
    required this.style,
    required this.reduceMotion,
  });

  final WalletCardModel card;
  final ThemeData theme;
  final AppLocalizations localization;
  final CardSurfaceStyle style;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final decoration = _backDecoration(theme, card, style);
    Widget surface = AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      decoration: decoration,
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
    if (style == CardSurfaceStyle.glass) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: surface,
        ),
      );
    }
    return surface;
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

BoxDecoration _frontDecoration(
  ThemeData theme,
  WalletCardModel card,
  CardSurfaceStyle style,
  bool isActive,
) {
  final radius = BorderRadius.circular(28);
  switch (style) {
    case CardSurfaceStyle.glass:
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            card.startColor().withOpacity(0.8),
            card.endColor().withOpacity(0.74),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(isActive ? 0.4 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: card.startColor().withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 18),
            )
          else
            BoxShadow(
              color: card.startColor().withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
        ],
      );
    case CardSurfaceStyle.solid:
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [card.startColor(), card.endColor()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: card.startColor().withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 16),
            )
          else
            BoxShadow(
              color: card.startColor().withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
        ],
      );
    case CardSurfaceStyle.subtle:
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.22),
              blurRadius: 22,
              offset: const Offset(0, 14),
            )
          else
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
        ],
      );
  }
}

BoxDecoration _backDecoration(
  ThemeData theme,
  WalletCardModel card,
  CardSurfaceStyle style,
) {
  final radius = BorderRadius.circular(28);
  switch (style) {
    case CardSurfaceStyle.glass:
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            card.endColor().withOpacity(0.65),
            card.startColor().withOpacity(0.6),
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      );
    case CardSurfaceStyle.solid:
      return BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: card.startColor().withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: card.startColor().withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );
    case CardSurfaceStyle.subtle:
      return BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: radius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.45),
        ),
      );
  }
}
