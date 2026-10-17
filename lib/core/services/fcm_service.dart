import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

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

/// اعلان سفارش بدون وابستگی اجباری به گوگل
/// مسیر اصلی: ثبت دستگاه + صف سرور (device-inbox) — روی هواوی هم کار می‌کند
/// مسیر فرعی: FCM اگر گوگل در دسترس باشد
class FcmService {
  static final FcmService _i = FcmService._();
  factory FcmService() => _i;
  FcmService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool ready = false;
  bool enabled = true;
  bool gmsAvailable = false;
  String? token;
  String? deviceId;
  String? lastError; // عمداً برای UI خالی می‌ماند مگر خطای واقعی شبکه
  String statusText = 'در حال راه‌اندازی...';
  Timer? _pollTimer;
  AuthService? _auth;
  int? _lastOrderId;

  static const _androidChannel = AndroidNotificationChannel(
    'fy_orders',
    'سفارشات فروشگاه‌یار',
    description: 'اعلان سفارش جدید و موجودی',
    importance: Importance.high,
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('fy_fcm_enabled') ?? true;
    _lastOrderId = prefs.getInt('fy_last_order_id');
    deviceId = prefs.getString('fy_device_id');
    if (deviceId == null || deviceId!.isEmpty) {
      deviceId = _generateDeviceId();
      await prefs.setString('fy_device_id', deviceId!);
    }

    await _initLocal();
    lastError = null;

    if (!enabled) {
      ready = false;
      statusText = 'خاموش';
      return;
    }

    // FCM اختیاری — شکست بی‌صدا
    gmsAvailable = false;
    token = null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FyFirebaseOptions.android);
      }
      FirebaseMessaging.onBackgroundMessage(fyFirebaseBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showRemote);
      token = await messaging.getToken().timeout(const Duration(seconds: 6));
      if (token != null && token!.isNotEmpty) {
        gmsAvailable = true;
        await prefs.setString('fy_fcm_token', token!);
      }
    } catch (_) {
      gmsAvailable = false;
      token = null;
    }

    ready = true;
    statusText = gmsAvailable
        ? 'فعال (پوش گوگل + صف سرور)'
        : 'فعال (صف سرور — مناسب هواوی)';
  }

  String _generateDeviceId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _initLocal() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: androidInit));
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fy_fcm_enabled', v);
    enabled = v;
    if (v) {
      await init();
      if (_auth != null) await syncToken(_auth!);
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
      ready = false;
      statusText = 'خاموش';
      lastError = null;
    }
  }

  void startPolling(AuthService auth) {
    _auth = auth;
    _pollTimer?.cancel();
    if (!enabled) return;
    Future.delayed(const Duration(seconds: 3), () => _tick());
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _tick() async {
    if (!enabled || _auth == null || !_auth!.isAuthenticated) return;
    await _pollDeviceInbox();
    await _pollNewOrdersFallback();
  }

  /// مسیر اصلی بدون گوگل
  Future<void> _pollDeviceInbox() async {
    if (deviceId == null || deviceId!.isEmpty) return;
    try {
      final res = await _auth!.api.dio.get(
        'device-inbox',
        queryParameters: {'device_id': deviceId},
      );
      List items = [];
      if (res.data is Map && res.data['notifications'] is List) {
        items = res.data['notifications'] as List;
      }
      for (final raw in items) {
        if (raw is! Map) continue;
        final title = (raw['title'] ?? 'فروشگاه‌یار').toString();
        final body = (raw['body'] ?? '').toString();
        await showLocal(title, body);
      }
    } catch (_) {}
  }

  /// پشتیبان: اگر صف خالی بود، آخرین سفارش را چک کن
  Future<void> _pollNewOrdersFallback() async {
    try {
      final res = await _auth!.api.dio.get('orders', queryParameters: {
        'page': 1,
        'per_page': 3,
        'status': 'processing,pending,on-hold',
      });
      List list = [];
      if (res.data is Map && res.data['orders'] is List) {
        list = res.data['orders'] as List;
      } else if (res.data is List) {
        list = res.data as List;
      }
      if (list.isEmpty) return;
      final newest = list.first;
      final id = int.tryParse('${newest is Map ? newest['id'] : newest}') ?? 0;
      if (id <= 0) return;
      if (_lastOrderId == null) {
        _lastOrderId = id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('fy_last_order_id', id);
        return;
      }
      if (id > _lastOrderId!) {
        _lastOrderId = id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('fy_last_order_id', id);
        final name = newest is Map
            ? (newest['customer_name'] ?? newest['billing']?['first_name'] ?? 'مشتری').toString()
            : '';
        final total = newest is Map ? (newest['total'] ?? '').toString() : '';
        await showLocal(
          'سفارش جدید #$id',
          [if (name.isNotEmpty) name, if (total.isNotEmpty) '$total تومان'].join(' — '),
        );
      }
    } catch (_) {}
  }

  void _showRemote(RemoteMessage message) {
    if (!enabled) return;
    final n = message.notification;
    showLocal(
      n?.title ?? message.data['title']?.toString() ?? 'فروشگاه‌یار',
      n?.body ?? message.data['body']?.toString() ?? '',
    );
  }

  Future<void> showLocal(String title, String body) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
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
    );
  }

  Future<bool> syncToken(AuthService auth) async {
    _auth = auth;
    startPolling(auth);
    if (!enabled) return true;

    // همیشه دستگاه را در سرور ثبت کن (مسیر هواوی)
    try {
      await auth.api.dio.post('device-register', data: {
        'device_id': deviceId,
        'name': 'Android',
        'platform': 'android',
      });
    } catch (_) {}

    if (gmsAvailable && token != null && token!.isNotEmpty) {
      try {
        await auth.api.dio.post('fcm-token', data: {
          'token': token,
          'platform': 'android',
          'device': deviceId,
        });
        statusText = 'فعال (پوش گوگل + صف سرور)';
      } catch (_) {
        statusText = 'فعال (صف سرور — مناسب هواوی)';
      }
    } else {
      statusText = 'فعال (صف سرور — مناسب هواوی)';
    }
    lastError = null;
    return true;
  }
}
