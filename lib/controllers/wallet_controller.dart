import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/wallet_card.dart';
import '../data/mock/mock_data.dart';

class WalletController {
  WalletController._(
    this._prefs,
    List<WalletCardModel> initialCards,
    int activeIndex,
    Set<String> flipped,
  )   : cardsNotifier = ValueNotifier<List<WalletCardModel>>(initialCards),
        activeCardIndex = ValueNotifier<int>(activeIndex),
        flippedCards = ValueNotifier<Set<String>>(flipped);

  final SharedPreferences _prefs;
  final ValueNotifier<List<WalletCardModel>> cardsNotifier;
  final ValueNotifier<int> activeCardIndex;
  final ValueNotifier<Set<String>> flippedCards;

  static Future<WalletController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCards = prefs.getString(AppConstants.prefWalletCards);
    final storedActive =
        prefs.getInt(AppConstants.prefWalletActiveIndex) ?? 0;
    final storedFlipped =
        prefs.getStringList(AppConstants.prefWalletFlippedCards) ?? <String>[];

    final cards = storedCards != null
        ? WalletCardModel.decodeList(storedCards)
        : MockDataGenerator.defaultWalletCards();

    final controller = WalletController._(
      prefs,
      cards,
      min(storedActive, cards.isEmpty ? 0 : cards.length - 1),
      storedFlipped.toSet(),
    );

    controller.cardsNotifier.addListener(() {
      final encoded = WalletCardModel.encodeList(controller.cardsNotifier.value);
      prefs.setString(AppConstants.prefWalletCards, encoded);
    });

    controller.activeCardIndex.addListener(() {
      prefs.setInt(
        AppConstants.prefWalletActiveIndex,
        controller.activeCardIndex.value,
      );
    });

    controller.flippedCards.addListener(() {
      prefs.setStringList(
        AppConstants.prefWalletFlippedCards,
        controller.flippedCards.value.toList(),
      );
    });

    return controller;
  }

  void setActiveIndex(int index) {
    if (index < 0 || index >= cardsNotifier.value.length) return;
    activeCardIndex.value = index;
  }

  void toggleFlip(String cardId) {
    final flipped = Set<String>.from(flippedCards.value);
    if (flipped.contains(cardId)) {
      flipped.remove(cardId);
    } else {
      flipped.add(cardId);
    }
    flippedCards.value = flipped;
  }

  void addCard(WalletCardModel card) {
    final cards = List<WalletCardModel>.from(cardsNotifier.value)..add(card);
    cardsNotifier.value = cards;
    activeCardIndex.value = cards.length - 1;
  }

  WalletCardModel composeCard({
    required String title,
    required double balance,
    required String currency,
    required String network,
    required String holderName,
  }) {
    final random = Random();
    final digits = List.generate(4, (_) => random.nextInt(9000) + 1000).join(' ');
    final expiryMonth = (random.nextInt(12) + 1).toString().padLeft(2, '0');
    final expiryYear = (DateTime.now().year + 2 + random.nextInt(5)).toString().substring(2);
    final gradient = AppConstants
        .walletGradients[random.nextInt(AppConstants.walletGradients.length)];

    return WalletCardModel(
      id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      holderName: holderName,
      cardNumber: digits,
      balance: balance,
      currency: currency,
      gradient: gradient,
      expiry: '$expiryMonth/$expiryYear',
      network: network,
    );
  }

  void updateBalance(String cardId, double delta) {
    final cards = cardsNotifier.value.map((card) {
      if (card.id == cardId) {
        return card.copyWith(balance: (card.balance + delta).clamp(0, 999999));
      }
      return card;
    }).toList();
    cardsNotifier.value = cards;
  }

  void removeCard(String cardId) {
    final cards = List<WalletCardModel>.from(cardsNotifier.value)
      ..removeWhere((card) => card.id == cardId);
    cardsNotifier.value = cards;
    if (activeCardIndex.value >= cards.length) {
      activeCardIndex.value = cards.isEmpty ? 0 : cards.length - 1;
    }
  }

  void reorderCards(int oldIndex, int newIndex) {
    final cards = List<WalletCardModel>.from(cardsNotifier.value);
    if (oldIndex < 0 || oldIndex >= cards.length) {
      return;
    }
    if (newIndex > cards.length) {
      newIndex = cards.length;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final card = cards.removeAt(oldIndex);
    cards.insert(newIndex, card);
    cardsNotifier.value = cards;
    activeCardIndex.value = newIndex;
  }

  void dispose() {
    cardsNotifier.dispose();
    activeCardIndex.dispose();
    flippedCards.dispose();
  }
}
