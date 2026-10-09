import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      context.read<OrdersService>().fetchOrders(auth, refresh: true);
    });
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
      case 'تکمیل شده':
        return const Color(0xFF10B981);
      case 'processing':
      case 'در حال انجام':
        return const Color(0xFF3B82F6);
      case 'pending':
      case 'در انتظار':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'لغو شده':
      case 'refunded':
        return const Color(0xFFEF4444);
      default:
        return Colors.white54;
    }
  }

  String _statusLabel(String? s) {
    const map = {
      'completed': 'تکمیل شده',
      'processing': 'در حال انجام',
      'pending': 'در انتظار',
      'on-hold': 'در انتظار بررسی',
      'cancelled': 'لغو شده',
      'refunded': 'مسترد شده',
      'failed': 'ناموفق',
    };
    return map[s] ?? s ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<OrdersService>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('سفارشات', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => svc.fetchOrders(auth, refresh: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: svc.loading && svc.orders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : svc.error != null && svc.orders.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(svc.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                      ))
                    : svc.orders.isEmpty
                        ? const Center(child: Text('سفارشی یافت نشد', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            color: const Color(0xFF6C63FF),
                            onRefresh: () => svc.fetchOrders(auth, refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: svc.orders.length,
                              itemBuilder: (ctx, i) {
                                final o = svc.orders[i];
                                final id = o['id']?.toString() ?? o['number']?.toString() ?? '—';
                                final status = o['status']?.toString();
                                final total = o['total']?.toString() ?? o['total_formatted']?.toString() ?? '—';
                                final name = o['billing']?['first_name'] != null
                                    ? '${o['billing']['first_name']} ${o['billing']['last_name'] ?? ''}'
                                    : o['customer_name']?.toString() ?? o['customer']?.toString() ?? 'مشتری';
                                final date = o['date_created']?.toString() ?? o['date']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252640),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('#$id', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(_statusLabel(status),
                                                style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(name.trim(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(total, style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          if (date.isNotEmpty)
                                            Text(date.length > 10 ? date.substring(0, 10) : date,
                                                style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
