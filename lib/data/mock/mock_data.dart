import 'dart:math';

import '../models/budget.dart';
import '../models/transaction.dart';

class MockDataGenerator {
  MockDataGenerator._();

  static final _random = Random(42);

  static List<TransactionModel> generateTransactions({int count = 120}) {
    final categories = [
      'Groceries',
      'Transport',
      'Dining',
      'Subscriptions',
      'Investments',
      'Utilities',
      'Travel',
    ];

    final merchants = [
      'Fresh Market',
      'City Taxi',
      'Skyline Bistro',
      'StreamFlix',
      'Green Investments',
      'PowerGrid',
      'AeroFly',
    ];

    final tagPool = [
      'family',
      'work',
      'personal',
      'weekly',
      'monthly',
      'urgent',
      'fun',
    ];

    return List.generate(count, (index) {
      final category = categories[_random.nextInt(categories.length)];
      final merchant = merchants[_random.nextInt(merchants.length)];
      final type = _random.nextBool()
          ? TransactionType.expense
          : TransactionType.income;
      final amount =
          (type == TransactionType.expense ? 20 : 60) + _random.nextInt(400);
      final status = TransactionStatus.values
          [_random.nextInt(TransactionStatus.values.length)];
      final tags = List.generate(1 + _random.nextInt(3), (_) {
        return tagPool[_random.nextInt(tagPool.length)];
      }).toSet().toList();

      return TransactionModel(
        id: 'tx_$index',
        title: '$category purchase',
        description: '$merchant • ${category.toLowerCase()}',
        amount: amount.toDouble(),
        currency: 'USD',
        category: category,
        tags: tags,
        date: DateTime.now().subtract(Duration(days: index ~/ 3, hours: index)),
        type: type,
        status: status,
        merchant: merchant,
      );
    });
  }

  static List<BudgetModel> defaultBudgets() {
    final categories = [
      {
        'category': 'Groceries',
        'limit': 600.0,
        'spent': 420.0,
        'color': 0xFF2BAA7D,
      },
      {
        'category': 'Dining',
        'limit': 300.0,
        'spent': 280.0,
        'color': 0xFF4C7AF0,
      },
      {
        'category': 'Transport',
        'limit': 180.0,
        'spent': 90.0,
        'color': 0xFFFA7A55,
      },
    ];

    return [
      for (var i = 0; i < categories.length; i++)
        BudgetModel(
          id: 'budget_$i',
          category: categories[i]['category'] as String,
          limit: categories[i]['limit'] as double,
          spent: categories[i]['spent'] as double,
          color: categories[i]['color'] as int,
        ),
    ];
  }
}
