import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/mock/mock_data.dart';
import '../data/models/recurring_payment.dart';
import '../data/models/transaction.dart';

class RecurringPaymentsController {
  RecurringPaymentsController._(this.paymentsNotifier);

  final ValueNotifier<List<RecurringPaymentModel>> paymentsNotifier;

  static Future<RecurringPaymentsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.prefRecurringPayments);

    final payments = stored == null
        ? MockDataGenerator.defaultRecurringPayments()
        : stored
            .map((entry) => RecurringPaymentModel.fromJson(
                utf8.decode(base64Decode(entry))))
            .toList();

    return RecurringPaymentsController._(
      ValueNotifier<List<RecurringPaymentModel>>(payments),
    );
  }

  Future<void> addPayment(RecurringPaymentModel payment) async {
    final payments = [...paymentsNotifier.value, payment];
    paymentsNotifier.value = payments;
    await _persist(payments);
  }

  Future<void> updatePayment(RecurringPaymentModel payment) async {
    final payments = paymentsNotifier.value.map((item) {
      if (item.id == payment.id) {
        return payment;
      }
      return item;
    }).toList();
    paymentsNotifier.value = payments;
    await _persist(payments);
  }

  Future<void> deletePayment(String id) async {
    final payments =
        paymentsNotifier.value.where((payment) => payment.id != id).toList();
    paymentsNotifier.value = payments;
    await _persist(payments);
  }

  Future<void> postpone(String id) async {
    final payments = paymentsNotifier.value.map((payment) {
      if (payment.id == id) {
        return payment.copyWith(
          nextDate: payment.nextDate.add(
            recurringFrequencyToDuration(payment.frequency),
          ),
        );
      }
      return payment;
    }).toList();
    paymentsNotifier.value = payments;
    await _persist(payments);
  }

  Future<TransactionModel?> execute(String id) async {
    final payments = [...paymentsNotifier.value];
    final index = payments.indexWhere((payment) => payment.id == id);
    if (index == -1) return null;
    final payment = payments[index];
    final transaction = payment.toTransaction();
    payments[index] = payment.copyWith(
      nextDate: payment.nextDate.add(
        recurringFrequencyToDuration(payment.frequency),
      ),
    );
    paymentsNotifier.value = payments;
    await _persist(payments);
    return transaction;
  }

  Future<void> _persist(List<RecurringPaymentModel> payments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefRecurringPayments,
      payments
          .map((payment) => base64Encode(utf8.encode(payment.toJson())))
          .toList(growable: false),
    );
  }

  void dispose() {
    paymentsNotifier.dispose();
  }
}
