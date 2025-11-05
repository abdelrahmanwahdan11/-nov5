import 'dart:convert';

import 'transaction.dart';

enum RecurringFrequency { weekly, monthly, quarterly, yearly }

class RecurringPaymentModel {
  const RecurringPaymentModel({
    required this.id,
    required this.title,
    required this.recipient,
    required this.amount,
    required this.currency,
    required this.category,
    required this.frequency,
    required this.nextDate,
    required this.color,
    required this.note,
  });

  final String id;
  final String title;
  final String recipient;
  final double amount;
  final String currency;
  final String category;
  final RecurringFrequency frequency;
  final DateTime nextDate;
  final int color;
  final String note;

  RecurringPaymentModel copyWith({
    String? title,
    String? recipient,
    double? amount,
    String? currency,
    String? category,
    RecurringFrequency? frequency,
    DateTime? nextDate,
    int? color,
    String? note,
  }) {
    return RecurringPaymentModel(
      id: id,
      title: title ?? this.title,
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      color: color ?? this.color,
      note: note ?? this.note,
    );
  }

  TransactionModel toTransaction() {
    return TransactionModel(
      id: 'scheduled_${DateTime.now().millisecondsSinceEpoch}_$id',
      title: title,
      description: '$recipient • $note',
      amount: amount,
      currency: currency,
      category: category,
      tags: <String>{'scheduled', frequency.name}.toList(),
      date: DateTime.now(),
      type: TransactionType.expense,
      status: TransactionStatus.completed,
      merchant: recipient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'recipient': recipient,
      'amount': amount,
      'currency': currency,
      'category': category,
      'frequency': frequency.name,
      'nextDate': nextDate.toIso8601String(),
      'color': color,
      'note': note,
    };
  }

  static RecurringPaymentModel fromMap(Map<String, dynamic> map) {
    return RecurringPaymentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      recipient: map['recipient'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      category: map['category'] as String,
      frequency: RecurringFrequency.values
          .firstWhere((value) => value.name == map['frequency'] as String),
      nextDate: DateTime.parse(map['nextDate'] as String),
      color: map['color'] as int,
      note: map['note'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  static RecurringPaymentModel fromJson(String source) =>
      fromMap(jsonDecode(source) as Map<String, dynamic>);
}

Duration recurringFrequencyToDuration(RecurringFrequency frequency) {
  switch (frequency) {
    case RecurringFrequency.weekly:
      return const Duration(days: 7);
    case RecurringFrequency.monthly:
      return const Duration(days: 30);
    case RecurringFrequency.quarterly:
      return const Duration(days: 90);
    case RecurringFrequency.yearly:
      return const Duration(days: 365);
  }
}
