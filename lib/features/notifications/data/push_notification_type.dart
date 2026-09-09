import 'package:flutter/material.dart' show IconData, Icons;

import '../../projects/data/projects_repository.dart';

/// Values that arrive in the FCM data payload's "type" field. Mirrors
/// com.skillpath.service.notification.NotificationType on the backend —
/// keep the two in sync.
enum PushNotificationType {
  /// Someone (the owner) invited you to a project.
  inviteReceived,

  /// You accepted an invite you received.
  inviteAccepted,

  /// You declined an invite you received.
  inviteRejected,

  /// Someone asked to join your project.
  joinRequestReceived,

  /// The owner accepted your join request.
  joinRequestAccepted,

  /// The owner declined your join request.
  joinRequestRejected,

  /// Someone commented on your discussion post.
  discussionCommentReceived,

  /// Anything we don't recognise — e.g. an older client receiving a type
  /// added by a newer backend. Handled as "no-op navigation".
  unknown,
}

PushNotificationType pushNotificationTypeFromString(String? value) {
  switch (value) {
    case 'PROJECT_INVITE_RECEIVED':
      return PushNotificationType.inviteReceived;
    case 'PROJECT_INVITE_ACCEPTED':
      return PushNotificationType.inviteAccepted;
    case 'PROJECT_INVITE_REJECTED':
      return PushNotificationType.inviteRejected;
    case 'PROJECT_JOIN_REQUEST_RECEIVED':
      return PushNotificationType.joinRequestReceived;
    case 'PROJECT_JOIN_REQUEST_ACCEPTED':
      return PushNotificationType.joinRequestAccepted;
    case 'PROJECT_JOIN_REQUEST_REJECTED':
      return PushNotificationType.joinRequestRejected;
    case 'PROJECT_DISCUSSION_COMMENT_RECEIVED':
      return PushNotificationType.discussionCommentReceived;
    default:
      return PushNotificationType.unknown;
  }
}

/// Where tapping a notification of this type should take the user.
/// Returns null when there's nowhere sensible to go (unknown type, or no
/// projectId in the payload).
String? routeForPushNotification(
  PushNotificationType type,
  Map<String, dynamic> data,
) {
  final projectId = data['projectId'];

  switch (type) {
    // Take both invite and join request notifications to My Invites screen
    case PushNotificationType.inviteReceived:
    case PushNotificationType.joinRequestReceived:
      return '/projects/invites';

    // Your own invite/request was resolved — take you to the project page.
    case PushNotificationType.inviteAccepted:
    case PushNotificationType.inviteRejected:
    case PushNotificationType.joinRequestAccepted:
    case PushNotificationType.joinRequestRejected:
      return projectId != null ? '/projects/$projectId' : null;

    // Straight to the specific post if postId is available
    case PushNotificationType.discussionCommentReceived:
      if (projectId == null) return null;
      final postId = data['postId'];
      return postId == null
          ? '/projects/$projectId/discussion'
          : '/projects/$projectId/discussion/post/$postId';

    case PushNotificationType.unknown:
      return null;
  }
}

/// Whether [routeForPushNotification] sends this type to the bare
/// "/projects/:id" route — the one route that needs to branch between the
/// owner's manage screen and the member-facing detail screen.
bool _landsOnBareProjectRoute(PushNotificationType type) {
  switch (type) {
    case PushNotificationType.inviteAccepted:
    case PushNotificationType.inviteRejected:
    case PushNotificationType.joinRequestAccepted:
    case PushNotificationType.joinRequestRejected:
      return true;
    default:
      return false;
  }
}

/// Same destination as [routeForPushNotification], except the bare project
/// route is upgraded to the owner's "manage" screen when [currentUserId]
/// owns that project — the same ownership check project cards use
/// throughout the app (e.g. the dashboard's project card tap handler),
/// applied here so a notification tap lands on the same screen a manual
/// tap on that project would.
///
/// Falls back to the plain [routeForPushNotification] result if there's no
/// project to check, no signed-in user, or the ownership lookup fails.
Future<String?> resolveProjectAwareNotificationRoute(
  PushNotificationType type,
  Map<String, dynamic> data,
  int? currentUserId,
) async {
  final route = routeForPushNotification(type, data);
  if (route == null || !_landsOnBareProjectRoute(type)) return route;

  final rawProjectId = data['projectId'];
  if (rawProjectId == null || currentUserId == null) return route;
  final projectId = rawProjectId is int
      ? rawProjectId
      : int.tryParse(rawProjectId.toString());
  if (projectId == null) return route;

  try {
    final project = await ProjectsRepository().getProject(projectId);
    return currentUserId == project.ownerId
        ? '/projects/mine/$projectId'
        : '/projects/$projectId';
  } catch (_) {
    return route;
  }
}

/// Icon for this notification type — used by the notification list so each
/// entry reads at a glance without needing to parse the title text.
IconData iconForPushNotification(PushNotificationType type) {
  switch (type) {
    case PushNotificationType.inviteReceived:
      return Icons.mail_outline;
    case PushNotificationType.joinRequestReceived:
      return Icons.person_add_alt_outlined;
    case PushNotificationType.inviteAccepted:
    case PushNotificationType.joinRequestAccepted:
      return Icons.check_circle_outline;
    case PushNotificationType.inviteRejected:
    case PushNotificationType.joinRequestRejected:
      return Icons.cancel_outlined;
    case PushNotificationType.discussionCommentReceived:
      return Icons.chat_bubble_outline;
    case PushNotificationType.unknown:
      return Icons.notifications_none;
  }
}

bool isPositivePushNotification(PushNotificationType type) {
  switch (type) {
    case PushNotificationType.inviteRejected:
    case PushNotificationType.joinRequestRejected:
      return false;
    default:
      return true;
  }
}
