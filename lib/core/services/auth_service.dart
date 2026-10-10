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
  ApiClient get api => _api;

  Future<String?> getSavedSiteUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fy_site_url');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fy_token');
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fy_token');
      final siteUrl = prefs.getString('fy_site_url');

      if (token == null || token.isEmpty || siteUrl == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _api.setBaseUrl(siteUrl);
      try {
        await _api.ensureReachable();
      } catch (_) {}
      await _api.saveToken(token);

      final res = await _api.dio.get('site-info');
      if (res.statusCode == 200 && res.data != null) {
        _site = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
        _user = {'display_name': prefs.getString('fy_user_name') ?? 'مدیر'};
        _isAuthenticated = true;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
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
        await prefs.setString('fy_site_url', siteUrl.trim());
        _user = response.data['user'] is Map
            ? Map<String, dynamic>.from(response.data['user'] as Map)
            : null;
        _site = response.data['site'] is Map
            ? Map<String, dynamic>.from(response.data['site'] as Map)
            : null;
        if (_user?['display_name'] != null) {
          await prefs.setString('fy_user_name', _user!['display_name'].toString());
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message']?.toString() ?? 'خطا در اتصال';
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        _error = e.response!.data['message'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _error = 'زمان اتصال تمام شد. اینترنت را چک کنید.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'خطای شبکه: ${e.message ?? "اتصال برقرار نشد"}';
      } else {
        _error = 'خطا: ${e.message ?? e.type.toString()}';
      }
    } catch (e) {
      _error = 'خطای ناشناخته: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// خروج از صفحه اصلی — توکن پاک نمی‌شود تا دوباره وارد کردن لازم نباشد
  Future<void> logout({bool clearToken = false}) async {
    try {
      await _api.dio.post('logout');
    } catch (_) {}

    if (clearToken) {
      await _api.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fy_site_url');
      await prefs.remove('fy_user_name');
    }

    _isAuthenticated = false;
    _user = null;
    _site = null;
    _error = null;
    notifyListeners();
  }
}
