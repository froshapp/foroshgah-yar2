import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class ProductsService extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _search = '';

  List<Map<String, dynamic>> get products => _products;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts(AuthService auth, {bool refresh = false, String? search}) async {
    if (search != null) _search = search;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _products = [];
    }
    if (!_hasMore && !refresh) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_search.isNotEmpty) params['search'] = _search;

      final res = await auth.api.dio.get('products', queryParameters: params);

      List list = [];
      if (res.data is List) {
        list = res.data;
      } else if (res.data is Map && res.data['products'] is List) {
        list = res.data['products'];
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'];
      }

      final items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (refresh) {
        _products = items;
      } else {
        _products.addAll(items);
      }
      _hasMore = items.length >= 20;
      _page++;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'خطا در دریافت محصولات';
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
