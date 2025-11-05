import 'dart:convert';

class HelpArticleModel {
  const HelpArticleModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    required this.relatedIds,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final List<String> tags;
  final List<String> relatedIds;

  HelpArticleModel copyWith({
    String? title,
    String? body,
    String? category,
    List<String>? tags,
    List<String>? relatedIds,
  }) {
    return HelpArticleModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      relatedIds: relatedIds ?? this.relatedIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'tags': tags,
      'relatedIds': relatedIds,
    };
  }

  static HelpArticleModel fromJson(Map<String, dynamic> json) {
    return HelpArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      relatedIds: (json['relatedIds'] as List<dynamic>).cast<String>(),
    );
  }

  static List<HelpArticleModel> decodeList(String? source) {
    if (source == null || source.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HelpArticleModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<HelpArticleModel> articles) {
    return jsonEncode([for (final article in articles) article.toJson()]);
  }
}
