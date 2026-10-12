import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  final VoidCallback? onAddProduct;
  final VoidCallback? onContacts;
  const DashboardScreen({super.key, this.onNavigate, this.onAddProduct, this.onContacts});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List _announces = [];
  List _recentOrders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().fetchStats(context.read<AuthService>());
      _loadExtra();
    });
  }

  Future<void> _loadExtra() async {
    final api = context.read<AuthService>().api;
    try {
      final a = await api.dio.get('announcements/active', queryParameters: {'place': 'app'});
      if (a.data is Map && a.data['items'] is List && mounted) {
        setState(() => _announces = a.data['items'] as List);
      }
    } catch (_) {}
    try {
      final o = await api.dio.get('orders', queryParameters: {'per_page': 5, 'page': 1});
      if (o.data is Map && o.data['orders'] is List && mounted) {
        setState(() => _recentOrders = o.data['orders'] as List);
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه من';
    final stats = dash.stats;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          await dash.fetchStats(auth);
          await _loadExtra();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            GlassHeader(
              title: siteName,
              subtitle: 'مدیریت فروشگاه ووکامرس',
              leadingIcon: Icons.storefront_rounded,
              leadingColor: AppColors.purple,
              onRefresh: dash.loading
                  ? null
                  : () async {
                      await dash.fetchStats(auth);
                      await _loadExtra();
                    },
            ),
            // عنوان آمار
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: AppColors.blue, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('آمار کلی فروشگاه', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
            // شبکه ۲×۲ آمار — مثل مرجع
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: _statCard(
                      Icons.shopping_cart_outlined,
                      AppColors.blue,
                      'سفارشات امروز',
                      _fmt(stats['today_orders']),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      Icons.payments_outlined,
                      AppColors.green,
                      'درآمد امروز',
                      _fmt(stats['today_sales']),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _statCard(
                      Icons.inventory_2_outlined,
                      AppColors.cyan,
                      'محصولات',
                      _fmt(stats['total_products']),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      Icons.people_outline_rounded,
                      AppColors.purple,
                      'مشتریان',
                      _fmt(stats['total_customers'] ?? stats['customers']),
                    ),
                  ),
                ]),
              ]),
            ),
            // اطلاعیه
            if (_announces.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._announces.take(2).map((a) {
                final m = Map<String, dynamic>.from(a as Map);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: NeonCard(
                    borderColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      SoftIconBox(icon: Icons.campaign_rounded, color: AppColors.cyan, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          if ((m['body']?.toString() ?? '').isNotEmpty)
                            Text(m['body'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                        ]),
                      ),
                    ]),
                  ),
                );
              }),
            ],
            // دسترسی سریع
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.orange, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('دسترسی سریع', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Expanded(child: _quick(Icons.phone_in_talk_rounded, 'تماس‌ها', AppColors.blue, () => widget.onContacts?.call())),
                const SizedBox(width: 10),
                Expanded(child: _quick(Icons.add_box_rounded, 'افزودن محصول', AppColors.purple, () => widget.onAddProduct?.call())),
                const SizedBox(width: 10),
                Expanded(child: _quick(Icons.receipt_long_rounded, 'سفارشات', AppColors.cyan, () => widget.onNavigate?.call(1))),
              ]),
            ),
            // آخرین سفارشات
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.purpleGlow, size: 16),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('آخرین سفارشات', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14))),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(1),
                  child: const Text('همه', style: TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
                ),
              ]),
            ),
            if (_recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('سفارشی نیست', style: TextStyle(color: AppColors.textDim))),
              )
            else
              ..._recentOrders.take(5).map((o) {
                final m = Map<String, dynamic>.from(o as Map);
                final status = (m['status_label'] ?? m['status'] ?? '').toString();
                final num = m['number'] ?? m['id'];
                final total = _fmt(m['total']);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: NeonCard(
                    onTap: () => widget.onNavigate?.call(1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(children: [
                      SoftIconBox(icon: Icons.shopping_bag_outlined, color: AppColors.blue, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#$num', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(status, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                        ]),
                      ),
                      Text('$total', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                );
              }),
            if (dash.loading && stats.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: MiniLoader())),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, Color color, String label, String value) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SoftIconBox(icon: icon, color: color, size: 36),
          const Spacer(),
        ]),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
      ]),
    );
  }

  Widget _quick(IconData icon, String title, Color color, VoidCallback onTap) {
    return NeonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        SoftIconBox(icon: icon, color: color, size: 42),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}
