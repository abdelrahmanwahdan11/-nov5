import 'dart:convert';

class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.color,
    required this.imageUrl,
    required this.dueDate,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int color;
  final String imageUrl;
  final DateTime dueDate;

  double get progress => targetAmount == 0
      ? 0
      : (currentAmount / targetAmount).clamp(0, 1);

  SavingsGoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? color,
    String? imageUrl,
    DateTime? dueDate,
  }) {
    return SavingsGoalModel(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'color': color,
      'imageUrl': imageUrl,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  static SavingsGoalModel fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      color: map['color'] as int,
      imageUrl: map['imageUrl'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  static SavingsGoalModel fromJson(String source) =>
      fromMap(jsonDecode(source) as Map<String, dynamic>);
}
