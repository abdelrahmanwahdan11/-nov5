import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/analytics.dart';
import '../data/models/transaction.dart';

class AnalyticsController {
  AnalyticsController._(
    this.rangeNotifier,
    this.summaryNotifier,
    this.heatmapNotifier,
    this.statementMonthNotifier,
    this.statementNotifier,
    this.availableMonthsNotifier,
    this._transactions,
    this._prefs,
  );

  final ValueNotifier<AnalyticsRange> rangeNotifier;
  final ValueNotifier<AnalyticsSummary> summaryNotifier;
  final ValueNotifier<List<HeatmapBucket>> heatmapNotifier;
  final ValueNotifier<DateTime> statementMonthNotifier;
  final ValueNotifier<StatementDocument> statementNotifier;
  final ValueNotifier<List<DateTime>> availableMonthsNotifier;

  final List<TransactionModel> _transactions;
  final SharedPreferences _prefs;

  static Future<AnalyticsController> load(
      List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final storedRange = prefs.getString(AppConstants.prefAnalyticsRange);
    final range = AnalyticsRange.values.firstWhere(
      (value) => value.name == storedRange,
      orElse: () => AnalyticsRange.month,
    );

    final truncated = _truncateToDayList(transactions);
    final months = _discoverMonths(truncated);
    final storedMonth = prefs.getString(AppConstants.prefStatementMonth);
    DateTime initialMonth = months.isNotEmpty ? months.first : _nowMonth();
    if (storedMonth != null) {
      final parts = storedMonth.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) {
          final candidate = DateTime(year, month);
          if (months.contains(candidate)) {
            initialMonth = candidate;
          }
        }
      }
    }

    final controller = AnalyticsController._(
      ValueNotifier<AnalyticsRange>(range),
      ValueNotifier<AnalyticsSummary>(_emptySummary()),
      ValueNotifier<List<HeatmapBucket>>(<HeatmapBucket>[]),
      ValueNotifier<DateTime>(initialMonth),
      ValueNotifier<StatementDocument>(StatementDocument(
        month: initialMonth,
        transactions: const <TransactionModel>[],
      )),
      ValueNotifier<List<DateTime>>(months),
      truncated,
      prefs,
    );

    controller._recomputeSummary();
    controller._recomputeStatement();
    return controller;
  }

  void updateRange(AnalyticsRange range) {
    if (rangeNotifier.value == range) return;
    rangeNotifier.value = range;
    _prefs.setString(AppConstants.prefAnalyticsRange, range.name);
    _recomputeSummary();
  }

  void selectStatementMonth(DateTime month) {
    if (_sameMonth(statementMonthNotifier.value, month)) {
      return;
    }
    statementMonthNotifier.value = month;
    _prefs.setString(
      AppConstants.prefStatementMonth,
      '${month.year}-${month.month.toString().padLeft(2, '0')}',
    );
    _recomputeStatement();
  }

  void rebuild(List<TransactionModel> transactions) {
    _transactions
      ..clear()
      ..addAll(_truncateToDayList(transactions));
    final months = _discoverMonths(_transactions);
    availableMonthsNotifier.value = months;
    if (months.isNotEmpty) {
      final selected = statementMonthNotifier.value;
      if (!months.contains(selected)) {
        statementMonthNotifier.value = months.first;
      }
    }
    _recomputeSummary();
    _recomputeStatement();
  }

  void _recomputeSummary() {
    if (_transactions.isEmpty) {
      summaryNotifier.value = _emptySummary();
      heatmapNotifier.value = <HeatmapBucket>[];
      return;
    }
    final now = DateTime.now();
    final range = rangeNotifier.value;
    final start = _startForRange(range, now);
    final filtered = _transactions
        .where((tx) => !tx.date.isBefore(start) && !tx.date.isAfter(now))
        .toList();
    if (filtered.isEmpty) {
      summaryNotifier.value = _emptySummary().copyWith(
        rangeStart: start,
        rangeEnd: now,
      );
      return;
    }

    final incomeSeries = _aggregateByDay(filtered, TransactionType.income);
    final expenseSeries = _aggregateByDay(filtered, TransactionType.expense);
    final netSeries = _buildNetSeries(incomeSeries, expenseSeries);
    final categories = _buildCategorySlices(filtered);
    final totalIncome = incomeSeries.fold<double>(0, (sum, point) => sum + point.value);
    final totalExpense = expenseSeries.fold<double>(0, (sum, point) => sum + point.value);

    summaryNotifier.value = AnalyticsSummary(
      rangeStart: start,
      rangeEnd: now,
      incomeSeries: incomeSeries,
      expenseSeries: expenseSeries,
      netSeries: netSeries,
      categorySlices: categories,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  void _recomputeStatement() {
    final month = statementMonthNotifier.value;
    final filtered = _transactions
        .where((tx) => tx.date.year == month.year && tx.date.month == month.month)
        .toList();
    statementNotifier.value = StatementDocument(
      month: month,
      transactions: filtered,
    );
    heatmapNotifier.value = _buildHeatmap(month, filtered);
  }

  List<HeatmapBucket> _buildHeatmap(
    DateTime month,
    List<TransactionModel> source,
  ) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final buckets = <HeatmapBucket>[];
    for (var day = 0; day < daysInMonth; day++) {
      final date = firstDay.add(Duration(days: day));
      final sameDay = source
          .where((tx) => tx.date.day == date.day && tx.type == TransactionType.expense)
          .toList();
      final total = sameDay.fold<double>(0, (sum, tx) => sum + tx.amount);
      final related = source
          .where((tx) => tx.date.day == date.day)
          .toList();
      buckets.add(HeatmapBucket(date: date, total: total, transactions: related));
    }
    return buckets;
  }

  static List<TransactionModel> _truncateToDayList(
      List<TransactionModel> transactions) {
    return transactions
        .map((tx) => tx.copyWith(date: DateTime(tx.date.year, tx.date.month, tx.date.day)))
        .toList();
  }

  static List<DateTime> _discoverMonths(List<TransactionModel> transactions) {
    final months = <DateTime>{};
    for (final tx in transactions) {
      months.add(DateTime(tx.date.year, tx.date.month));
    }
    final list = months.toList()
      ..sort((a, b) => b.compareTo(a));
    if (list.isEmpty) {
      list.add(_nowMonth());
    }
    return list;
  }

  static AnalyticsSummary _emptySummary() {
    final now = DateTime.now();
    return AnalyticsSummary(
      rangeStart: now,
      rangeEnd: now,
      incomeSeries: const <ChartPoint>[],
      expenseSeries: const <ChartPoint>[],
      netSeries: const <ChartPoint>[],
      categorySlices: const <CategorySlice>[],
      totalIncome: 0,
      totalExpense: 0,
    );
  }

  static DateTime _startForRange(AnalyticsRange range, DateTime now) {
    switch (range) {
      case AnalyticsRange.month:
        return DateTime(now.year, now.month, max(now.day - 29, 1));
      case AnalyticsRange.quarter:
        return now.subtract(const Duration(days: 90));
      case AnalyticsRange.year:
        return now.subtract(const Duration(days: 365));
    }
  }

  static List<ChartPoint> _aggregateByDay(
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    final map = <DateTime, double>{};
    for (final tx in transactions) {
      if (tx.type != type) continue;
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      map[key] = (map[key] ?? 0) + tx.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final entry in entries)
        ChartPoint(date: entry.key, value: entry.value),
    ];
  }

  static List<ChartPoint> _buildNetSeries(
    List<ChartPoint> income,
    List<ChartPoint> expense,
  ) {
    final allDates = <DateTime>{
      for (final point in income) point.date,
      for (final point in expense) point.date,
    }.toList()
      ..sort();
    return [
      for (final date in allDates)
        ChartPoint(
          date: date,
          value: (income.firstWhere(
                (point) => _sameDay(point.date, date),
                orElse: () => ChartPoint(date: date, value: 0),
              ).value -
              expense.firstWhere(
                (point) => _sameDay(point.date, date),
                orElse: () => ChartPoint(date: date, value: 0),
              ).value),
        ),
    ];
  }

  static List<CategorySlice> _buildCategorySlices(
      List<TransactionModel> transactions) {
    final palette = AppConstants.analyticsPalette;
    final map = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <CategorySlice>[];
    for (var i = 0; i < entries.length; i++) {
      final color = palette[i % palette.length];
      slices.add(CategorySlice(
        label: entries[i].key,
        value: entries[i].value,
        color: color,
      ));
    }
    return slices;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _sameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime _nowMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void dispose() {
    rangeNotifier.dispose();
    summaryNotifier.dispose();
    heatmapNotifier.dispose();
    statementMonthNotifier.dispose();
    statementNotifier.dispose();
    availableMonthsNotifier.dispose();
  }
}

extension on AnalyticsSummary {
  AnalyticsSummary copyWith({
    DateTime? rangeStart,
    DateTime? rangeEnd,
    List<ChartPoint>? incomeSeries,
    List<ChartPoint>? expenseSeries,
    List<ChartPoint>? netSeries,
    List<CategorySlice>? categorySlices,
    double? totalIncome,
    double? totalExpense,
  }) {
    return AnalyticsSummary(
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      incomeSeries: incomeSeries ?? this.incomeSeries,
      expenseSeries: expenseSeries ?? this.expenseSeries,
      netSeries: netSeries ?? this.netSeries,
      categorySlices: categorySlices ?? this.categorySlices,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}
