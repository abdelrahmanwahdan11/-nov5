import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/wallet_card.dart';

class WalletController {
  WalletController._(this.cards, this.primaryCardId, this._prefs);

  static const _cardsKey = 'wallet_cards';
  static const _primaryKey = 'wallet_primary';

  final ValueNotifier<List<WalletCardModel>> cards;
  final ValueNotifier<String?> primaryCardId;
  final SharedPreferences _prefs;

  static Future<WalletController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_cardsKey) ?? <String>[];
    final cards = stored.map((raw) => _decode(raw)).toList();
    final primary = prefs.getString(_primaryKey);
    final controller = WalletController._(
      ValueNotifier(cards),
      ValueNotifier(primary),
      prefs,
    );
    controller.cards.addListener(() {
      final encoded = controller.cards.value.map(_encode).toList();
      prefs.setStringList(_cardsKey, encoded);
      if (controller.cards.value.isEmpty) {
        controller.primaryCardId.value = null;
      }
    });
    controller.primaryCardId.addListener(() {
      final value = controller.primaryCardId.value;
      if (value == null) {
        prefs.remove(_primaryKey);
      } else {
        prefs.setString(_primaryKey, value);
      }
    });
    if (controller.cards.value.isEmpty) {
      controller.seedDefaults();
    }
    return controller;
  }

  void seedDefaults() {
    cards.value = [
      WalletCardModel(
        id: 'card-1',
        label: 'Everyday Card',
        number: '4892 ****** 1028',
        balance: 4200.75,
        currency: 'USD',
        colors: const [Color(0xFF2BAA7D), Color(0xFF16302B)],
      ),
      WalletCardModel(
        id: 'card-2',
        label: 'Travel Jar',
        number: '5210 ****** 8841',
        balance: 1800.00,
        currency: 'USD',
        colors: const [Color(0xFF7D2BAA), Color(0xFF2B4EAA)],
      ),
    ];
    primaryCardId.value = cards.value.first.id;
  }

  void addCard(WalletCardModel card) {
    cards.value = [...cards.value, card];
    primaryCardId.value ??= card.id;
  }

  void removeCard(String id) {
    cards.value = cards.value.where((element) => element.id != id).toList();
    if (primaryCardId.value == id) {
      primaryCardId.value = cards.value.isEmpty ? null : cards.value.first.id;
    }
  }

  void makePrimary(String id) {
    if (cards.value.any((element) => element.id == id)) {
      primaryCardId.value = id;
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...cards.value];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    cards.value = list;
  }

  static WalletCardModel _decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return WalletCardModel(
      id: data['id'] as String,
      label: data['label'] as String,
      number: data['number'] as String,
      balance: (data['balance'] as num).toDouble(),
      currency: data['currency'] as String,
      colors: (data['colors'] as List<dynamic>)
          .map((value) => Color(value as int))
          .toList(),
    );
  }

  static String _encode(WalletCardModel card) {
    return jsonEncode({
      'id': card.id,
      'label': card.label,
      'number': card.number,
      'balance': card.balance,
      'currency': card.currency,
      'colors': card.colors.map((e) => e.value).toList(),
    });
  }

  void dispose() {
    cards.dispose();
    primaryCardId.dispose();
  }
}
