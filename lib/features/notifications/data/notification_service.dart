import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/navigation_keys.dart';
import '../../auth/data/auth_repository.dart';
import 'push_notification_type.dart';

/// Handles messages that arrive while the app is backgrounded or fully
/// closed. Must be a top-level (or static) function - the platform side
/// invokes it in its own isolate, so it can't be a NotificationService
/// instance method or close over any running-app state.
///
/// Our invite messages always carry a "notification" payload, which
/// Android/iOS already turn into a system-tray notification on their own
/// in this state, so there's nothing else to do here. It's still
/// registered so the OS knows to wake the app for delivery, and so it's in
/// place if a future data-only (silent) message type is added.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Owns push-notification setup end to end: permission, token
/// registration/refresh, showing the notification while the app is in the
/// foreground (the OS does it for us otherwise), and routing a tap to the
/// right screen.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthRepository _authRepo = AuthRepository();

  static const _androidChannel = AndroidNotificationChannel(
    'project_invites',
    'Project Invites',
    description: 'Invite requests, responses, and project membership updates.',
    importance: Importance.high,
  );

  int? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;

  /// Call once at app startup (after Firebase.initializeApp), before any
  /// user is signed in. Sets up local-notification display and message
  /// listeners. Doesn't request permission or register a token yet - that
  /// needs a signed-in user, and happens in [registerForUser].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _navigateForMessage,
    );

    // App was fully closed and got launched by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _navigateForMessage(initialMessage);
  }

  /// Call once a user is signed in and we know their backend id (e.g. right
  /// after AuthRepository.sync() succeeds). Requests notification
  /// permission, fetches this device's FCM token, and registers it with
  /// the backend so invite events reach this device. Every step here is
  /// best-effort: a user who declines permission, or whose token can't be
  /// reached right now, still gets full in-app functionality - they just
  /// won't get a push.
  Future<void> registerForUser(int userId) async {
    _currentUserId = userId;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return;
    }

    await _syncToken(userId);

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      if (_currentUserId != null) {
        _sendTokenToBackend(_currentUserId!, token);
      }
    });
  }

  Future<void> _syncToken(int userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _sendTokenToBackend(userId, token);
    } catch (e) {
      debugPrint('Could not fetch FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(int userId, String token) async {
    try {
      await _authRepo.registerDeviceToken(userId, token, _platformName());
    } catch (e) {
      debugPrint('Could not register device token with backend: $e');
    }
  }

  /// Call on sign-out so a shared/reinstalled device stops receiving the
  /// signed-out user's notifications.
  Future<void> handleSignOut() async {
    final userId = _currentUserId;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (userId == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _authRepo.unregisterDeviceToken(userId, token);
      }
    } catch (_) {
    } finally {
      _currentUserId = null;
    }
  }

  Future<void> setPushEnabled(bool enabled, int userId) async {
    if (enabled) {
      await registerForUser(userId);
      return;
    }
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _authRepo.unregisterDeviceToken(userId, token);
      }
    } catch (e) {
      debugPrint('Could not unregister device token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: foreground message, data=${message.data}');
    final notification = message.notification;
    if (notification == null) {
      debugPrint(
        'NotificationService: message had no "notification" block - '
        'nothing to show in the tray for it.',
      );
      return;
    }

    _localNotifications.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint(
      'NotificationService: local notification tapped, payload=${response.payload}',
    );
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigate(data);
    } catch (e) {
      debugPrint('Could not parse notification payload: $e');
    }
  }

  void _navigateForMessage(RemoteMessage message) {
    debugPrint(
      'NotificationService: message opened/initial, data=${message.data}',
    );
    _navigate(message.data);
  }

  void _navigate(Map<String, dynamic> data, {int attempt = 0}) {
    final type = pushNotificationTypeFromString(data['type'] as String?);
    final route = routeForPushNotification(type, data);
    if (route == null) {
      debugPrint(
        'NotificationService: no route for payload $data (type=$type) - '
        'nothing to navigate to.',
      );
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      debugPrint('NotificationService: navigating to $route');
      GoRouter.of(context).push(route);
      return;
    }

    // Most commonly hit on a cold start: the app was launched by tapping
    // the notification, so getInitialMessage() resolves before runApp()
    // has built the widget tree - rootNavigatorKey isn't attached to
    // anything yet. Rather than silently dropping the navigation, retry a
    // few times a beat apart, which is enough for the router to exist and
    // (usually) for auth state to have settled too.
    if (attempt >= 20) {
      debugPrint(
        'NotificationService: giving up navigating to $route - '
        'router never became ready.',
      );
      return;
    }
    debugPrint(
      'NotificationService: router not ready yet for $route, '
      'retrying (attempt $attempt)',
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _navigate(data, attempt: attempt + 1),
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }
  void disposeListeners() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    _tokenRefreshSub?.cancel();
  }
}
