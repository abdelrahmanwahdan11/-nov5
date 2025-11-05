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

  void dispose() {
    cardsNotifier.dispose();
    activeCardIndex.dispose();
    flippedCards.dispose();
  }
}
