import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized before this is called.
  debugPrint('[FCM] Background message: ${message.messageId}');

  // Do not show notifications when no user is logged in on this device.
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token');
  if (authToken == null) {
    debugPrint('[FCM] Background: no logged-in user — skipping notification.');
    return;
  }

  // If the message has no notification payload (data-only), the OS will NOT
  // display anything automatically. We must show a local notification here.
  if (message.notification == null) {
    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;
    if (title != null || body != null) {
      const channel = AndroidNotificationChannel(
        'ofa_high_importance',
        'OFA Notifications',
        description: 'Notifikasi penting dari OFA',
        importance: Importance.high,
      );
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      if (!kIsWeb && Platform.isAndroid) {
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }
      await plugin.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Cached ApiService used by token-refresh listener and syncToken.
  static ApiService? _apiService;

  /// Returns the current device FCM token, if available.
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Failed to get FCM token: $e');
      return null;
    }
  }

  /// Request notification permission at runtime (useful for Android 13+).
  /// Returns true if permission is granted, false otherwise.
  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Runtime permission request: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Stream emitted when a foreground message arrives (for in-app refresh).
  static final _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onForegroundMessage =>
      _messageStreamController.stream;

  /// Stream emitted when user taps a notification (background / terminated).
  static final _tapStreamController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onNotificationTap =>
      _tapStreamController.stream;

  static const _androidChannel = AndroidNotificationChannel(
    'ofa_high_importance',
    'OFA Notifications',
    description: 'Notifikasi penting dari OFA',
    importance: Importance.high,
  );

  /// Call once at app startup (before login) to set up listeners and channels.
  static Future<void> initialize(ApiService apiService) async {
    _apiService = apiService;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ & iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Do NOT return early on denied — still set up listeners so token refresh works
    // if user grants permission later via settings.

    // iOS: show notifications even when the app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications channel (Android)
    await _initLocalNotifications();

    // Listen for token refresh — will use the stored _apiService.
    _messaging.onTokenRefresh.listen((token) {
      if (_apiService != null) {
        _sendTokenToServer(_apiService!, token);
      }
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
      _messageStreamController.add(message);
    });

    // Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
      _tapStreamController.add(message);
    });

    // Check if app was opened from a terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Opened from terminated: ${initial.data}');
      // Slight delay to allow the widget tree to mount before navigating
      Future.delayed(const Duration(milliseconds: 500), () {
        _tapStreamController.add(initial);
      });
    }
  }

  /// Call this on user logout to invalidate the device's FCM token.
  /// Deletes the token locally so Firebase generates a fresh one on next login.
  /// The server clears its stored token via the logout API endpoint.
  static Future<void> clearToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('[FCM] Token deleted on logout.');
    } catch (e) {
      debugPrint('[FCM] Failed to delete token: $e');
    }
  }

  /// Call this after the user successfully logs in to sync the FCM token.
  /// The token cannot be sent during app startup because the user is not
  /// authenticated yet and the server would reject the request with 401.
  static Future<void> syncToken({int maxRetries = 3}) async {
    final api = _apiService;
    if (api == null) {
      throw Exception('FCM Service not initialized: _apiService is null');
    }

    String? token;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      token = await _messaging.getToken();
      if (token != null) break;
      debugPrint('[FCM] syncToken: getToken() returned null, retry $attempt/$maxRetries');
      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    if (token == null) {
      throw Exception('Failed to get FCM token after $maxRetries attempts');
    }

    debugPrint('[FCM] Syncing token after login: $token');
    await _sendTokenToServer(api, token);
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(initSettings);

    // Create high-importance channel on Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }
  }

  static Future<void> _sendTokenToServer(
    ApiService apiService,
    String token,
  ) async {
    try {
      await apiService.post(ApiConstants.fcmTokenUpdate, {'fcm_token': token});
      debugPrint('[FCM] Token synced to server.');
    } catch (e) {
      debugPrint('[FCM] Failed to sync token: $e');
      rethrow;
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    // Fallback ke data payload jika backend mengirim data-only message
    // (tanpa field `notification`). Ini terjadi pada tipe invoice, ticketing, dll.
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    if (title == null && body == null) return;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
