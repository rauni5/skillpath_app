import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/app_notification.dart';
import '../data/push_notification_type.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollCtrl = ScrollController();

  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger the next page a bit before actually hitting the bottom, so
    // it's ready by the time the person gets there.
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 300) {
      final userId = _userId;
      if (userId != null) {
        context.read<NotificationsProvider>().loadMore(userId);
      }
    }
  }

  void _load() {
    final userId = _userId;
    if (userId != null) context.read<NotificationsProvider>().load(userId);
  }

  Future<void> _markAllRead() async {
    final userId = _userId;
    if (userId != null) {
      HapticFeedback.selectionClick();
      await context.read<NotificationsProvider>().markAllRead(userId);
    }
  }

  Future<void> _onTap(AppNotification notification) async {
    final userId = _userId;
    if (userId != null) {
      context.read<NotificationsProvider>().markRead(userId, notification);
    }
    final route = notification.route;
    if (route == null) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final notifications = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildBody(context, p, notifications),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    NotificationsProvider notifications,
  ) {
    switch (notifications.state) {
      case NotificationsLoadState.initial:
      case NotificationsLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case NotificationsLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: notifications.errorMessage ?? 'Something went wrong.',
          onRetry: _load,
        );
      case NotificationsLoadState.loaded:
        if (notifications.notifications.isEmpty) {
          return ListView(
            key: const ValueKey('empty'),
            children: [
              const SizedBox(height: 90),
              Icon(Icons.notifications_none, size: 40, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                "You're all caught up.",
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ],
          );
        }
        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount:
                notifications.notifications.length +
                (notifications.hasMore ? 1 : 0),
            separatorBuilder: (context, i) =>
                Divider(height: 1, color: p.border),
            itemBuilder: (context, i) {
              if (i >= notifications.notifications.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.indigo,
                      ),
                    ),
                  ),
                );
              }
              final n = notifications.notifications[i];
              return _NotificationTile(notification: n, onTap: () => _onTap(n));
            },
          ),
        );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final positive = isPositivePushNotification(notification.type);
    final accent = positive ? p.indigo : p.textMuted;
    final accentBg = positive ? p.indigoLight : p.surface1;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.read
            ? Colors.transparent
            : p.indigoLight.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconForPushNotification(notification.type),
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: notification.read
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: p.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.indigo,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
