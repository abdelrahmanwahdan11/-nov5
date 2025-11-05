import 'dart:convert';

import 'transaction.dart';

class TransactionFilterDefinition {
  TransactionFilterDefinition({
    required this.id,
    required this.name,
    this.category,
    this.tags = const <String>[],
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.type,
    this.status,
    this.merchant,
  });

  final String id;
  final String name;
  final String? category;
  final List<String> tags;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final TransactionStatus? status;
  final String? merchant;

  TransactionFilterDefinition copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? tags,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
    String? merchant,
  }) {
    return TransactionFilterDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      tags: tags ?? List<String>.from(this.tags),
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      merchant: merchant ?? this.merchant,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'tags': tags,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'type': type?.name,
      'status': status?.name,
      'merchant': merchant,
    };
  }

  factory TransactionFilterDefinition.fromMap(Map<String, dynamic> map) {
    return TransactionFilterDefinition(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? const []),
      minAmount: (map['minAmount'] as num?)?.toDouble(),
      maxAmount: (map['maxAmount'] as num?)?.toDouble(),
      startDate: map['startDate'] == null
          ? null
          : DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] == null
          ? null
          : DateTime.parse(map['endDate'] as String),
      type: map['type'] == null
          ? null
          : TransactionType.values
              .firstWhere((value) => value.name == map['type']),
      status: map['status'] == null
          ? null
          : TransactionStatus.values
              .firstWhere((value) => value.name == map['status']),
      merchant: map['merchant'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TransactionFilterDefinition.fromJson(String source) =>
      TransactionFilterDefinition.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );
}
