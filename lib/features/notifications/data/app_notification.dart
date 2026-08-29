import 'push_notification_type.dart';

class AppNotification {
  final int id;
  final PushNotificationType type;
  final String title;
  final String body;
  final int? projectId;
  final int? postId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.projectId,
    this.postId,
    required this.read,
    required this.createdAt,
  });

  String? get route => routeForPushNotification(type, {
    if (projectId != null) 'projectId': projectId.toString(),
    if (postId != null) 'postId': postId.toString(),
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: pushNotificationTypeFromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      projectId: json['projectId'] as int?,
      postId: json['postId'] as int?,
      read: json['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      projectId: projectId,
      postId: postId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
