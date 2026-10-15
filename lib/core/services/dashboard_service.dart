import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class DashboardService extends ChangeNotifier {
  Map<String, dynamic> _stats = {
    'today_sales': 0,
    'today_orders': 0,
    'total_orders': 0,
    'total_products': 0,
    'total_customers': 0,
  };
  List _daily = [];
  List get dailySales => _daily;
  bool _loading = false;
  String? _error;

  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0;
  }

  Future<void> fetchStats(AuthService auth, {int days = 7}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final res = await auth.api.dio.get('dashboard', queryParameters: {'days': days});
      final data = res.data;
      if (data is Map) {
        final raw = Map<String, dynamic>.from(data);
        final nested = raw['stats'] is Map ? Map<String, dynamic>.from(raw['stats'] as Map) : <String, dynamic>{};
        _stats = {
          'today_sales': _toInt(raw['today_sales'] ?? nested['today_sales'] ?? nested['total_sales']),
          'today_orders': _toInt(raw['today_orders'] ?? nested['today_orders'] ?? nested['orders_count']),
          'total_orders': _toInt(raw['total_orders'] ?? nested['total_orders']),
          'total_products': _toInt(raw['total_products'] ?? nested['total_products']),
          'total_customers': _toInt(raw['total_customers'] ?? nested['total_customers'] ?? nested['customers']),
        };
        final ds = raw['daily_sales'] ?? nested['daily_sales'];
        _daily = ds is List ? List.from(ds) : [];
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
