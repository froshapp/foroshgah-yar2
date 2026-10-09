import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class OrdersService extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  List<Map<String, dynamic>> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

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
      });

      List list = [];
      if (res.data is List) {
        list = res.data;
      } else if (res.data is Map && res.data['orders'] is List) {
        list = res.data['orders'];
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'];
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
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'خطا در دریافت سفارشات';
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(AuthService auth, int orderId, String status) async {
    try {
      final res = await auth.api.dio.put('orders/$orderId', data: {'status': status});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
