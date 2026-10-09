import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class DashboardService extends ChangeNotifier {
  Map<String, dynamic>? _stats;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchStats(AuthService auth) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}
      final res = await auth.api.dio.get('dashboard');
      if (res.data is Map) {
        _stats = Map<String, dynamic>.from(res.data);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
