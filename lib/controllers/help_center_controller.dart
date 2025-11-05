import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/mock/mock_data.dart';
import '../data/models/help_article.dart';

class HelpCenterController {
  HelpCenterController._(
    this._prefs,
    List<String> history,
  )   : _allArticles = MockDataGenerator.knowledgeBase(),
        query = ValueNotifier<String>(''),
        selectedCategory = ValueNotifier<String?>(null),
        historyNotifier = ValueNotifier<List<String>>(history);

  final SharedPreferences _prefs;
  final List<HelpArticleModel> _allArticles;
  final ValueNotifier<String> query;
  final ValueNotifier<String?> selectedCategory;
  final ValueNotifier<List<String>> historyNotifier;

  static const int _historyLimit = 8;

  static Future<HelpCenterController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs
            .getStringList(AppConstants.prefHelpCenterHistory) ??
        const <String>[];
    return HelpCenterController._(prefs, history);
  }

  UnmodifiableListView<HelpArticleModel> get allArticles =>
      UnmodifiableListView(_allArticles);

  List<String> get categories {
    final set = <String>{};
    for (final article in _allArticles) {
      set.add(article.category);
    }
    return set.toList()..sort();
  }

  void updateQuery(String value) {
    if (query.value == value) {
      return;
    }
    query.value = value;
  }

  void setCategory(String? category) {
    if (selectedCategory.value == category) {
      return;
    }
    selectedCategory.value = category;
  }

  List<HelpArticleModel> get filteredArticles {
    final q = query.value.trim().toLowerCase();
    final category = selectedCategory.value;

    return _allArticles.where((article) {
      final matchesCategory =
          category == null || article.category == category;
      final matchesQuery = q.isEmpty
          ? true
          : article.title.toLowerCase().contains(q) ||
              article.body.toLowerCase().contains(q) ||
              article.tags.any((tag) => tag.toLowerCase().contains(q));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void addToHistory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final history = List<String>.from(historyNotifier.value);
    history.remove(trimmed);
    history.insert(0, trimmed);
    if (history.length > _historyLimit) {
      history.removeRange(_historyLimit, history.length);
    }
    historyNotifier.value = history;
    _prefs.setStringList(AppConstants.prefHelpCenterHistory, history);
  }

  void clearHistory() {
    historyNotifier.value = const [];
    _prefs.remove(AppConstants.prefHelpCenterHistory);
  }

  void removeFromHistory(String value) {
    final history = List<String>.from(historyNotifier.value);
    history.remove(value);
    historyNotifier.value = history;
    _prefs.setStringList(AppConstants.prefHelpCenterHistory, history);
  }

  void dispose() {
    query.dispose();
    selectedCategory.dispose();
    historyNotifier.dispose();
  }
}
