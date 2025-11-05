import 'dart:convert';

class RecipientModel {
  const RecipientModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.handle,
    required this.quickAmount,
    required this.currency,
    required this.isFavorite,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String handle;
  final double quickAmount;
  final String currency;
  final bool isFavorite;

  RecipientModel copyWith({
    String? name,
    String? avatarUrl,
    String? handle,
    double? quickAmount,
    String? currency,
    bool? isFavorite,
  }) {
    return RecipientModel(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      handle: handle ?? this.handle,
      quickAmount: quickAmount ?? this.quickAmount,
      currency: currency ?? this.currency,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'handle': handle,
      'quickAmount': quickAmount,
      'currency': currency,
      'isFavorite': isFavorite,
    };
  }

  static RecipientModel fromMap(Map<String, dynamic> map) {
    return RecipientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String,
      handle: map['handle'] as String,
      quickAmount: (map['quickAmount'] as num).toDouble(),
      currency: map['currency'] as String,
      isFavorite: map['isFavorite'] as bool,
    );
  }

  String toJson() => jsonEncode(toMap());

  static RecipientModel fromJson(String source) =>
      fromMap(jsonDecode(source) as Map<String, dynamic>);
}
