import 'dart:math';

import 'package:flutter/material.dart';

import '../../controllers/display_controller.dart';
import '../../data/models/wallet_card.dart';

class WalletCardView extends StatelessWidget {
  const WalletCardView({
    super.key,
    required this.card,
    required this.flipped,
    required this.onToggle,
    required this.isPrimary,
    required this.privacyMode,
    required this.surfaceStyle,
    required this.primaryLabel,
  });

  final WalletCardModel card;
  final bool flipped;
  final VoidCallback onToggle;
  final bool isPrimary;
  final bool privacyMode;
  final CardSurfaceStyle surfaceStyle;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final value = rotate.value;
              final visible = value <= pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value),
                alignment: Alignment.center,
                child: visible
                    ? child
                    : Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: child,
                      ),
              );
            },
          );
        },
        child: flipped
            ? _BackSide(card: card, surfaceStyle: surfaceStyle)
            : _FrontSide(
                card: card,
                isPrimary: isPrimary,
                privacyMode: privacyMode,
                surfaceStyle: surfaceStyle,
                primaryLabel: primaryLabel,
              ),
      ),
    );
  }
}

BoxDecoration _decorationFor(CardSurfaceStyle style, List<Color> colors) {
  switch (style) {
    case CardSurfaceStyle.solid:
      return BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      );
    case CardSurfaceStyle.glass:
      return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colors.first.withOpacity(0.85),
            colors.last.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      );
  }
}

class _FrontSide extends StatelessWidget {
  const _FrontSide({
    required this.card,
    required this.isPrimary,
    required this.privacyMode,
    required this.surfaceStyle,
    required this.primaryLabel,
  });

  final WalletCardModel card;
  final bool isPrimary;
  final bool privacyMode;
  final CardSurfaceStyle surfaceStyle;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('front-${card.id}'),
      decoration: _decorationFor(surfaceStyle, card.colors),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.label,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            privacyMode ? '••••••••' : card.number,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            privacyMode
                ? '*** ${card.currency}'
                : '${card.balance.toStringAsFixed(2)} ${card.currency}',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (isPrimary)
            Chip(
              label: Text(primaryLabel),
              backgroundColor: Colors.white24,
              labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _BackSide extends StatelessWidget {
  const _BackSide({
    required this.card,
    required this.surfaceStyle,
  });

  final WalletCardModel card;
  final CardSurfaceStyle surfaceStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('back-${card.id}'),
      decoration: _decorationFor(surfaceStyle, card.colors),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Card holder', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(card.label, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Text('Currency', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
          Text(card.currency, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const Spacer(),
          Text('ID: ${card.id}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
