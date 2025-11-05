import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock/mock_data.dart';
import '../data/models/transaction.dart';

class TransactionsController extends ChangeNotifier {
  TransactionsController._(this._prefs) {
    _allTransactions = MockData.transactions();
    _filteredTransactions = List.from(_allTransactions);
  }

  static const _historyKey = 'search_history';

  late List<TransactionModel> _allTransactions;
  late List<TransactionModel> _filteredTransactions;
  final ValueNotifier<String> query = ValueNotifier('');
  final ValueNotifier<List<String>> history = ValueNotifier([]);
  final SharedPreferences _prefs;

  List<TransactionModel> get allTransactions => UnmodifiableListView(_allTransactions);
  List<TransactionModel> get filteredTransactions =>
      UnmodifiableListView(_filteredTransactions);

  static Future<TransactionsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TransactionsController._(prefs);
    controller.history.value = prefs.getStringList(_historyKey) ?? [];
    controller.query.addListener(() {
      controller._applyFilter(controller.query.value);
    });
    return controller;
  }

  void _applyFilter(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      _filteredTransactions = List.from(_allTransactions);
    } else {
      _filteredTransactions = _allTransactions
          .where((transaction) =>
              transaction.title.toLowerCase().contains(normalized) ||
              transaction.category.toLowerCase().contains(normalized))
          .toList();
    }
    notifyListeners();
  }

  void addTransaction(TransactionModel model) {
    _allTransactions = [model, ..._allTransactions];
    _applyFilter(query.value);
  }

  void updateHistory(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    final list = [...history.value];
    list.remove(normalized);
    list.insert(0, normalized);
    if (list.length > 10) {
      list.removeLast();
    }
    history.value = list;
    _prefs.setStringList(_historyKey, list);
  }

  @override
  void dispose() {
    query.dispose();
    history.dispose();
    super.dispose();
  }
}
