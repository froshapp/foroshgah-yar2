import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';

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

  String _jalaliToday() {
    final j = Jalali.now();
    const months = ['', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
    const days = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
    // shamsi_date weekDay: 1=Sat ... 7=Fri in some versions; use DateTime for weekday
    final wd = DateTime.now().weekday; // 1=Mon..7=Sun
    final map = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 0}; // to index of days starting Sat
    // simpler: just date
    return '${j.day} ${months[j.month]} ${j.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final manager = auth.user?['display_name']?.toString() ?? '';
    final stats = dash.stats;

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        onRefresh: () => dash.fetchStats(auth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(siteName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(manager.isNotEmpty ? 'مدیر: $manager' : '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_jalaliToday(), style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                  ]),
                ),
                if (dash.loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
                  )
                else
                  IconButton(icon: const Icon(Icons.refresh, color: Colors.white38, size: 22), onPressed: () => dash.fetchStats(auth)),
              ],
            ),
            const SizedBox(height: 18),
            if (dash.loading && stats['total_orders'] == 0)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF)))),
              )
            else ...[
              Row(children: [
                Expanded(child: _stat('فروش امروز', _fmt(stats['today_sales']), const Color(0xFF10B981))),
                const SizedBox(width: 10),
                Expanded(child: _stat('سفارش امروز', _fmt(stats['today_orders']), const Color(0xFF6C63FF))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _stat('کل سفارشات', _fmt(stats['total_orders']), const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
                Expanded(child: _stat('محصولات', _fmt(stats['total_products']), const Color(0xFF3B82F6))),
              ]),
              const SizedBox(height: 22),
              const Text('دسترسی سریع', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _quick(Icons.receipt_long_rounded, 'سفارشات', const Color(0xFF6C63FF), () => widget.onNavigate?.call(1)),
              const SizedBox(height: 8),
              _quick(Icons.add_box_outlined, 'افزودن محصول', const Color(0xFF10B981), () => widget.onAddProduct?.call()),
              const SizedBox(height: 8),
              _quick(Icons.phone_in_talk_outlined, 'تماس‌ها', const Color(0xFF3B82F6), () => widget.onContacts?.call()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252640),
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: color, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _quick(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF252640),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
            const Icon(Icons.chevron_left, color: Colors.white24, size: 20),
          ]),
        ),
      ),
    );
  }
}
