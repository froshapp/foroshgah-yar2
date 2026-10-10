import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  final VoidCallback? onAddProduct;
  const DashboardScreen({super.key, this.onNavigate, this.onAddProduct});

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final stats = dash.stats;

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        onRefresh: () => dash.fetchStats(auth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(siteName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('سلام ${auth.user?['display_name'] ?? ''}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: dash.loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                      : const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: dash.loading ? null : () => dash.fetchStats(auth),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (dash.loading && (stats['total_orders'] == 0 && stats['total_products'] == 0))
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF)))),
              )
            else ...[
              Row(
                children: [
                  Expanded(child: _stat('فروش امروز', _fmt(stats['today_sales']), Icons.payments_outlined, const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: _stat('سفارش امروز', _fmt(stats['today_orders']), Icons.receipt_outlined, const Color(0xFF6C63FF))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _stat('کل سفارشات', _fmt(stats['total_orders']), Icons.shopping_bag_outlined, const Color(0xFFF59E0B))),
                  const SizedBox(width: 12),
                  Expanded(child: _stat('محصولات', _fmt(stats['total_products']), Icons.inventory_2_outlined, const Color(0xFF3B82F6))),
                ],
              ),
              if (dash.error != null) ...[
                const SizedBox(height: 12),
                Text(dash.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              const Text('دسترسی سریع', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _quick(Icons.receipt_long, 'مدیریت سفارشات', 'مشاهده آدرس و تغییر وضعیت', const Color(0xFF6C63FF),
                  () => widget.onNavigate?.call(1)),
              const SizedBox(height: 10),
              _quick(Icons.add_box_outlined, 'افزودن محصول', 'محصول جدید با فرم ساده', const Color(0xFF10B981),
                  () => widget.onAddProduct?.call()),
              const SizedBox(height: 10),
              _quick(Icons.inventory_2, 'لیست محصولات', 'ویرایش قیمت و موجودی', const Color(0xFF3B82F6),
                  () => widget.onNavigate?.call(2)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _quick(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF252640),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
