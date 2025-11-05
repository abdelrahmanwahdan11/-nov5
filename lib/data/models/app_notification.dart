import 'dart:convert';

import 'package:flutter/material.dart';

enum AppNotificationType { success, alert, tip, update }

class AppNotificationModel {
  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.icon,
    this.actionRoute,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime timestamp;
  final IconData icon;
  final String? actionRoute;
  final bool read;

  AppNotificationModel copyWith({
    bool? read,
  }) {
    return AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      icon: icon,
      actionRoute: actionRoute,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'icon': icon.codePoint,
      'fontFamily': icon.fontFamily,
      'actionRoute': actionRoute,
      'read': read,
    };
  }

  static AppNotificationModel fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: AppNotificationType.values[json['type'] as int],
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      icon: IconData(
        json['icon'] as int,
        fontFamily: json['fontFamily'] as String?,
      ),
      actionRoute: json['actionRoute'] as String?,
      read: json['read'] as bool? ?? false,
    );
  }

  static List<AppNotificationModel> decodeList(String? source) {
    if (source == null || source.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<AppNotificationModel> notifications) {
    final payload = notifications.map((notification) => notification.toJson());
    return jsonEncode(payload.toList());
  }
}
