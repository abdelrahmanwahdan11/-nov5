import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/transaction.dart';

class SearchController {
  SearchController._(this.suggestions, this.historyNotifier, this._source);

  final ValueNotifier<List<String>> suggestions;
  final ValueNotifier<List<String>> historyNotifier;
  final List<TransactionModel> _source;

  String _currentQuery = '';

  static Future<SearchController> load(
      List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefSearchHistory) ?? <String>[];
    final decoded = <String>[];
    var sanitized = false;
    for (final value in stored) {
      try {
        final entry = utf8.decode(base64Decode(value)).trim();
        if (entry.isEmpty) {
          sanitized = true;
          continue;
        }
        if (decoded.contains(entry)) {
          sanitized = true;
          continue;
        }
        decoded.add(entry);
      } on FormatException {
        sanitized = true;
      }
    }
    if (sanitized) {
      await prefs.setStringList(
        AppConstants.prefSearchHistory,
        decoded.map((value) => base64Encode(utf8.encode(value))).toList(),
      );
    }
    return SearchController._(
      ValueNotifier<List<String>>(<String>[]),
      ValueNotifier<List<String>>(decoded),
      List<TransactionModel>.from(transactions),
    );
  }

  void updateQuery(String query) {
    _currentQuery = query;
    if (query.trim().isEmpty) {
      suggestions.value = <String>[];
      return;
    }
    final lower = query.toLowerCase();
    final matches = _source
        .where((tx) =>
            tx.title.toLowerCase().contains(lower) ||
            tx.merchant.toLowerCase().contains(lower) ||
            tx.tags.any((tag) => tag.toLowerCase().contains(lower)))
        .map((tx) => tx.title)
        .toSet()
        .take(6)
        .toList();
    suggestions.value = matches;
  }

  Future<void> addToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final entries = [...historyNotifier.value];
    entries.remove(trimmed);
    entries.insert(0, trimmed);
    if (entries.length > 10) {
      entries.removeRange(10, entries.length);
    }
    historyNotifier.value = entries;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefSearchHistory,
      entries.map((value) => base64Encode(utf8.encode(value))).toList(),
    );
  }

  Future<void> clearHistory() async {
    historyNotifier.value = <String>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSearchHistory);
  }

  String get currentQuery => _currentQuery;

  void dispose() {
    suggestions.dispose();
    historyNotifier.dispose();
  }

  void rebuildSource(List<TransactionModel> transactions) {
    _source
      ..clear()
      ..addAll(transactions);
    if (_currentQuery.isNotEmpty) {
      updateQuery(_currentQuery);
    }
  }
}
