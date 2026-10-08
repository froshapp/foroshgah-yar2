import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class OrdersService extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  void setApi(ApiClient api) {
    // uses shared instance via auth if needed
  }

  Future<void> fetchOrders({String? status, int page = 1}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Will be connected via AuthService.api in screens
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }
}
