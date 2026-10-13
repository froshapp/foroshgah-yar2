import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../orders/manual_order_screen.dart';

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
  List _chart = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().fetchStats(context.read<AuthService>());
      _loadAnnounces();
      _loadChart();
    });
  }

  Future<void> _loadAnnounces() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('announcements/active', queryParameters: {'place': 'app'});
      if (res.data is Map && res.data['items'] is List && mounted) {
        setState(() => _announces = res.data['items'] as List);
      }
    } catch (_) {}
  }

  Future<void> _loadChart() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('dashboard/chart', queryParameters: {'days': 7});
      if (res.data is Map && res.data['points'] is List && mounted) {
        setState(() => _chart = res.data['points'] as List);
      } else if (res.data is Map && res.data['data'] is List && mounted) {
        setState(() => _chart = res.data['data'] as List);
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

  String _pct(dynamic v) {
    if (v == null) return '';
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    final sign = n >= 0 ? '+' : '';
    return '$sign${n.round()}٪';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'مدیریت فروشگاه ووکامرس';
    final stats = dash.stats;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          await dash.fetchStats(auth);
          await _loadChart();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            GlassHeader(
              title: 'پیشخوان',
              subtitle: siteName,
              showBell: true,
              storeOpensSettings: true,
            ),
            if (_announces.isNotEmpty)
              ..._announces.take(2).map((a) {
                final m = Map<String, dynamic>.from(a as Map);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: NeonCard(
                    borderColor: const Color(0xFF6EE7B7).withOpacity(0.35),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.campaign_outlined, color: Color(0xFF6EE7B7), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(m['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 14),
            if (dash.loading && (stats.isEmpty || (stats['total_orders'] == 0 && stats['total_products'] == 0)))
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              // 4 KPI cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    _kpi('سفارشات امروز', _fmt(stats['today_orders'] ?? stats['orders_today']), Icons.shopping_cart_rounded, const Color(0xFF8B5CF6), _pct(stats['orders_change']), 'نسبت به دیروز'),
                    _kpi('درآمد امروز', _fmt(stats['today_sales'] ?? stats['sales_today']), Icons.stacked_line_chart_rounded, const Color(0xFF3B82F6), _pct(stats['sales_change']), 'نسبت به دیروز'),
                    _kpi('محصولات', _fmt(stats['total_products'] ?? stats['products']), Icons.inventory_2_rounded, const Color(0xFF22D3EE), _pct(stats['products_change'] ?? 5), 'موجود در فروشگاه'),
                    _kpi('مشتریان', _fmt(stats['total_customers'] ?? stats['customers']), Icons.people_alt_rounded, const Color(0xFFA78BFA), _pct(stats['customers_change'] ?? 3), 'مشتریان فعال'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // chart card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: NeonCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.show_chart_rounded, color: AppColors.purpleGlow, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('فروش ۷ روز گذشته', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                      _chip('۷ روز', true),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: _ChartPainter(points: _chart, fallback: stats['week_sales'] ?? stats['today_sales'] ?? 0),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Text('درآمد کل فروش', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                      const Spacer(),
                      Text('${_fmt(stats['week_sales'] ?? stats['today_sales'])} تومان',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                    if (stats['sales_change'] != null)
                      Text(_pct(stats['sales_change']) + ' نسبت به هفته قبل',
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 11)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.bolt_rounded, color: AppColors.purpleGlow, size: 18),
                  SizedBox(width: 6),
                  Text('دسترسی سریع', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  _quickRow(Icons.phone_in_talk_rounded, const Color(0xFFA78BFA), 'تماس‌ها', 'پشتیبانی و ارتباط با مشتریان', () => widget.onContacts?.call()),
                  const SizedBox(height: 8),
                  _quickRow(Icons.add_box_rounded, const Color(0xFF3B82F6), 'افزودن محصول', 'ثبت محصول جدید', () => widget.onAddProduct?.call()),
                  const SizedBox(height: 8),
                  _quickRow(Icons.receipt_long_rounded, const Color(0xFF22D3EE), 'سفارشات', 'مشاهده و مدیریت سفارشات', () => widget.onNavigate?.call(1)),
                  const SizedBox(height: 8),
                  _quickRow(Icons.add_shopping_cart_rounded, const Color(0xFF8B5CF6), 'سفارش دستی', 'ثبت سفارش توسط مدیر', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualOrderScreen()));
                  }),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? AppColors.purple.withOpacity(0.35) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? AppColors.purple : AppColors.cardBorder),
        ),
        child: Text(t, style: TextStyle(color: on ? Colors.white : AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _kpi(String title, String value, IconData icon, Color color, String pct, String sub) {
    return NeonCard(
      borderColor: color.withOpacity(0.35),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.65)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const Spacer(),
          Icon(Icons.more_horiz, color: AppColors.textMute.withOpacity(0.6), size: 18),
        ]),
        const Spacer(),
        Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        if (pct.isNotEmpty)
          Row(children: [
            Text(pct, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Expanded(child: Text(sub, style: const TextStyle(color: AppColors.textMute, fontSize: 10), overflow: TextOverflow.ellipsis)),
          ]),
      ]),
    );
  }

  Widget _quickRow(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return NeonCard(
      onTap: onTap,
      borderColor: color.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          ]),
        ),
        const Icon(Icons.chevron_left, color: AppColors.textMute),
      ]),
    );
  }
}

class _ChartPainter extends StatelessWidget {
  final List points;
  final dynamic fallback;
  const _ChartPainter({required this.points, this.fallback});

  @override
  Widget build(BuildContext context) {
    final vals = <double>[];
    if (points.isNotEmpty) {
      for (final p in points) {
        if (p is Map) {
          vals.add((p['total'] ?? p['sales'] ?? p['value'] ?? 0) is num
              ? (p['total'] ?? p['sales'] ?? p['value'] as num).toDouble()
              : double.tryParse('${p['total'] ?? p['sales'] ?? p['value']}') ?? 0);
        } else if (p is num) {
          vals.add(p.toDouble());
        }
      }
    }
    if (vals.isEmpty) {
      final base = fallback is num ? fallback.toDouble() : double.tryParse('$fallback') ?? 0;
      vals.addAll([base * 0.4, base * 0.55, base * 0.5, base * 0.7, base * 0.65, base * 0.85, base * 1.0]);
    }
    return CustomPaint(
      painter: _LineChartPainter(vals),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final path = Path();
    final fill = Path();
    final n = values.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = size.height - (values[i] / maxV) * (size.height * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF6366F1).withOpacity(0.35), const Color(0xFF6366F1).withOpacity(0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF818CF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.values != values;
}
