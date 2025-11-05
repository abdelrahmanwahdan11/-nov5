import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/transaction.dart';

class SearchController {
  SearchController._(
    this.suggestions,
    this.historyNotifier,
    this._source,
    this._index,
    this._idToTransaction,
  );

  final ValueNotifier<List<String>> suggestions;
  final ValueNotifier<List<String>> historyNotifier;
  final List<TransactionModel> _source;
  final Map<String, Set<String>> _index;
  final Map<String, TransactionModel> _idToTransaction;

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

    final source = List<TransactionModel>.from(transactions);
    final index = <String, Set<String>>{};
    final idToTransaction = <String, TransactionModel>{};
    _rebuildIndex(source, index, idToTransaction);

    return SearchController._(
      ValueNotifier<List<String>>(<String>[]),
      ValueNotifier<List<String>>(decoded),
      source,
      index,
      idToTransaction,
    );
  }

  void updateQuery(String query) {
    _currentQuery = query;
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      suggestions.value = <String>[];
      return;
    }
    final grams = _ngrams(normalized);
    if (grams.isEmpty) {
      suggestions.value = <String>[];
      return;
    }

    Set<String>? matches;
    for (final gram in grams) {
      final ids = _index[gram];
      if (ids == null) continue;
      matches = matches == null ? Set<String>.from(ids) : matches.intersection(ids);
      if (matches.isEmpty) {
        break;
      }
    }

    if (matches == null || matches.isEmpty) {
      suggestions.value = <String>[];
      return;
    }

    final scored = <_ScoredResult>[];
    for (final id in matches) {
      final transaction = _idToTransaction[id];
      if (transaction == null) continue;
      final score = _score(transaction, normalized);
      scored.add(_ScoredResult(transaction, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    final unique = <String>[];
    for (final result in scored) {
      if (!unique.contains(result.transaction.title)) {
        unique.add(result.transaction.title);
      }
      if (unique.length >= 6) break;
    }
    suggestions.value = unique;
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
    _rebuildIndex(_source, _index, _idToTransaction);
    if (_currentQuery.isNotEmpty) {
      updateQuery(_currentQuery);
    }
  }

  static void _rebuildIndex(
    List<TransactionModel> source,
    Map<String, Set<String>> index,
    Map<String, TransactionModel> idToTransaction,
  ) {
    index.clear();
    idToTransaction.clear();
    for (final tx in source) {
      idToTransaction[tx.id] = tx;
      final tokens = _tokenize(tx);
      for (final token in tokens) {
        index.putIfAbsent(token, () => <String>{}).add(tx.id);
      }
    }
  }

  static Set<String> _tokenize(TransactionModel transaction) {
    final fields = <String>{
      transaction.title,
      transaction.description,
      transaction.merchant,
      transaction.category,
      ...transaction.tags,
    };
    final tokens = <String>{};
    for (final field in fields) {
      final normalized = _normalize(field);
      if (normalized.isEmpty) continue;
      final parts = normalized.split(RegExp(r'[^a-z0-9؀-ۿ]+'));
      for (final part in parts) {
        if (part.isEmpty) continue;
        tokens.add(part);
        tokens.addAll(_ngrams(part));
      }
    }
    return tokens;
  }

  static String _normalize(String value) {
    return value.toLowerCase();
  }

  static Set<String> _ngrams(String value) {
    final cleaned = value.toLowerCase();
    final grams = <String>{};
    if (cleaned.length <= 2) {
      grams.add(cleaned);
      return grams;
    }
    const min = 2;
    final max = cleaned.length >= 4 ? 4 : cleaned.length;
    for (var size = min; size <= max; size++) {
      for (var i = 0; i <= cleaned.length - size; i++) {
        grams.add(cleaned.substring(i, i + size));
      }
    }
    return grams;
  }

  static double _score(TransactionModel transaction, String query) {
    final normalizedQuery = query.toLowerCase();
    var score = 0.0;
    if (transaction.title.toLowerCase().contains(normalizedQuery)) {
      score += 5;
    }
    if (transaction.merchant.toLowerCase().contains(normalizedQuery)) {
      score += 3;
    }
    if (transaction.description.toLowerCase().contains(normalizedQuery)) {
      score += 1.5;
    }
    for (final tag in transaction.tags) {
      if (tag.toLowerCase().contains(normalizedQuery)) {
        score += 1;
      }
    }
    return score;
  }
}

class _ScoredResult {
  _ScoredResult(this.transaction, this.score);

  final TransactionModel transaction;
  final double score;
}
