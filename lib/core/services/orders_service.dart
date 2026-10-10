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
  String? _debug;

  List<Map<String, dynamic>> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get total => _total;
  String? get debug => _debug;

  Future<void> fetchOrders(AuthService auth, {bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _orders = [];
    }
    if (!_hasMore && !refresh) return;

    _loading = true;
    _error = null;
    _debug = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final res = await auth.api.dio.get('orders', queryParameters: {
        'page': _page,
        'per_page': 20,
      });

      List list = [];
      if (res.data is Map) {
        final m = Map<String, dynamic>.from(res.data as Map);
        if (m['success'] == false) {
          _error = (m['message'] ?? 'خطای سرور').toString();
          if (m['file'] != null) _error = '$_error (${m['file']}:${m['line']})';
        }
        if (m['orders'] is List) {
          list = m['orders'] as List;
        } else if (m['data'] is List) {
          list = m['data'] as List;
        }
        final pag = m['pagination'];
        if (pag is Map) {
          _total = int.tryParse(pag['total']?.toString() ?? '') ?? _total;
        }
        if (m['debug'] is Map) {
          _debug = m['debug'].toString();
        }
        if (m['count'] != null) {
          _debug = '${_debug ?? ''} count=${m['count']}';
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
      if (items.isNotEmpty) {
        _page++;
      } else {
        _hasMore = false;
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        _error = (body['message'] ?? body['code'] ?? 'خطای سرور').toString();
        if (e.response?.statusCode != null) {
          _error = '${e.response!.statusCode}: $_error';
        }
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
