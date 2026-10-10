import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class ProductsService extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _search = '';
  int? _categoryId;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int? get categoryId => _categoryId;

  Future<void> fetchCategories(AuthService auth) async {
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}
      final res = await auth.api.dio.get('products/categories');
      List list = [];
      if (res.data is Map && res.data['categories'] is List) {
        list = res.data['categories'] as List;
      } else if (res.data is List) {
        list = res.data as List;
      }
      _categories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchProducts(AuthService auth, {bool refresh = false, String? search, int? categoryId}) async {
    if (search != null) _search = search;
    if (categoryId != null) {
      _categoryId = categoryId == 0 ? null : categoryId;
    }
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

      final params = <String, dynamic>{'page': _page, 'per_page': 20, 'status': 'any'};
      if (_search.isNotEmpty) params['search'] = _search;
      if (_categoryId != null && _categoryId! > 0) params['category'] = _categoryId;

      final res = await auth.api.dio.get('products', queryParameters: params);

      List list = [];
      if (res.data is Map) {
        final m = res.data as Map;
        if (m['products'] is List) list = m['products'] as List;
        else if (m['data'] is List) list = m['data'] as List;
      } else if (res.data is List) {
        list = res.data as List;
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

  void clearCategory() {
    _categoryId = null;
  }

  Future<bool> updateProduct(
    AuthService auth,
    int id, {
    String? price,
    String? regularPrice,
    int? stock,
    String? status,
  }) async {
    try {
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final body = <String, dynamic>{};
      if (price != null) body['price'] = price;
      if (regularPrice != null) body['regular_price'] = regularPrice;
      if (stock != null) {
        body['stock_quantity'] = stock;
        body['manage_stock'] = true;
      }
      if (status != null) body['status'] = status;

      final res = await auth.api.dio.put('products/$id', data: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final idx = _products.indexWhere((p) => p['id'].toString() == id.toString());
        if (idx >= 0) {
          if (price != null) _products[idx]['price'] = price;
          if (regularPrice != null) _products[idx]['regular_price'] = regularPrice;
          if (stock != null) _products[idx]['stock_quantity'] = stock;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int> bulkUpdatePrice(AuthService auth, List<int> ids, {required String price}) async {
    int ok = 0;
    for (final id in ids) {
      if (await updateProduct(auth, id, price: price, regularPrice: price)) ok++;
    }
    return ok;
  }
}
