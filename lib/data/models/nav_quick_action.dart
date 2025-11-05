import 'dart:convert';

class NavQuickAction {
  const NavQuickAction({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.target,
  });

  final String id;
  final String labelKey;
  final int icon;
  final String target;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'labelKey': labelKey,
      'icon': icon,
      'target': target,
    };
  }

  static NavQuickAction fromJson(Map<String, dynamic> json) {
    return NavQuickAction(
      id: json['id'] as String,
      labelKey: json['labelKey'] as String,
      icon: json['icon'] as int,
      target: json['target'] as String,
    );
  }

  static String encodeMap(Map<String, List<String>> mapping) {
    return jsonEncode(mapping);
  }

  static Map<String, List<String>> decodeMap(String? source) {
    if (source == null || source.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final items = (value as List<dynamic>).cast<String>();
        return MapEntry(key, items);
      });
    } catch (_) {
      return {};
    }
  }
}
