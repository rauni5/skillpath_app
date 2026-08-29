import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/app_notification.dart';
import '../data/notifications_repository.dart';

enum NotificationsLoadState { initial, loading, loaded, error }

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({NotificationsRepository? repository})
    : _repo = repository ?? NotificationsRepository();

  final NotificationsRepository _repo;
  static const _pageSize = 25;

  NotificationsLoadState state = NotificationsLoadState.initial;
  List<AppNotification> notifications = [];
  int unreadCount = 0;
  String? errorMessage;

  int _page = 0;
  bool hasMore = true;
  bool isLoadingMore = false;

  /// Fetches the first page fresh — used on initial load and pull-to-
  /// refresh. Never fetches more than one page's worth at a time.
  Future<void> load(int userId) async {
    state = NotificationsLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getNotifications(userId, page: 0, size: _pageSize),
        _repo.getUnreadCount(userId),
      ]);
      notifications = results[0] as List<AppNotification>;
      unreadCount = results[1] as int;
      _page = 0;
      hasMore = notifications.length == _pageSize;
      state = NotificationsLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load notifications.';
      state = NotificationsLoadState.error;
    }
    notifyListeners();
  }

  /// Fetches the next page and appends it — the list only ever grows one
  /// page at a time, driven by the screen scrolling near the bottom.
  Future<void> loadMore(int userId) async {
    if (isLoadingMore || !hasMore || state != NotificationsLoadState.loaded) {
      return;
    }
    isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final page = await _repo.getNotifications(
        userId,
        page: nextPage,
        size: _pageSize,
      );
      notifications = [...notifications, ...page];
      _page = nextPage;
      hasMore = page.length == _pageSize;
    } catch (_) {
      // A failed "load more" isn't worth a full error state — the person
      // can just scroll again (or pull to refresh) to retry.
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Just refreshes the unread count — cheap enough to call often (e.g. on
  /// every dashboard load) without fetching the whole list.
  Future<void> refreshUnreadCount(int userId) async {
    try {
      unreadCount = await _repo.getUnreadCount(userId);
      notifyListeners();
    } catch (_) {
      // Best-effort — a stale badge count isn't worth surfacing an error.
    }
  }

  Future<void> markRead(int userId, AppNotification notification) async {
    if (notification.read) return;
    // Optimistic: flip it locally first so the tap feels instant, then
    // reconcile with the server in the background.
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notification.copyWith(read: true);
      unreadCount = (unreadCount - 1).clamp(0, unreadCount);
      notifyListeners();
    }
    try {
      await _repo.markRead(userId, notification.id);
    } catch (_) {
      // Not critical enough to roll back or surface — worst case the
      // badge is off by one until the next load.
    }
  }

  Future<void> markAllRead(int userId) async {
    if (unreadCount == 0) return;
    final previous = notifications;
    final previousUnread = unreadCount;
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    unreadCount = 0;
    notifyListeners();
    try {
      await _repo.markAllRead(userId);
    } catch (_) {
      notifications = previous;
      unreadCount = previousUnread;
      notifyListeners();
    }
  }
}
