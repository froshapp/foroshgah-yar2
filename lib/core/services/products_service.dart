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
        list = res.data as List;
      } else if (res.data is Map && res.data['products'] is List) {
        list = res.data['products'] as List;
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'] as List;
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
        // update local list
        final idx = _products.indexWhere((p) => p['id'].toString() == id.toString());
        if (idx >= 0) {
          if (price != null) _products[idx]['price'] = price;
          if (regularPrice != null) _products[idx]['regular_price'] = regularPrice;
          if (stock != null) _products[idx]['stock_quantity'] = stock;
          if (status != null) _products[idx]['status'] = status;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int> bulkUpdatePrice(AuthService auth, List<int> ids, {required String price, bool percent = false}) async {
    int ok = 0;
    for (final id in ids) {
      String newPrice = price;
      if (percent) {
        final p = _products.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => {});
        final old = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
        final pct = double.tryParse(price) ?? 0;
        newPrice = (old * (1 + pct / 100)).round().toString();
      }
      if (await updateProduct(auth, id, price: newPrice, regularPrice: newPrice)) ok++;
    }
    return ok;
  }
}
