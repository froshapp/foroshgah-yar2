import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class OrdersService extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  int _total = 0;

  List<Map<String, dynamic>> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get total => _total;

  Future<void> fetchOrders(AuthService auth, {bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _orders = [];
    }
    if (!_hasMore && !refresh) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      // try with all statuses first, then without status
      Response? res;
      DioException? lastErr;
      for (final params in [
        {'page': _page, 'per_page': 20, 'status': 'any'},
        {'page': _page, 'per_page': 20},
      ]) {
        try {
          res = await auth.api.dio.get('orders', queryParameters: params);
          break;
        } on DioException catch (e) {
          lastErr = e;
        }
      }
      if (res == null) throw lastErr ?? Exception('no response');

      List list = [];
      if (res.data is Map) {
        final m = Map<String, dynamic>.from(res.data as Map);
        if (m['orders'] is List) {
          list = m['orders'] as List;
        } else if (m['data'] is List) {
          list = m['data'] as List;
        } else if (m['results'] is List) {
          list = m['results'] as List;
        }
        // pagination
        final pag = m['pagination'];
        if (pag is Map) {
          _total = int.tryParse(pag['total']?.toString() ?? '') ?? _total;
        } else if (m['total'] != null) {
          _total = int.tryParse(m['total'].toString()) ?? _total;
        }
        // if success false
        if (m['success'] == false && list.isEmpty) {
          _error = m['message']?.toString() ?? 'خطا در دریافت سفارشات';
        }
      } else if (res.data is List) {
        list = res.data as List;
      }

      final items = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map) items.add(Map<String, dynamic>.from(e));
      }

      if (refresh) {
        _orders = items;
      } else {
        _orders.addAll(items);
      }
      _hasMore = items.length >= 20;
      if (items.isNotEmpty) _page++;
      if (items.isEmpty && _orders.isEmpty && _error == null) {
        _error = null; // empty is valid
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        _error = body['message'].toString();
      } else if (body is Map && body['code'] != null) {
        _error = '${body['code']}: ${body['message'] ?? ''}';
      } else {
        _error = 'خطای ارتباط: ${e.response?.statusCode ?? e.message}';
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchOrder(AuthService auth, int id) async {
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}
      final res = await auth.api.dio.get('orders/$id');
      if (res.data is Map) {
        final m = res.data as Map;
        if (m['order'] is Map) return Map<String, dynamic>.from(m['order'] as Map);
        if (m['id'] != null) return Map<String, dynamic>.from(m);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updateStatus(AuthService auth, int id, String status) async {
    try {
      await auth.api.dio.post('orders/$id', data: {'status': status});
      final idx = _orders.indexWhere((o) => o['id'].toString() == id.toString());
      if (idx >= 0) {
        _orders[idx] = {..._orders[idx], 'status': status};
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
