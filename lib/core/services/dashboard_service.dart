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

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['orders'] is List) return data['orders'] as List;
      if (data['products'] is List) return data['products'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return [];
  }

  int _totalFrom(Response res, List list) {
    final h = res.headers.value('x-wp-total') ??
        res.headers.value('X-WP-Total');
    if (h != null) return _toInt(h);
    if (res.data is Map) {
      final m = res.data as Map;
      for (final k in ['total', 'total_orders', 'total_products', 'found', 'count']) {
        if (m[k] != null) return _toInt(m[k]);
      }
    }
    return list.length;
  }

  Future<void> fetchStats(AuthService auth) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      // dashboard endpoint
      try {
        final res = await auth.api.dio.get('dashboard');
        if (res.data is Map) {
          final raw = Map<String, dynamic>.from(res.data as Map);
          if (raw['stats'] is Map) raw.addAll(Map<String, dynamic>.from(raw['stats'] as Map));
          if (raw['data'] is Map) raw.addAll(Map<String, dynamic>.from(raw['data'] as Map));
          if (raw['today'] is Map) {
            final t = Map<String, dynamic>.from(raw['today'] as Map);
            raw['today_sales'] = t['sales'] ?? t['total'] ?? t['revenue'];
            raw['today_orders'] = t['orders'] ?? t['count'];
          }
          final ts = _toInt(raw['today_sales'] ?? raw['sales_today']);
          final to = _toInt(raw['today_orders'] ?? raw['orders_today']);
          final totO = _toInt(raw['total_orders'] ?? raw['orders_count']);
          final totP = _toInt(raw['total_products'] ?? raw['products_count']);
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

      // orders: get total + today from several pages
      try {
        final oRes = await auth.api.dio.get('orders', queryParameters: {'page': 1, 'per_page': 100});
        final list = _extractList(oRes.data);
        final total = _totalFrom(oRes, list);
        if (total > (_stats['total_orders'] as int)) {
          _stats['total_orders'] = total;
        }

        // if plugin doesn't send total header, try page 2 count estimate
        if (total <= list.length && list.length >= 100) {
          try {
            final o2 = await auth.api.dio.get('orders', queryParameters: {'page': 2, 'per_page': 100});
            final list2 = _extractList(o2.data);
            final t2 = _totalFrom(o2, list2);
            if (t2 > (_stats['total_orders'] as int)) {
              _stats['total_orders'] = t2;
            } else {
              _stats['total_orders'] = list.length + list2.length;
            }
            list.addAll(list2);
          } catch (_) {}
        }

        final now = DateTime.now();
        int todayCount = 0;
        double todaySales = 0;
        for (final item in list) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final dateStr = m['date_created']?.toString() ?? m['date']?.toString() ?? '';
          final d = DateTime.tryParse(dateStr);
          if (d != null && d.year == now.year && d.month == now.month && d.day == now.day) {
            todayCount++;
            final st = m['status']?.toString() ?? '';
            if (st != 'cancelled' && st != 'refunded' && st != 'failed') {
              todaySales += _toDouble(m['total']);
            }
          }
        }
        _stats['today_orders'] = todayCount;
        _stats['today_sales'] = todaySales.round();
      } catch (_) {}

      // products total
      try {
        final pRes = await auth.api.dio.get('products', queryParameters: {'page': 1, 'per_page': 1});
        final list = _extractList(pRes.data);
        final total = _totalFrom(pRes, list);
        if (total > 0) {
          _stats['total_products'] = total;
        } else {
          // try larger page
          final p2 = await auth.api.dio.get('products', queryParameters: {'page': 1, 'per_page': 100});
          final list2 = _extractList(p2.data);
          final t2 = _totalFrom(p2, list2);
          _stats['total_products'] = t2 > 0 ? t2 : list2.length;
        }
      } catch (_) {}
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
