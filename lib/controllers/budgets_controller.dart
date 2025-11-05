import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/budget.dart';
import '../data/mock/mock_data.dart';

class BudgetsController {
  BudgetsController._(this.budgetsNotifier);

  final ValueNotifier<List<BudgetModel>> budgetsNotifier;

  static Future<BudgetsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefBudgets);
    final budgets = stored == null || stored.isEmpty
        ? MockDataGenerator.defaultBudgets()
        : stored
            .map((item) =>
                BudgetModel.fromMap(jsonDecode(item) as Map<String, dynamic>))
            .toList();

    return BudgetsController._(ValueNotifier<List<BudgetModel>>(budgets));
  }

  Future<void> addBudget(BudgetModel budget) async {
    final items = [...budgetsNotifier.value, budget];
    budgetsNotifier.value = items;
    await _persist();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final items = budgetsNotifier.value
        .map((b) => b.id == budget.id ? budget : b)
        .toList();
    budgetsNotifier.value = items;
    await _persist();
  }

  Future<void> deleteBudget(String id) async {
    final items = budgetsNotifier.value.where((b) => b.id != id).toList();
    budgetsNotifier.value = items;
    await _persist();
  }

  Future<void> updateSpent(String id, double spent) async {
    final items = budgetsNotifier.value
        .map((b) => b.id == id ? b.copyWith(spent: spent) : b)
        .toList();
    budgetsNotifier.value = items;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = budgetsNotifier.value
        .map((budget) => jsonEncode(budget.toMap()))
        .toList();
    await prefs.setStringList(AppConstants.prefBudgets, encoded);
  }

  void dispose() {
    budgetsNotifier.dispose();
  }
}
