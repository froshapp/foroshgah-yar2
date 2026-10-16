import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// مقادیر از google-services.json پروژه foroshgah-yar
class FyFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJ-c1hiyqQFPyAi9gMiJR_QIPnzq70rUE',
    appId: '1:288700049655:android:fe7310cbe96e8e18f3cbf2',
    messagingSenderId: '288700049655',
    projectId: 'foroshgah-yar',
    storageBucket: 'foroshgah-yar.firebasestorage.app',
  );
}

@pragma('vm:entry-point')
Future<void> fyFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FyFirebaseOptions.android);
    }
  } catch (_) {}
}

class FcmService {
  static final FcmService _i = FcmService._();
  factory FcmService() => _i;
  FcmService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool ready = false;
  bool enabled = true;
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
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool('fy_fcm_enabled') ?? true;
      if (!enabled) {
        ready = false;
        lastError = 'پوش توسط کاربر غیرفعال شده';
        return;
      }

      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(options: FyFirebaseOptions.android);
        } catch (_) {
          // fallback بدون options (اگر google-services اعمال شده باشد)
          await Firebase.initializeApp();
        }
      }

      FirebaseMessaging.onBackgroundMessage(fyFirebaseBackgroundHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _local.initialize(
        const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (resp) {
          debugPrint('FY local notif tap: ${resp.payload}');
        },
      );

      final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_showLocal);
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        debugPrint('FY FCM opened: ${m.data}');
      });

      token = await messaging.getToken();
      if (token != null) {
        await prefs.setString('fy_fcm_token', token!);
      }
      messaging.onTokenRefresh.listen((t) async {
        token = t;
        await prefs.setString('fy_fcm_token', t);
      });

      ready = true;
      lastError = null;
    } catch (e) {
      ready = false;
      lastError = e.toString();
      debugPrint('FY FCM init failed: $e');
    }
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fy_fcm_enabled', v);
    enabled = v;
    if (v) {
      await init();
    } else {
      ready = false;
      lastError = 'پوش توسط کاربر غیرفعال شده';
    }
  }

  void _showLocal(RemoteMessage message) {
    if (!enabled) return;
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

  Future<bool> syncToken(AuthService auth) async {
    if (!enabled || !auth.isAuthenticated) return false;
    try {
      if (token == null || token!.isEmpty) {
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(options: FyFirebaseOptions.android);
          }
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
