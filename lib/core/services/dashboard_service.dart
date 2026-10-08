import 'package:flutter/foundation.dart';

class DashboardService extends ChangeNotifier {
  Map<String, dynamic>? _stats;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _loading = false;
    notifyListeners();
  }
}
