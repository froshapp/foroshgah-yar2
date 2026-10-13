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
  final _search = TextEditingController();
  String filter = 'all'; // all | processing | completed | cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersService>().fetchOrders(context.read<AuthService>(), refresh: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _statusColor(String? status) {
    switch (status?.replaceFirst('wc-', '')) {
      case 'completed':
        return AppColors.green;
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
    final raw = (status ?? '').replaceFirst('wc-', '').toLowerCase();
    const map = {
      'completed': 'تکمیل شده',
      'processing': 'در حال پردازش',
      'pending': 'در حال پرداخت',
      'on-hold': 'در انتظار پرداخت',
      'cancelled': 'لغو شده',
      'refunded': 'مسترد شده',
      'failed': 'ناموفق',
    };
    if (map.containsKey(raw)) return map[raw]!;
    var s = status ?? '—';
    s = s.replaceAll('wc-', '');
    s = s.replaceAll(RegExp(r'basalam', caseSensitive: false), 'باسلام');
    s = s.replaceAll(RegExp(r'torob', caseSensitive: false), 'ترب');
    s = s.replaceAll(RegExp(r'pending', caseSensitive: false), 'در انتظار');
    s = s.replaceAll(RegExp(r'processing', caseSensitive: false), 'در حال پردازش');
    s = s.replaceAll(RegExp(r'completed', caseSensitive: false), 'تکمیل شده');
    s = s.replaceAll(RegExp(r'cancelled|canceled', caseSensitive: false), 'لغو شده');
    s = s.replaceAll('-', ' ');
    return s;
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

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = v is num ? v.round() : int.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _date(Map o) {
    final j = o['date_jalali']?.toString();
    if (j != null && j.isNotEmpty && !j.contains('-10-') && !j.startsWith('202')) return j;
    // اگر میلادی بود فقط تاریخ را کوتاه نشان بده
    final d = o['date_created_gmt']?.toString() ?? o['date_created']?.toString() ?? o['date']?.toString() ?? '';
    if (d.length >= 10) {
      // YYYY-MM-DD HH:mm
      final clean = d.replaceAll('T', ' ').substring(0, d.length >= 16 ? 16 : 10);
      return clean;
    }
    return d;
  }

  bool _matchFilter(Map o) {
    final st = (o['status']?.toString() ?? '').replaceFirst('wc-', '').toLowerCase();
    switch (filter) {
      case 'processing':
        return st == 'processing' || st == 'pending' || st == 'on-hold' || st.contains('processing');
      case 'completed':
        return st == 'completed' || st.contains('completed');
      case 'cancelled':
        return st == 'cancelled' || st == 'canceled' || st == 'refunded' || st == 'failed' || st.contains('cancel');
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    final q = _search.text.trim();
    return all.where((o) {
      if (!_matchFilter(o)) return false;
      if (q.isEmpty) return true;
      final id = '${o['id'] ?? ''} ${o['number'] ?? ''}';
      final name = _customerName(o);
      return id.contains(q) || name.contains(q);
    }).toList();
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
    if (mounted) {
      context.read<OrdersService>().fetchOrders(context.read<AuthService>(), refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<OrdersService>();
    final list = _filtered(svc.orders);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'سفارشات',
          subtitle: 'مدیریت سفارش‌های فروشگاه',
          leadingIcon: Icons.shopping_cart_rounded,
          leadingColor: AppColors.blue,
          onRefresh: () => svc.fetchOrders(auth, refresh: true),
        ),
        // جستجو فرورفته
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1230),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2A55)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.textMute, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'جستجو در سفارشات...',
                    hintStyle: TextStyle(color: AppColors.textMute, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.textMute, size: 20),
                onPressed: () {},
              ),
            ]),
          ),
        ),
        // چیپ فیلتر
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            children: [
              _chip('همه', 'all', AppColors.purple),
              _chip('در حال پردازش', 'processing', AppColors.blue),
              _chip('تکمیل شده', 'completed', AppColors.green),
              _chip('لغو شده', 'cancelled', AppColors.red),
            ],
          ),
        ),
        Expanded(
          child: svc.loading && svc.orders.isEmpty
              ? const Center(child: MiniLoader())
              : svc.error != null && svc.orders.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(svc.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                        TextButton(onPressed: () => svc.fetchOrders(auth, refresh: true), child: const Text('تلاش مجدد')),
                      ]),
                    )
                  : list.isEmpty
                      ? const Center(child: Text('سفارشی یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          backgroundColor: AppColors.card,
                          onRefresh: () => svc.fetchOrders(auth, refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                            itemCount: list.length + (svc.hasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i >= list.length) {
                                svc.fetchOrders(auth);
                                return const Padding(padding: EdgeInsets.all(16), child: Center(child: MiniLoader(size: 22)));
                              }
                              final o = list[i];
                              final id = o['number'] ?? o['id'] ?? '—';
                              final status = o['status']?.toString();
                              final sc = _statusColor(status);
                              final sl = o['status_label']?.toString().isNotEmpty == true
                                  ? o['status_label'].toString()
                                  : _statusLabel(status);
                              final total = _fmt(o['total'] ?? o['total_formatted']);
                              final date = _date(o);
                              final name = _customerName(o);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  onTap: () => _openOrder(o),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // در RTL اولی سمت راست می‌آید = آیکون
                                      SoftIconBox(icon: Icons.inventory_2_outlined, color: AppColors.blue, size: 48),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(name.isNotEmpty ? name : 'مشتری', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text('جزئیات در صفحه سفارش', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                          const SizedBox(height: 6),
                                          Text(date, style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Text('$total تومان', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                        ]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: sc.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: sc.withOpacity(0.4)),
                                        ),
                                        child: Text(sl, style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String val, Color c) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => filter = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: sel
                ? LinearGradient(colors: [c, c.withOpacity(0.75)])
                : null,
            color: sel ? null : const Color(0xFF0B1230),
            border: Border.all(color: sel ? c.withOpacity(0.5) : const Color(0xFF1E2A55)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : AppColors.textDim,
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
