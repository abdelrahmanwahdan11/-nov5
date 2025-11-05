import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';

class ToolsController {
  ToolsController._(
    this.feeAmountNotifier,
    this.feeRateNotifier,
    this.feeResultNotifier,
    this.interestPrincipalNotifier,
    this.interestRateNotifier,
    this.interestPeriodsNotifier,
    this.interestResultNotifier,
    this._prefs,
  );

  final ValueNotifier<double> feeAmountNotifier;
  final ValueNotifier<double> feeRateNotifier;
  final ValueNotifier<double> feeResultNotifier;

  final ValueNotifier<double> interestPrincipalNotifier;
  final ValueNotifier<double> interestRateNotifier;
  final ValueNotifier<int> interestPeriodsNotifier;
  final ValueNotifier<double> interestResultNotifier;

  final SharedPreferences _prefs;

  static Future<ToolsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final feeJson = prefs.getString(AppConstants.prefFeeCalculator);
    final interestJson = prefs.getString(AppConstants.prefInterestCalculator);

    final feeState = _parseFeeState(feeJson);
    final interestState = _parseInterestState(interestJson);

    final controller = ToolsController._(
      ValueNotifier<double>(feeState['amount'] as double),
      ValueNotifier<double>(feeState['rate'] as double),
      ValueNotifier<double>(_calcFee(
        feeState['amount'] as double,
        feeState['rate'] as double,
      )),
      ValueNotifier<double>(interestState['principal'] as double),
      ValueNotifier<double>(interestState['rate'] as double),
      ValueNotifier<int>(interestState['periods'] as int),
      ValueNotifier<double>(_calcCompound(
        interestState['principal'] as double,
        interestState['rate'] as double,
        interestState['periods'] as int,
      )),
      prefs,
    );

    controller._wireListeners();
    return controller;
  }

  void _wireListeners() {
    feeAmountNotifier.addListener(_persistFee);
    feeRateNotifier.addListener(_persistFee);
    interestPrincipalNotifier.addListener(_persistInterest);
    interestRateNotifier.addListener(_persistInterest);
    interestPeriodsNotifier.addListener(_persistInterest);
  }

  static Map<String, Object> _parseFeeState(String? source) {
    if (source == null) {
      return {'amount': 250.0, 'rate': 1.4};
    }
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return {
        'amount': (decoded['amount'] as num).toDouble(),
        'rate': (decoded['rate'] as num).toDouble(),
      };
    } catch (_) {
      return {'amount': 250.0, 'rate': 1.4};
    }
  }

  static Map<String, Object> _parseInterestState(String? source) {
    if (source == null) {
      return {'principal': 1200.0, 'rate': 3.2, 'periods': 12};
    }
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return {
        'principal': (decoded['principal'] as num).toDouble(),
        'rate': (decoded['rate'] as num).toDouble(),
        'periods': decoded['periods'] as int,
      };
    } catch (_) {
      return {'principal': 1200.0, 'rate': 3.2, 'periods': 12};
    }
  }

  void updateFeeAmount(double value) {
    feeAmountNotifier.value = value;
    feeResultNotifier.value = _calcFee(value, feeRateNotifier.value);
  }

  void updateFeeRate(double value) {
    feeRateNotifier.value = value;
    feeResultNotifier.value = _calcFee(feeAmountNotifier.value, value);
  }

  void updateInterestPrincipal(double value) {
    interestPrincipalNotifier.value = value;
    interestResultNotifier.value = _calcCompound(
      value,
      interestRateNotifier.value,
      interestPeriodsNotifier.value,
    );
  }

  void updateInterestRate(double value) {
    interestRateNotifier.value = value;
    interestResultNotifier.value = _calcCompound(
      interestPrincipalNotifier.value,
      value,
      interestPeriodsNotifier.value,
    );
  }

  void updateInterestPeriods(int value) {
    interestPeriodsNotifier.value = value;
    interestResultNotifier.value = _calcCompound(
      interestPrincipalNotifier.value,
      interestRateNotifier.value,
      value,
    );
  }

  void _persistFee() {
    feeResultNotifier.value = _calcFee(
      feeAmountNotifier.value,
      feeRateNotifier.value,
    );
    final payload = jsonEncode({
      'amount': feeAmountNotifier.value,
      'rate': feeRateNotifier.value,
    });
    _prefs.setString(AppConstants.prefFeeCalculator, payload);
  }

  void _persistInterest() {
    interestResultNotifier.value = _calcCompound(
      interestPrincipalNotifier.value,
      interestRateNotifier.value,
      interestPeriodsNotifier.value,
    );
    final payload = jsonEncode({
      'principal': interestPrincipalNotifier.value,
      'rate': interestRateNotifier.value,
      'periods': interestPeriodsNotifier.value,
    });
    _prefs.setString(AppConstants.prefInterestCalculator, payload);
  }

  static double _calcFee(double amount, double rate) {
    return (amount * (rate / 100)).clamp(0, double.infinity);
  }

  static double _calcCompound(double principal, double rate, int periods) {
    final monthly = rate / 100 / 12;
    final totalMonths = periods;
    final futureValue =
        principal * pow((1 + monthly), totalMonths).toDouble();
    return (futureValue - principal).clamp(0, double.infinity);
  }

  void dispose() {
    feeAmountNotifier.removeListener(_persistFee);
    feeRateNotifier.removeListener(_persistFee);
    interestPrincipalNotifier.removeListener(_persistInterest);
    interestRateNotifier.removeListener(_persistInterest);
    interestPeriodsNotifier.removeListener(_persistInterest);
    feeAmountNotifier.dispose();
    feeRateNotifier.dispose();
    feeResultNotifier.dispose();
    interestPrincipalNotifier.dispose();
    interestRateNotifier.dispose();
    interestPeriodsNotifier.dispose();
    interestResultNotifier.dispose();
  }
}
