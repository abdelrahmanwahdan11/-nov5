import 'package:flutter/material.dart';

class WalletCardModel {
  WalletCardModel({
    required this.id,
    required this.label,
    required this.number,
    required this.balance,
    required this.currency,
    required this.colors,
  });

  final String id;
  final String label;
  final String number;
  final double balance;
  final String currency;
  final List<Color> colors;

  WalletCardModel copyWith({
    String? label,
    String? number,
    double? balance,
    String? currency,
    List<Color>? colors,
  }) {
    return WalletCardModel(
      id: id,
      label: label ?? this.label,
      number: number ?? this.number,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      colors: colors ?? this.colors,
    );
  }
}
