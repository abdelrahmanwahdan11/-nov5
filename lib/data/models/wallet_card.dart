import 'dart:convert';

import 'package:flutter/material.dart';

class WalletCardModel {
  WalletCardModel({
    required this.id,
    required this.title,
    required this.holderName,
    required this.cardNumber,
    required this.balance,
    required this.currency,
    required this.gradient,
    required this.expiry,
    required this.network,
  });

  final String id;
  final String title;
  final String holderName;
  final String cardNumber;
  final double balance;
  final String currency;
  final List<int> gradient;
  final String expiry;
  final String network;

  WalletCardModel copyWith({
    String? title,
    String? holderName,
    String? cardNumber,
    double? balance,
    String? currency,
    List<int>? gradient,
    String? expiry,
    String? network,
  }) {
    return WalletCardModel(
      id: id,
      title: title ?? this.title,
      holderName: holderName ?? this.holderName,
      cardNumber: cardNumber ?? this.cardNumber,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      gradient: gradient ?? this.gradient,
      expiry: expiry ?? this.expiry,
      network: network ?? this.network,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'holderName': holderName,
      'cardNumber': cardNumber,
      'balance': balance,
      'currency': currency,
      'gradient': gradient,
      'expiry': expiry,
      'network': network,
    };
  }

  static WalletCardModel fromJson(Map<String, dynamic> json) {
    return WalletCardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      holderName: json['holderName'] as String,
      cardNumber: json['cardNumber'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      gradient: (json['gradient'] as List<dynamic>).cast<int>(),
      expiry: json['expiry'] as String,
      network: json['network'] as String,
    );
  }

  static List<WalletCardModel> decodeList(String source) {
    final List<dynamic> decoded = json.decode(source) as List<dynamic>;
    return decoded
        .map((item) => WalletCardModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<WalletCardModel> cards) {
    final payload = cards.map((card) => card.toJson()).toList();
    return json.encode(payload);
  }

  String get maskedNumber {
    final trimmed = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.length < 4) {
      return cardNumber;
    }
    final suffix = trimmed.substring(trimmed.length - 4);
    return '**** **** **** $suffix';
  }

  Color startColor() => Color(gradient.first);
  Color endColor() => Color(gradient.last);
}
