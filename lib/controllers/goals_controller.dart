import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/mock/mock_data.dart';
import '../data/models/savings_goal.dart';

class GoalsController {
  GoalsController._(this.goalsNotifier);

  final ValueNotifier<List<SavingsGoalModel>> goalsNotifier;

  static Future<GoalsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefSavingsGoals);
    final goals = stored == null
        ? MockDataGenerator.defaultSavingsGoals()
        : stored
            .map((entry) =>
                SavingsGoalModel.fromJson(utf8.decode(base64Decode(entry))))
            .toList();

    return GoalsController._(
      ValueNotifier<List<SavingsGoalModel>>(goals),
    );
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    final goals = [...goalsNotifier.value, goal];
    goalsNotifier.value = goals;
    await _persist(goals);
  }

  Future<void> updateGoal(SavingsGoalModel updated) async {
    final goals = goalsNotifier.value.map((goal) {
      if (goal.id == updated.id) {
        return updated;
      }
      return goal;
    }).toList();
    goalsNotifier.value = goals;
    await _persist(goals);
  }

  Future<void> adjustProgress(String id, double delta) async {
    final goals = goalsNotifier.value.map((goal) {
      if (goal.id != id) return goal;
      final nextAmount = (goal.currentAmount + delta).clamp(0, goal.targetAmount);
      return goal.copyWith(currentAmount: nextAmount);
    }).toList();
    goalsNotifier.value = goals;
    await _persist(goals);
  }

  Future<void> deleteGoal(String id) async {
    final goals = goalsNotifier.value.where((goal) => goal.id != id).toList();
    goalsNotifier.value = goals;
    await _persist(goals);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final goals = [...goalsNotifier.value];
    final goal = goals.removeAt(oldIndex);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    goals.insert(targetIndex, goal);
    goalsNotifier.value = goals;
    await _persist(goals);
  }

  Future<void> _persist(List<SavingsGoalModel> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefSavingsGoals,
      goals
          .map((goal) => base64Encode(utf8.encode(goal.toJson())))
          .toList(growable: false),
    );
  }

  void dispose() {
    goalsNotifier.dispose();
  }
}
