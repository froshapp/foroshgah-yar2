import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';
import '../../core/theme/app_theme.dart';

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});
  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  bool loading = true;
  Map<String, List<Map<String, dynamic>>> byCustomer = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final auth = context.read<AuthService>();
    final svc = context.read<OrdersService>();
    if (svc.orders.isEmpty) {
      await svc.fetchOrders(auth, refresh: true);
    }
    final map = <String, List<Map<String, dynamic>>>{};
    for (final o in svc.orders) {
      String name = 'مشتری';
      final c = o['customer'];
      if (c is Map && (c['name']?.toString().isNotEmpty ?? false)) {
        name = c['name'].toString();
      } else {
        final b = o['billing'];
        if (b is Map) {
          final n = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
          if (n.isNotEmpty) name = n;
        }
      }
      map.putIfAbsent(name, () => []).add(o);
    }
    byCustomer = map;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final entries = byCustomer.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('سوابق مشتریان', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(child: MiniLoader())
          : entries.isEmpty
              ? const Center(child: Text('سابقه‌ای یافت نشد — ابتدا سفارشات را بارگذاری کنید', style: TextStyle(color: AppColors.textDim), textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeonCard(
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor: AppColors.blue.withOpacity(0.2),
                            child: const Icon(Icons.person, color: AppColors.blue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text('${e.value.length} خرید', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                          ])),
                          const Icon(Icons.chevron_left, color: AppColors.textMute),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
