import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class DashboardService extends ChangeNotifier {
  Map<String, dynamic> _stats = {
    'today_sales': 0,
    'today_orders': 0,
    'total_orders': 0,
    'total_products': 0,
  };
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

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '').replaceAll('٬', '')) ?? 0;
  }

  Future<void> fetchStats(AuthService auth) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      // 1) try dedicated dashboard endpoint
      try {
        final res = await auth.api.dio.get('dashboard');
        final data = res.data;
        if (data is Map) {
          final raw = Map<String, dynamic>.from(data);
          if (raw['stats'] is Map) raw.addAll(Map<String, dynamic>.from(raw['stats'] as Map));
          if (raw['data'] is Map) raw.addAll(Map<String, dynamic>.from(raw['data'] as Map));
          if (raw['today'] is Map) {
            final t = Map<String, dynamic>.from(raw['today'] as Map);
            raw['today_sales'] = t['sales'] ?? t['total'] ?? t['revenue'];
            raw['today_orders'] = t['orders'] ?? t['count'];
          }
          final ts = _toInt(raw['today_sales'] ?? raw['sales_today'] ?? raw['today_revenue']);
          final to = _toInt(raw['today_orders'] ?? raw['orders_today']);
          final totO = _toInt(raw['total_orders'] ?? raw['orders_count'] ?? raw['order_count']);
          final totP = _toInt(raw['total_products'] ?? raw['products_count'] ?? raw['product_count']);
          if (ts + to + totO + totP > 0) {
            _stats = {
              'today_sales': ts,
              'today_orders': to,
              'total_orders': totO,
              'total_products': totP,
            };
          }
        }
      } catch (_) {}

      // 2) fallback: compute from orders + products
      if (_stats['total_orders'] == 0 || _stats['today_orders'] == 0 || _stats['today_sales'] == 0) {
        try {
          final oRes = await auth.api.dio.get('orders', queryParameters: {'page': 1, 'per_page': 50});
          List list = [];
          if (oRes.data is List) {
            list = oRes.data as List;
          } else if (oRes.data is Map) {
            list = (oRes.data['orders'] ?? oRes.data['data'] ?? []) as List? ?? [];
          }
          final headerTotal = oRes.headers.value('x-wp-total');
          if (headerTotal != null) {
            _stats['total_orders'] = _toInt(headerTotal);
          } else if (list.isNotEmpty && _stats['total_orders'] == 0) {
            _stats['total_orders'] = list.length;
          }

          final now = DateTime.now();
          int todayCount = 0;
          double todaySales = 0;
          for (final item in list) {
            if (item is! Map) continue;
            final m = Map<String, dynamic>.from(item);
            final dateStr = m['date_created']?.toString() ?? m['date']?.toString() ?? '';
            DateTime? d;
            try {
              d = DateTime.tryParse(dateStr);
            } catch (_) {}
            if (d != null && d.year == now.year && d.month == now.month && d.day == now.day) {
              todayCount++;
              todaySales += _toDouble(m['total']);
            }
          }
          if (todayCount > 0 || _stats['today_orders'] == 0) {
            _stats['today_orders'] = todayCount;
            _stats['today_sales'] = todaySales.round();
          }
        } catch (_) {}
      }

      if (_stats['total_products'] == 0) {
        try {
          final pRes = await auth.api.dio.get('products', queryParameters: {'page': 1, 'per_page': 1});
          final headerTotal = pRes.headers.value('x-wp-total');
          if (headerTotal != null) {
            _stats['total_products'] = _toInt(headerTotal);
          } else if (pRes.data is Map && pRes.data['total'] != null) {
            _stats['total_products'] = _toInt(pRes.data['total']);
          } else if (pRes.data is List) {
            _stats['total_products'] = (pRes.data as List).length;
          }
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
