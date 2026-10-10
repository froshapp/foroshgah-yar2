import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class DashboardService extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
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
    return int.tryParse(v.toString().replaceAll(',', '').replaceAll('٬', '')) ?? 0;
  }

  Future<void> fetchStats(AuthService auth) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final res = await auth.api.dio.get('dashboard');
      final data = res.data;

      Map<String, dynamic> raw = {};
      if (data is Map) {
        raw = Map<String, dynamic>.from(data);
        // nested structures
        if (raw['stats'] is Map) {
          raw.addAll(Map<String, dynamic>.from(raw['stats'] as Map));
        }
        if (raw['data'] is Map) {
          raw.addAll(Map<String, dynamic>.from(raw['data'] as Map));
        }
        if (raw['today'] is Map) {
          final t = Map<String, dynamic>.from(raw['today'] as Map);
          raw['today_sales'] = t['sales'] ?? t['total'] ?? t['revenue'];
          raw['today_orders'] = t['orders'] ?? t['count'];
        }
      }

      _stats = {
        'today_sales': _toInt(raw['today_sales'] ?? raw['sales_today'] ?? raw['today_revenue'] ?? raw['revenue_today'] ?? raw['sales']),
        'today_orders': _toInt(raw['today_orders'] ?? raw['orders_today'] ?? raw['order_count_today']),
        'total_orders': _toInt(raw['total_orders'] ?? raw['orders_count'] ?? raw['orders_total'] ?? raw['order_count']),
        'total_products': _toInt(raw['total_products'] ?? raw['products_count'] ?? raw['product_count'] ?? raw['products_total']),
      };

      // fallback: if all zero, try orders + products count endpoints
      if (_stats['total_orders'] == 0) {
        try {
          final o = await auth.api.dio.get('orders', queryParameters: {'page': 1, 'per_page': 1});
          final total = o.headers.value('x-wp-total') ?? o.data?['total'];
          if (total != null) _stats['total_orders'] = _toInt(total);
        } catch (_) {}
      }
      if (_stats['total_products'] == 0) {
        try {
          final p = await auth.api.dio.get('products', queryParameters: {'page': 1, 'per_page': 1});
          final total = p.headers.value('x-wp-total') ?? p.data?['total'];
          if (total != null) _stats['total_products'] = _toInt(total);
        } catch (_) {}
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
