import 'package:flutter/material.dart' show IconData, Icons;

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
