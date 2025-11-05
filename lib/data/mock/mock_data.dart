import 'dart:math';

import '../models/budget.dart';
import '../models/recipient.dart';
import '../models/recurring_payment.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wallet_card.dart';

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

  static List<WalletCardModel> defaultWalletCards() {
    return [
      WalletCardModel(
        id: 'wallet_primary',
        title: 'Everyday Wallet',
        holderName: 'Laila Youssef',
        cardNumber: '4581 3289 9912 5541',
        balance: 4820.75,
        currency: 'USD',
        gradient: const [0xFF2BAA7D, 0xFF58C6A3],
        expiry: '09/27',
        network: 'VISA',
      ),
      WalletCardModel(
        id: 'wallet_travel',
        title: 'Travel Stash',
        holderName: 'Laila Youssef',
        cardNumber: '5392 1100 8823 9472',
        balance: 1810.40,
        currency: 'EUR',
        gradient: const [0xFF3A7BFF, 0xFF7FA6FF],
        expiry: '01/28',
        network: 'Mastercard',
      ),
      WalletCardModel(
        id: 'wallet_savings',
        title: 'Dream Home Fund',
        holderName: 'Laila Youssef',
        cardNumber: '6020 9988 5554 3001',
        balance: 12650.00,
        currency: 'AED',
        gradient: const [0xFF9B5DE5, 0xFFB48BFF],
        expiry: '12/29',
        network: 'Amethyst',
      ),
    ];
  }

  static List<SavingsGoalModel> defaultSavingsGoals() {
    final now = DateTime.now();
    return [
      SavingsGoalModel(
        id: 'goal_getaway',
        name: 'Island Getaway',
        targetAmount: 4800,
        currentAmount: 2150,
        color: 0xFF2BAA7D,
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=60',
        dueDate: DateTime(now.year, now.month + 6, 1),
      ),
      SavingsGoalModel(
        id: 'goal_camera',
        name: 'Cinema Rig Upgrade',
        targetAmount: 3200,
        currentAmount: 1475,
        color: 0xFF9B5DE5,
        imageUrl:
            'https://images.unsplash.com/photo-1484704849700-f032a568e944?auto=format&fit=crop&w=800&q=60',
        dueDate: DateTime(now.year, now.month + 3, 15),
      ),
      SavingsGoalModel(
        id: 'goal_education',
        name: 'Design Masterclass',
        targetAmount: 2200,
        currentAmount: 880,
        color: 0xFFFF8A3D,
        imageUrl:
            'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?auto=format&fit=crop&w=800&q=60',
        dueDate: DateTime(now.year, now.month + 2, 20),
      ),
    ];
  }

  static List<RecipientModel> generateRecipients() {
    const avatars = [
      'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=400&q=60',
      'https://images.unsplash.com/photo-1552058544-f2b08422138a?auto=format&fit=crop&w=400&q=60',
      'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=400&q=60',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=60',
      'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=400&q=60',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=60',
    ];

    final names = [
      'Omar Nasser',
      'Salma Haddad',
      'Yara Al Farsi',
      'Karim Alami',
      'Maya Benali',
      'Noah Idris',
    ];

    return [
      for (var i = 0; i < names.length; i++)
        RecipientModel(
          id: 'recipient_$i',
          name: names[i],
          avatarUrl: avatars[i % avatars.length],
          handle: '@${names[i].split(' ').first.toLowerCase()}',
          quickAmount: 150 + (_random.nextInt(5) * 50),
          currency: 'USD',
          isFavorite: i < 3,
        ),
    ];
  }

  static List<RecurringPaymentModel> defaultRecurringPayments() {
    final now = DateTime.now();
    return [
      RecurringPaymentModel(
        id: 'rec_rent',
        title: 'Downtown Loft Rent',
        recipient: 'Skyline Properties',
        amount: 1350,
        currency: 'USD',
        category: 'Housing',
        frequency: RecurringFrequency.monthly,
        nextDate: DateTime(now.year, now.month, 28),
        color: 0xFF4C7AF0,
        note: 'Auto debit at noon',
      ),
      RecurringPaymentModel(
        id: 'rec_gym',
        title: 'Gym Membership',
        recipient: 'Pulse Athletics',
        amount: 75,
        currency: 'USD',
        category: 'Health',
        frequency: RecurringFrequency.monthly,
        nextDate: DateTime(now.year, now.month, 12),
        color: 0xFF2BAA7D,
        note: 'Includes sauna access',
      ),
      RecurringPaymentModel(
        id: 'rec_classes',
        title: 'Motion Design Course',
        recipient: 'Creative School',
        amount: 190,
        currency: 'USD',
        category: 'Education',
        frequency: RecurringFrequency.weekly,
        nextDate: now.add(const Duration(days: 5)),
        color: 0xFFFF8A3D,
        note: 'Friday live stream',
      ),
    ];
  }
}
