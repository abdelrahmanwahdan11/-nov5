import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/mock/mock_data.dart';
import '../data/models/recipient.dart';

class RecipientsController {
  RecipientsController._(this._allRecipients, this.favoritesNotifier);

  final List<RecipientModel> _allRecipients;
  final ValueNotifier<List<RecipientModel>> favoritesNotifier;

  static Future<RecipientsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefRecipients);

    List<RecipientModel> recipients;
    if (stored == null) {
      recipients = MockDataGenerator.generateRecipients();
      await _persistRecipients(recipients);
    } else {
      recipients = stored
          .map((entry) =>
              RecipientModel.fromJson(utf8.decode(base64Decode(entry))))
          .toList();
    }

    final favorites =
        recipients.where((recipient) => recipient.isFavorite).toList();

    return RecipientsController._(
      recipients,
      ValueNotifier<List<RecipientModel>>(favorites),
    );
  }

  List<RecipientModel> get allRecipients =>
      List<RecipientModel>.unmodifiable(_allRecipients);

  Future<void> toggleFavorite(String id) async {
    final updated = _allRecipients.map((recipient) {
      if (recipient.id == id) {
        return recipient.copyWith(isFavorite: !recipient.isFavorite);
      }
      return recipient;
    }).toList();
    await _replace(updated);
  }

  Future<void> setQuickAmount(String id, double amount) async {
    final updated = _allRecipients.map((recipient) {
      if (recipient.id == id) {
        return recipient.copyWith(quickAmount: amount);
      }
      return recipient;
    }).toList();
    await _replace(updated);
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final favorites = [...favoritesNotifier.value];
    final item = favorites.removeAt(oldIndex);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    favorites.insert(targetIndex, item);

    final nonFavorites =
        _allRecipients.where((recipient) => !recipient.isFavorite).toList();
    favoritesNotifier.value = favorites;
    await _replace([...favorites, ...nonFavorites]);
  }

  Future<void> _replace(List<RecipientModel> updated) async {
    _allRecipients
      ..clear()
      ..addAll(updated);
    favoritesNotifier.value =
        updated.where((recipient) => recipient.isFavorite).toList();
    await _persistRecipients(_allRecipients);
  }

  static Future<void> _persistRecipients(List<RecipientModel> recipients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefRecipients,
      recipients
          .map((recipient) => base64Encode(utf8.encode(recipient.toJson())))
          .toList(growable: false),
    );
  }

  void dispose() {
    favoritesNotifier.dispose();
  }
}
