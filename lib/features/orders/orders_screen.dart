import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';
import '../../core/theme/app_theme.dart';
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

  Color _statusColor(String? status) {
    switch (status?.replaceFirst('wc-', '')) {
      case 'completed':
        return AppColors.cyan;
      case 'processing':
        return AppColors.blue;
      case 'pending':
        return AppColors.orange;
      case 'on-hold':
        return AppColors.purple;
      case 'cancelled':
      case 'refunded':
      case 'failed':
        return AppColors.red;
      default:
        return AppColors.textDim;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.replaceFirst('wc-', '')) {
      case 'completed':
        return 'تکمیل شده';
      case 'processing':
        return 'در حال انجام';
      case 'pending':
        return 'در انتظار پرداخت';
      case 'on-hold':
        return 'در انتظار بررسی';
      case 'cancelled':
        return 'لغو شده';
      case 'refunded':
        return 'مسترد شده';
      case 'failed':
        return 'ناموفق';
      default:
        return status ?? '—';
    }
  }

  String _customerName(Map<String, dynamic> o) {
    final c = o['customer'];
    if (c is Map) {
      final n = c['name']?.toString() ?? '';
      if (n.isNotEmpty) return n;
    }
    final b = o['billing'];
    if (b is Map) {
      final n = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
      if (n.isNotEmpty) return n;
    }
    return 'مشتری';
  }

  String _customerPhone(Map<String, dynamic> o) {
    final c = o['customer'];
    if (c is Map && (c['phone']?.toString().isNotEmpty ?? false)) {
      return c['phone'].toString();
    }
    final b = o['billing'];
    if (b is Map) return b['phone']?.toString() ?? '';
    return '';
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf تومان';
  }

  String _toJalali(String date) {
    if (date.length < 10) return date;
    final parts = date.substring(0, 10).split('-');
    if (parts.length != 3) return date;
    final gy = int.tryParse(parts[0]) ?? 0;
    final gm = int.tryParse(parts[1]) ?? 0;
    final gd = int.tryParse(parts[2]) ?? 0;
    if (gy == 0) return date;
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd + gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + days ~/ 31;
      jd = 1 + days % 31;
    } else {
      jm = 7 + (days - 186) ~/ 30;
      jd = 1 + (days - 186) % 30;
    }
    return '${jy.toString().padLeft(4, '0')}/${jm.toString().padLeft(2, '0')}/${jd.toString().padLeft(2, '0')}';
  }



  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<OrdersService>();

    return SafeArea(
      child: Column(
        children: [
          GlassHeader(
            title: 'سفارشات',
            actions: [
              if (svc.loading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: MiniLoader(size: 18),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () => svc.fetchOrders(auth, refresh: true),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(auth, svc),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AuthService auth, OrdersService svc) {
    if (svc.loading && svc.orders.isEmpty) {
      return const Center(child: MiniLoader());
    }

    if (svc.error != null && svc.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                svc.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => svc.fetchOrders(auth, refresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (svc.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(svc.error ?? 'سفارشی یافت نشد', style: const TextStyle(color: AppColors.textDim), textAlign: TextAlign.center),
            if (svc.debug != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(svc.debug!, style: const TextStyle(color: AppColors.textMute, fontSize: 11), textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => svc.fetchOrders(auth, refresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purple,
      backgroundColor: AppColors.card,
      onRefresh: () => svc.fetchOrders(auth, refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: svc.orders.length + (svc.hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= svc.orders.length) {
            svc.fetchOrders(auth);
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: MiniLoader(size: 22)),
            );
          }
          final o = svc.orders[i];
          final id = o['id']?.toString() ?? o['number']?.toString() ?? '—';
          final status = o['status']?.toString();
          final total = o['total'] ?? o['total_formatted'];
          final date = o['date_created']?.toString() ?? o['date']?.toString() ?? '';
          final dateShort = date.length >= 10 ? _toJalali(date) : date;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NeonCard(
              onTap: () => _openOrder(o),
              borderColor: AppColors.purple.withOpacity(0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#$id',
                        style: const TextStyle(
                          color: AppColors.purpleGlow,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _customerName(o),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (_customerPhone(o).isNotEmpty)
                    Text(
                      _customerPhone(o),
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      textDirection: TextDirection.ltr,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _fmtMoney(total),
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateShort,
                        style: const TextStyle(color: AppColors.textMute, fontSize: 11),
                      ),
                      const Icon(Icons.chevron_left, color: AppColors.textMute, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
