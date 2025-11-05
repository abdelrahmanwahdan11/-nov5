import 'package:flutter/material.dart';

import 'transaction.dart';

enum AnalyticsRange { month, quarter, year }

class ChartPoint {
  const ChartPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class HeatmapBucket {
  const HeatmapBucket({
    required this.date,
    required this.total,
    required this.transactions,
  });

  final DateTime date;
  final double total;
  final List<TransactionModel> transactions;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.rangeStart,
    required this.rangeEnd,
    required this.incomeSeries,
    required this.expenseSeries,
    required this.netSeries,
    required this.categorySlices,
    required this.totalIncome,
    required this.totalExpense,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<ChartPoint> incomeSeries;
  final List<ChartPoint> expenseSeries;
  final List<ChartPoint> netSeries;
  final List<CategorySlice> categorySlices;
  final double totalIncome;
  final double totalExpense;

  double get savingsRate {
    if (totalIncome <= 0) {
      return 0;
    }
    final delta = totalIncome - totalExpense;
    return (delta / totalIncome).clamp(-1.0, 1.0);
  }
}

class StatementDocument {
  StatementDocument({
    required this.month,
    required List<TransactionModel> transactions,
  }) : transactions = List<TransactionModel>.from(transactions)
          ..sort((a, b) => b.date.compareTo(a.date));

  final DateTime month;
  final List<TransactionModel> transactions;

  double get totalIncome => transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get net => totalIncome - totalExpense;

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final tx in transactions) {
      final current = totals[tx.category] ?? 0;
      totals[tx.category] = current + tx.amount;
    }
    return totals;
  }

  Map<String, Object?> toSerializableMap() {
    return {
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net': net,
      'transactions': [
        for (final tx in transactions)
          {
            'id': tx.id,
            'title': tx.title,
            'amount': tx.amount,
            'currency': tx.currency,
            'category': tx.category,
            'tags': tx.tags,
            'date': tx.date.toIso8601String(),
            'type': tx.type.name,
            'status': tx.status.name,
            'merchant': tx.merchant,
          }
      ],
    };
  }
}
