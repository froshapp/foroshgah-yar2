import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _site;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get site => _site;
  String get siteName {
    final n = _site?['name']?.toString();
    if (n != null && n.isNotEmpty) return n;
    return _user?['display_name']?.toString() ?? '';
  }

  ApiClient get api => _api;

  Future<String?> getSavedSiteUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fy_site_url');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fy_token');
  }

  /// ورود خودکار — اگر توکن ذخیره باشد حتی با خطای موقت شبکه، نشست حفظ می‌شود
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fy_token');
      final siteUrl = prefs.getString('fy_site_url');

      if (token == null || token.isEmpty || siteUrl == null || siteUrl.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _api.setBaseUrl(siteUrl);
      await _api.saveToken(token);

      // بازگردانی اطلاعات ذخیره‌شده
      final savedName = prefs.getString('fy_user_name') ?? 'مدیر';
      final savedEmail = prefs.getString('fy_user_email') ?? '';
      final savedSiteName = prefs.getString('fy_site_name') ?? '';
      _user = {
        'display_name': savedName,
        'email': savedEmail,
      };
      if (savedSiteName.isNotEmpty) {
        _site = {
          'name': savedSiteName,
          'url': siteUrl,
        };
      }

      // نشست را بلافاصله فعال کن تا صفحه لاگین نیاید
      _isAuthenticated = true;
      notifyListeners();

      try {
        await _api.ensureReachable();
      } catch (_) {}

      try {
        final res = await _api.dio.get('site-info');
        if (res.statusCode == 200 && res.data is Map) {
          final d = Map<String, dynamic>.from(res.data as Map);
          if (d['site'] is Map) {
            _site = Map<String, dynamic>.from(d['site'] as Map);
          } else {
            _site = d;
          }
          if (d['user'] is Map) {
            _user = Map<String, dynamic>.from(d['user'] as Map);
          }
          if (_site?['name'] != null) {
            await prefs.setString('fy_site_name', _site!['name'].toString());
          }
          if (_user?['display_name'] != null) {
            await prefs.setString('fy_user_name', _user!['display_name'].toString());
          }
          if (_user?['email'] != null) {
            await prefs.setString('fy_user_email', _user!['email'].toString());
          }
        } else if (res.statusCode == 401) {
          // فقط در صورت ۴۰۱ واقعی خارج شو
          _isAuthenticated = false;
          await prefs.remove('fy_token');
        }
      } catch (_) {
        // خطای شبکه: نشست را نگه دار
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// پس از بازگشت به اپ — اتصال را دوباره برقرار کن
  Future<void> revalidateSession() async {
    if (!_isAuthenticated) return;
    try {
      await _api.ensureReachable();
      final res = await _api.dio.get('site-info');
      if (res.statusCode == 401) {
        _isAuthenticated = false;
        notifyListeners();
      } else if (res.statusCode == 200 && res.data is Map) {
        final d = Map<String, dynamic>.from(res.data as Map);
        if (d['site'] is Map) _site = Map<String, dynamic>.from(d['site'] as Map);
        if (d['user'] is Map) _user = Map<String, dynamic>.from(d['user'] as Map);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> connectWithToken({
    required String siteUrl,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _api.setBaseUrl(siteUrl);
      try {
        await _api.ensureReachable();
      } catch (_) {}

      final response = await _api.dio.post('connect', data: {'token': token});

      if (response.statusCode == 200 && response.data['success'] == true) {
        await _api.saveToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fy_token', token);
        await prefs.setString('fy_site_url', siteUrl);

        final data = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
        _user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null;
        _site = data['site'] is Map ? Map<String, dynamic>.from(data['site'] as Map) : {'url': siteUrl};

        if (_user?['display_name'] != null) {
          await prefs.setString('fy_user_name', _user!['display_name'].toString());
        }
        if (_user?['email'] != null) {
          await prefs.setString('fy_user_email', _user!['email'].toString());
        }
        if (_site?['name'] != null) {
          await prefs.setString('fy_site_name', _site!['name'].toString());
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.data is Map
          ? (response.data['message']?.toString() ?? 'اتصال ناموفق')
          : 'اتصال ناموفق';
    } on DioException catch (e) {
      _error = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? e.message)
          : (e.message ?? 'خطای شبکه');
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout({bool clearToken = true}) async {
    try {
      await _api.dio.post('logout');
    } catch (_) {}
    if (clearToken) {
      await _api.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fy_token');
      await prefs.remove('fy_site_url');
      await prefs.remove('fy_user_name');
      await prefs.remove('fy_user_email');
      await prefs.remove('fy_site_name');
    }
    _isAuthenticated = false;
    _user = null;
    _site = null;
    notifyListeners();
  }
}
