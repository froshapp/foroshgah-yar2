import 'package:flutter/foundation.dart';

class ProductsService extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }
}
