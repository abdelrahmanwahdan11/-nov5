import 'dart:convert';

class BudgetModel {
  BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.color,
  });

  final String id;
  final String category;
  final double limit;
  final double spent;
  final int color;

  double get progress => limit == 0 ? 0 : (spent / limit).clamp(0, 1.2);
  double get remaining => limit - spent;

  BudgetModel copyWith({
    String? category,
    double? limit,
    double? spent,
    int? color,
  }) {
    return BudgetModel(
      id: id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'spent': spent,
      'color': color,
    };
  }

  static BudgetModel fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
      color: map['color'] as int,
    );
  }

  String toJson() => jsonEncode(toMap());

  static BudgetModel fromJson(String source) =>
      fromMap(jsonDecode(source) as Map<String, dynamic>);
}
