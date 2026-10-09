import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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

  Future<bool> connectWithToken({
    required String siteUrl,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _api.setBaseUrl(siteUrl);

      final response = await _api.dio.post('connect', data: {'token': token});

      if (response.statusCode == 200 && response.data['success'] == true) {
        await _api.saveToken(token);
        _user = response.data['user'] is Map
            ? Map<String, dynamic>.from(response.data['user'])
            : null;
        _site = response.data['site'] is Map
            ? Map<String, dynamic>.from(response.data['site'])
            : null;
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
        _error = 'خطای شبکه: ${e.message ?? e.type}';
      } else {
        _error = 'خطا: ${e.message ?? e.type}';
      }
    } catch (e) {
      _error = 'خطای ناشناخته: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('logout');
    } catch (_) {}
    await _api.clearToken();
    _isAuthenticated = false;
    _user = null;
    _site = null;
    notifyListeners();
  }
}
