import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/mock/mock_data.dart';
import '../data/models/app_notification.dart';

class NotificationsController with ChangeNotifier {
  NotificationsController._(this._prefs, List<AppNotificationModel> items)
      : notifications = ValueNotifier<List<AppNotificationModel>>(items),
        filter = ValueNotifier<AppNotificationType?>(null);

  final SharedPreferences _prefs;
  final ValueNotifier<List<AppNotificationModel>> notifications;
  final ValueNotifier<AppNotificationType?> filter;

  static Future<NotificationsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = AppNotificationModel.decodeList(
      prefs.getString(AppConstants.prefNotifications),
    );
    final initial = stored.isEmpty
        ? MockDataGenerator.generateNotifications()
        : stored;

    final controller = NotificationsController._(prefs, initial);
    controller._hydrateDefaultsIfNeeded(initial);
    return controller;
  }

  void _hydrateDefaultsIfNeeded(List<AppNotificationModel> current) {
    if (current.isNotEmpty) {
      return;
    }
    final seeded = MockDataGenerator.generateNotifications();
    notifications.value = seeded;
    _persist(seeded);
  }

  void setFilter(AppNotificationType? type) {
    if (filter.value == type) {
      return;
    }
    filter.value = type;
  }

  void markRead(String id, bool value) {
    final updated = notifications.value
        .map((item) => item.id == id ? item.copyWith(read: value) : item)
        .toList();
    notifications.value = updated;
    _persist(updated);
    notifyListeners();
  }

  void markAllRead() {
    final updated = [
      for (final item in notifications.value) item.copyWith(read: true),
    ];
    notifications.value = updated;
    _persist(updated);
    notifyListeners();
  }

  int get unreadCount =>
      notifications.value.where((item) => !item.read).length;

  List<AppNotificationModel> get filteredNotifications {
    final selected = filter.value;
    if (selected == null) {
      return notifications.value;
    }
    return notifications.value
        .where((item) => item.type == selected)
        .toList();
  }

  void addNotification(AppNotificationModel notification) {
    final updated = [notification, ...notifications.value];
    notifications.value = updated;
    _persist(updated);
    notifyListeners();
  }

  void clear() {
    notifications.value = [];
    _persist([]);
    notifyListeners();
  }

  void _persist(List<AppNotificationModel> payload) {
    _prefs.setString(
      AppConstants.prefNotifications,
      AppNotificationModel.encodeList(payload),
    );
  }

  @override
  void dispose() {
    notifications.dispose();
    filter.dispose();
    super.dispose();
  }
}
