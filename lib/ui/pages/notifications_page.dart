import 'package:flutter/material.dart';

import '../../controllers/notifications_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/app_notification.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.notificationsController,
  });

  final NotificationsController notificationsController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final filters = <AppNotificationType?>[
      null,
      AppNotificationType.success,
      AppNotificationType.alert,
      AppNotificationType.tip,
      AppNotificationType.update,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('notificationsTitle')),
        actions: [
          ValueListenableBuilder<List<AppNotificationModel>>(
            valueListenable: notificationsController.notifications,
            builder: (context, notifications, _) {
              final hasUnread =
                  notifications.any((notification) => !notification.read);
              return IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: t.translate('notificationsMarkAll'),
                onPressed: hasUnread
                    ? () => notificationsController.markAllRead()
                    : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ValueListenableBuilder<AppNotificationType?>(
            valueListenable: notificationsController.filter,
            builder: (context, current, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final type in filters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            type == null
                                ? t.translate('notificationsFilterAll')
                                : t.translate('notificationsFilter${type.name}'),
                          ),
                          selected: current == type,
                          onSelected: (_) =>
                              notificationsController.setFilter(type),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<List<AppNotificationModel>>(
              valueListenable: notificationsController.notifications,
              builder: (context, allNotifications, _) {
                final filtered =
                    notificationsController.filteredNotifications;
                if (filtered.isEmpty) {
                  return const _EmptyNotificationsState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final notification = filtered[index];
                    return _NotificationTile(
                      notification: notification,
                      onToggle: (value) => notificationsController
                          .markRead(notification.id, value),
                      onOpen: () => _handleOpen(context, notification),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOpen(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    if (!notification.read) {
      notificationsController.markRead(notification.id, true);
    }
    if (notification.actionRoute == null) {
      return;
    }
    Navigator.of(context).pushNamed(notification.actionRoute!);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onToggle,
    required this.onOpen,
  });

  final AppNotificationModel notification;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpen;

  Color _typeColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (notification.type) {
      case AppNotificationType.success:
        return scheme.primary;
      case AppNotificationType.alert:
        return scheme.error;
      case AppNotificationType.tip:
        return scheme.secondary;
      case AppNotificationType.update:
        return scheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = notification.read
        ? scheme.surfaceVariant.withOpacity(0.4)
        : scheme.primary.withOpacity(0.08);

    return Card(
      elevation: 0,
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _typeColor(context).withOpacity(0.15),
                ),
                child: Icon(
                  notification.icon,
                  color: _typeColor(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _relativeTime(notification.timestamp, t),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: notification.read,
                onChanged: (value) => onToggle(value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime timestamp, AppLocalizations t) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return t.translate('timeJustNow');
    }
    if (difference.inMinutes < 60) {
      return t.translate('timeMinutesAgo',
          params: {'count': difference.inMinutes.toString()});
    }
    if (difference.inHours < 24) {
      return t.translate('timeHoursAgo',
          params: {'count': difference.inHours.toString()});
    }
    if (difference.inDays == 1) {
      return t.translate('timeYesterday');
    }
    return t.translate('timeDaysAgo',
        params: {'count': difference.inDays.toString()});
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              t.translate('notificationsEmptyTitle'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('notificationsEmptySubtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
