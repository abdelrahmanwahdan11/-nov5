import 'dart:convert';

enum TransactionType { income, expense }

enum TransactionStatus { completed, pending, scheduled }

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.tags,
    required this.date,
    required this.type,
    required this.status,
    required this.merchant,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final List<String> tags;
  final DateTime date;
  final TransactionType type;
  final TransactionStatus status;
  final String merchant;

  TransactionModel copyWith({
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
    List<String>? tags,
    DateTime? date,
    TransactionType? type,
    TransactionStatus? status,
    String? merchant,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      merchant: merchant ?? this.merchant,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'tags': tags,
      'date': date.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'merchant': merchant,
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      category: map['category'] as String,
      tags: List<String>.from(map['tags'] as List<dynamic>),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values
          .firstWhere((e) => e.name == map['type'] as String),
      status: TransactionStatus.values
          .firstWhere((e) => e.name == map['status'] as String),
      merchant: map['merchant'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  static TransactionModel fromJson(String source) =>
      fromMap(jsonDecode(source) as Map<String, dynamic>);
}
