import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  Dio? _dio;
  String? _baseUrl;
  String? _token;

  Dio get dio {
    if (_dio == null) {
      throw Exception('ابتدا آدرس سایت را تنظیم کنید');
    }
    return _dio!;
  }

  void setBaseUrl(String siteUrl) {
    var url = siteUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _baseUrl = '$url/wp-json/foroshgah-yar/v1';

    _dio = Dio(BaseOptions(
      baseUrl: '$_baseUrl/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ForoshgahYar-Android/1.0',
      },
      validateStatus: (code) => code != null && code < 500,
    ));

    // رفع مشکل SSL بعضی هاست‌های ایران
    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fy_token', token);
    if (_baseUrl != null) {
      await prefs.setString('fy_base_url', _baseUrl!);
    }
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('fy_token');
    final savedUrl = prefs.getString('fy_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setBaseUrl(savedUrl.replaceAll('/wp-json/foroshgah-yar/v1', ''));
      _token = prefs.getString('fy_token');
    }
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fy_token');
    await prefs.remove('fy_base_url');
  }
}
