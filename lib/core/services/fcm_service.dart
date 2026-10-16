import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// هندلر پس‌زمینه (باید top-level باشد)
@pragma('vm:entry-point')
Future<void> fyFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FY FCM background: ${message.messageId} ${message.notification?.title}');
}

class FcmService {
  static final FcmService _i = FcmService._();
  factory FcmService() => _i;
  FcmService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool ready = false;
  String? token;
  String? lastError;

  static const _androidChannel = AndroidNotificationChannel(
    'fy_orders',
    'سفارشات فروشگاه‌یار',
    description: 'اعلان سفارش جدید و موجودی',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(fyFirebaseBackgroundHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          debugPrint('FY local notif tap: ${resp.payload}');
        },
      );

      final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FY FCM permission: ${settings.authorizationStatus}');

      // پیش‌زمینه
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showLocal);
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        debugPrint('FY FCM opened: ${m.data}');
      });

      token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fy_fcm_token', token!);
      }

      messaging.onTokenRefresh.listen((t) async {
        token = t;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fy_fcm_token', t);
        // اگر لاگین بود بعداً sync می‌شود
      });

      ready = true;
      lastError = null;
    } catch (e) {
      ready = false;
      lastError = e.toString();
      debugPrint('FY FCM init failed: $e');
    }
  }

  void _showLocal(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? 'فروشگاه‌یار';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    _local.show(
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
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// ارسال توکن به افزونه وردپرس
  Future<bool> syncToken(AuthService auth) async {
    if (!auth.isAuthenticated) return false;
    try {
      if (token == null || token!.isEmpty) {
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
      }
      if (token == null || token!.isEmpty) return false;
      await auth.api.dio.post('fcm-token', data: {
        'token': token,
        'platform': 'android',
      });
      return true;
    } catch (e) {
      debugPrint('FY FCM sync failed: $e');
      return false;
    }
  }
}
