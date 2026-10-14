import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NotifBadgeService extends ChangeNotifier {
  int count = 0;

  Future<void> refresh(AuthService auth) async {
    try {
      final res = await auth.api.dio.get('notifications');
      int c = 0;
      if (res.data is Map) {
        if (res.data['count'] != null) {
          c = int.tryParse('${res.data['count']}') ?? 0;
        } else {
          final items = res.data['items'];
          if (items is List) c = items.length;
        }
      }
      count = c;
      notifyListeners();
    } catch (_) {}
  }

  void setCount(int c) {
    count = c;
    notifyListeners();
  }

  void decrement([int n = 1]) {
    count = (count - n).clamp(0, 9999);
    notifyListeners();
  }
}
