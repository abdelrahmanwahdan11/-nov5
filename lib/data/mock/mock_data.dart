import '../models/transaction.dart';

class MockData {
  static List<TransactionModel> transactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 't1',
        title: 'Coffee House',
        category: 'Food & Drink',
        amount: 4.50,
        date: now.subtract(const Duration(days: 1)),
        isExpense: true,
      ),
      TransactionModel(
        id: 't2',
        title: 'Ride Sharing',
        category: 'Transport',
        amount: 12.20,
        date: now.subtract(const Duration(days: 2)),
        isExpense: true,
      ),
      TransactionModel(
        id: 't3',
        title: 'Salary',
        category: 'Income',
        amount: 2200.0,
        date: now.subtract(const Duration(days: 3)),
        isExpense: false,
      ),
      TransactionModel(
        id: 't4',
        title: 'Grocery Store',
        category: 'Groceries',
        amount: 76.90,
        date: now.subtract(const Duration(days: 4)),
        isExpense: true,
      ),
    ];
  }
}
