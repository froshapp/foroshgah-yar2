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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().fetchStats(context.read<AuthService>());
    });
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = v is num ? v.round() : int.tryParse(v.toString()) ?? 0;
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _jalali() {
    final j = Jalali.now();
    const months = ['', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
    return 'امروز - ${j.day} ${months[j.month]} ${j.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه من';
    final manager = auth.user?['display_name']?.toString() ?? '';
    final stats = dash.stats;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: () => dash.fetchStats(auth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GlassHeader(
              title: siteName,
              subtitle: manager.isEmpty ? null : manager,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                  tooltip: 'سفارشات',
                  onPressed: () => widget.onNavigate?.call(1),
                ),
                if (dash.loading)
                  const Padding(padding: EdgeInsets.all(8), child: MiniLoader(size: 18)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: NeonCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.purpleGlow, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_jalali(), style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            if (dash.loading && (stats['total_orders'] == 0 && stats['total_products'] == 0))
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _stat('فروش امروز', _fmt(stats['today_sales']), Icons.trending_up_rounded, AppColors.cyan)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('سفارش امروز', _fmt(stats['today_orders']), Icons.shopping_cart_outlined, AppColors.purple)),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _stat('کل سفارشات', _fmt(stats['total_orders']), Icons.groups_outlined, AppColors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('موجودی کالا', _fmt(stats['total_products']), Icons.inventory_2_outlined, AppColors.blue)),
                ]),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.bolt_rounded, color: AppColors.purpleGlow, size: 18),
                  SizedBox(width: 6),
                  Text('دسترسی سریع', style: TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _quick(Icons.receipt_long_rounded, 'سفارشات', AppColors.purple, () => widget.onNavigate?.call(1))),
                  const SizedBox(width: 10),
                  Expanded(child: _quick(Icons.add_circle_rounded, 'افزودن محصول', AppColors.cyan, () => widget.onAddProduct?.call())),
                  const SizedBox(width: 10),
                  Expanded(child: _quick(Icons.phone_in_talk_rounded, 'تماس‌ها', AppColors.blue, () => widget.onContacts?.call())),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return NeonCard(
      borderColor: color.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
        ]),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      ]),
    );
  }

  Widget _quick(IconData icon, String title, Color color, VoidCallback onTap) {
    return NeonCard(
      onTap: onTap,
      borderColor: color.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: SizedBox(
        height: 84,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
