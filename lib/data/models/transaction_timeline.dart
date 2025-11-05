import 'transaction.dart';

class TransactionTimelineSection {
  TransactionTimelineSection({
    required this.label,
    required this.total,
    required this.transactions,
    required this.date,
  });

  final String label;
  final double total;
  final List<TransactionModel> transactions;
  final DateTime date;
}
