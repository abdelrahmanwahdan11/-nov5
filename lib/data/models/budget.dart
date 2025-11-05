class BudgetModel {
  BudgetModel({
    required this.id,
    required this.label,
    required this.limit,
    required this.spent,
  });

  final String id;
  final String label;
  final double limit;
  final double spent;

  BudgetModel copyWith({String? label, double? limit, double? spent}) {
    return BudgetModel(
      id: id,
      label: label ?? this.label,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
    );
  }
}
