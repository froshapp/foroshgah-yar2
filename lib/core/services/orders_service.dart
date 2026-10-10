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

      final res = await auth.api.dio.get('orders', queryParameters: {
        'page': _page,
        'per_page': 20,
        'status': 'any',
      });

      List list = [];
      if (res.data is Map) {
        final m = res.data as Map;
        if (m['orders'] is List) list = m['orders'] as List;
        else if (m['data'] is List) list = m['data'] as List;
        if (m['pagination'] is Map) {
          _total = int.tryParse(m['pagination']['total']?.toString() ?? '') ?? _total;
        }
      } else if (res.data is List) {
        list = res.data as List;
      }

      final items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (refresh) {
        _orders = items;
      } else {
        _orders.addAll(items);
      }
      _hasMore = items.length >= 20;
      _page++;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        _error = body['message'].toString();
      } else if (body is Map && body['code'] != null) {
        _error = body['code'].toString();
      } else {
        _error = 'خطا: ${e.response?.statusCode ?? e.message}';
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
    try {
      return _orders.firstWhere((o) => o['id'].toString() == id.toString());
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus(AuthService auth, int orderId, String status) async {
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}
      // plugin expects status without wc- prefix sometimes
      final res = await auth.api.dio.put('orders/$orderId', data: {'status': status});
      if (res.statusCode == 200 || res.statusCode == 201) {
        final idx = _orders.indexWhere((o) => o['id'].toString() == orderId.toString());
        if (idx >= 0) {
          _orders[idx]['status'] = status;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
