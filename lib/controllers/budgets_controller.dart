import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/budget.dart';

class BudgetsController {
  BudgetsController._(this.budgets, this._prefs);

  static const _budgetsKey = 'budgets';

  final ValueNotifier<List<BudgetModel>> budgets;
  final SharedPreferences _prefs;

  static Future<BudgetsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_budgetsKey) ?? <String>[];
    final budgets = stored.map((raw) => _decode(raw)).toList();
    final controller = BudgetsController._(ValueNotifier(budgets), prefs);
    controller.budgets.addListener(() {
      prefs.setStringList(
        _budgetsKey,
        controller.budgets.value.map(_encode).toList(),
      );
    });
    if (controller.budgets.value.isEmpty) {
      controller.seedDefaults();
    }
    return controller;
  }

  void seedDefaults() {
    budgets.value = [
      BudgetModel(id: 'food', label: 'Food', limit: 600, spent: 320),
      BudgetModel(id: 'travel', label: 'Travel', limit: 400, spent: 90),
    ];
  }

  void upsert(BudgetModel budget) {
    final list = [...budgets.value];
    final index = list.indexWhere((element) => element.id == budget.id);
    if (index >= 0) {
      list[index] = budget;
    } else {
      list.add(budget);
    }
    budgets.value = list;
  }

  void delete(String id) {
    budgets.value = budgets.value.where((element) => element.id != id).toList();
  }

  static BudgetModel _decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return BudgetModel(
      id: data['id'] as String,
      label: data['label'] as String,
      limit: (data['limit'] as num).toDouble(),
      spent: (data['spent'] as num).toDouble(),
    );
  }

  static String _encode(BudgetModel budget) {
    return jsonEncode({
      'id': budget.id,
      'label': budget.label,
      'limit': budget.limit,
      'spent': budget.spent,
    });
  }

  void dispose() {
    budgets.dispose();
  }
}
