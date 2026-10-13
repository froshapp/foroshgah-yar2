import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  Dio? _dio;
  String? _baseUrl;
  String? _token;
  String? _siteHost;

  Dio get dio {
    if (_dio == null) {
      throw Exception('ابتدا آدرس سایت را تنظیم کنید');
    }
    return _dio!;
  }

  /// Resolve domain via DNS-over-HTTPS (works even when system DNS fails)
  Future<String?> _resolveViaDoh(String host) async {
    final servers = <String>[
      'https://1.1.1.1/dns-query',
      'https://8.8.8.8/resolve',
      'https://1.0.0.1/dns-query',
    ];

    for (final server in servers) {
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Accept': 'application/dns-json'},
        ));
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final c = HttpClient();
          c.badCertificateCallback = (cert, host, port) => true;
          return c;
        };

        final res = await dio.get(server, queryParameters: {
          'name': host,
          'type': 'A',
        });

        final data = res.data;
        if (data is Map && data['Answer'] is List) {
          for (final ans in data['Answer']) {
            if (ans is Map && (ans['type'] == 1) && ans['data'] != null) {
              final ip = ans['data'].toString();
              if (ip.contains('.')) return ip;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  void _buildDio(String baseUrl, {String? hostHeader}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        if (hostHeader != null) 'Host': hostHeader,
      },
      validateStatus: (code) => code != null && code < 500,
    ));

    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = const Duration(seconds: 60);
      return client;
    };

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (hostHeader != null) {
          options.headers['Host'] = hostHeader;
        }
        return handler.next(options);
      },
    ));
  }

  void setBaseUrl(String siteUrl) {
    var url = siteUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http')) url = 'https://$url';

    final uri = Uri.parse(url);
    _siteHost = uri.host;
    _baseUrl = '$url/wp-json/foroshgah-yar/v1';
    _buildDio(_baseUrl!);
  }

  /// If system DNS fails, resolve via DoH and reconnect by IP
  Future<void> ensureReachable() async {
    if (_siteHost == null || _baseUrl == null) return;

    try {
      final result = await InternetAddress.lookup(_siteHost!)
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty) return;
    } catch (_) {}

    final ip = await _resolveViaDoh(_siteHost!);
    if (ip == null) {
      throw DioException(
        requestOptions: RequestOptions(path: _baseUrl!),
        type: DioExceptionType.connectionError,
        message: 'DNS: نتوانست دامنه را پیدا کند ($_siteHost)',
      );
    }

    final path = '/wp-json/foroshgah-yar/v1';
    _buildDio('https://$ip$path', hostHeader: _siteHost);
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
      final site = savedUrl.replaceAll('/wp-json/foroshgah-yar/v1', '');
      setBaseUrl(site);
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
