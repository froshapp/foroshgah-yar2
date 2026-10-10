import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';
import 'order_detail_screen.dart';

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
        return const Color(0xFF10B981);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'pending':
      case 'on-hold':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'refunded':
      case 'failed':
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

  String _customerName(Map<String, dynamic> o) {
    // customer may be map, string, or nested billing
    final c = o['customer'];
    if (c is Map) {
      final name = c['name']?.toString() ??
          '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    if (c is String && c.isNotEmpty && !c.startsWith('{')) return c;

    final billing = o['billing'];
    if (billing is Map) {
      final name = '${billing['first_name'] ?? ''} ${billing['last_name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }

    return o['customer_name']?.toString() ??
        o['billing_name']?.toString() ??
        'مشتری';
  }

  String _customerPhone(Map<String, dynamic> o) {
    final c = o['customer'];
    if (c is Map && c['phone'] != null) return c['phone'].toString();
    final billing = o['billing'];
    if (billing is Map && billing['phone'] != null) return billing['phone'].toString();
    return o['phone']?.toString() ?? '';
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return '—';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
    if (mounted) {
      final auth = context.read<AuthService>();
      context.read<OrdersService>().fetchOrders(auth, refresh: true);
    }
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(svc.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
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
                                final total = o['total'] ?? o['total_formatted'];
                                final date = o['date_created']?.toString() ?? o['date']?.toString() ?? '';
                                final dateShort = date.length >= 10 ? date.substring(0, 10) : date;

                                return Material(
                                  color: const Color(0xFF252640),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    onTap: () => _openOrder(o),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('#$id',
                                                  style: const TextStyle(
                                                      color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 14)),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(_statusLabel(status),
                                                    style: TextStyle(
                                                        color: _statusColor(status),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(_customerName(o),
                                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                                          if (_customerPhone(o).isNotEmpty)
                                            Text(_customerPhone(o),
                                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                                                textDirection: TextDirection.ltr),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(_fmtMoney(total),
                                                  style: const TextStyle(
                                                      color: Color(0xFF10B981),
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600)),
                                              const Spacer(),
                                              if (dateShort.isNotEmpty)
                                                Text(dateShort, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.chevron_left, color: Colors.white24, size: 18),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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
