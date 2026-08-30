import '../../../core/network/api_client.dart';
import '../../../core/models/app_notification.dart';

class NotificationsRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/notifications?page=&size=
  /// Paginated, newest first — never fetches the whole history at once.
  Future<List<AppNotification>> getNotifications(
    int userId, {
    int page = 0,
    int size = 25,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/$userId/notifications',
        queryParameters: {'page': page, 'size': size},
      ),
      (data) => (data as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/users/{userId}/notifications/unread-count
  Future<int> getUnreadCount(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/notifications/unread-count'),
      (data) => (data as num).toInt(),
    );
  }

  /// POST /api/v1/users/{userId}/notifications/{notificationId}/read
  Future<void> markRead(int userId, int notificationId) {
    return _api.unwrap(
      (dio) =>
          dio.post('/api/v1/users/$userId/notifications/$notificationId/read'),
      (_) {},
    );
  }

  /// POST /api/v1/users/{userId}/notifications/read-all
  Future<void> markAllRead(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/notifications/read-all'),
      (_) {},
    );
  }
}
