import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final siteName = auth.site?['name']?.toString() ?? 'مدیریت فروشگاه ووکامرس';
    final stats = dash.stats;
    final daily = dash.dailySales;
    final weekTotal = daily.fold<double>(0, (a, e) {
      if (e is Map) {
        final v = e['total'] ?? e['sales'] ?? e['value'] ?? 0;
        return a + ((v is num) ? v.toDouble() : double.tryParse('$v') ?? 0);
      }
      return a;
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: () => dash.fetchStats(auth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            GlassHeader(
              title: 'پیشخوان',
              subtitle: siteName.isNotEmpty ? siteName : 'مدیریت فروشگاه ووکامرس',
              leadingIcon: Icons.storefront_rounded,
              leadingColor: AppColors.purple,
            ),
            if (dash.loading && stats['today_orders'] == 0 && stats['total_products'] == 0)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              const SizedBox(height: 12),
              // ۴ کارت آمار — ۲×۲ کنار هم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _kpi(
                      Icons.shopping_cart_rounded, const Color(0xFF8B5CF6),
                      'سفارشات امروز', _fmt(stats['today_orders']), '+٪۱۲',
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _kpi(
                      Icons.layers_rounded, const Color(0xFF3B82F6),
                      'درآمد امروز', _fmt(stats['today_sales']), '+٪۱۸',
                    )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _kpi(
                      Icons.inventory_2_rounded, const Color(0xFF22D3EE),
                      'محصولات', _fmt(stats['total_products']), '+٪۵',
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _kpi(
                      Icons.people_alt_rounded, const Color(0xFFA78BFA),
                      'مشتریان', _fmt(stats['total_customers']), '+٪۳',
                    )),
                  ]),
                ]),
              ),

              const SizedBox(height: 14),

              // فروش ۷ روز — فشرده برای موبایل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: NeonCard(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  borderColor: AppColors.purple.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        SoftIconBox(icon: Icons.show_chart_rounded, color: AppColors.purple, size: 32),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('فروش ۷ روز گذشته',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        _chip('۷ روز', true),
                        const SizedBox(width: 4),
                        _chip('۳۰', false),
                        const SizedBox(width: 4),
                        _chip('۹۰', false),
                      ]),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 100,
                              child: _SalesChart(daily: daily, fallback: stats['today_sales']),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(children: [
                              SizedBox(
                                width: 64, height: 64,
                                child: Stack(alignment: Alignment.center, children: [
                                  SizedBox(
                                    width: 64, height: 64,
                                    child: CircularProgressIndicator(
                                      value: 0.72, strokeWidth: 6,
                                      backgroundColor: const Color(0xFF1E2A55),
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(colors: [Color(0xFF2868FF), Color(0xFF7047F5)]),
                                      boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.45), blurRadius: 8)],
                                    ),
                                    child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 8),
                              const Text('درآمد کل فروش', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                              Text(
                                _fmt(weekTotal > 0 ? weekTotal : stats['today_sales']),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 9)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // دسترسی سریع — ۳ کنار هم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  SoftIconBox(icon: Icons.bolt_rounded, color: AppColors.purple, size: 28),
                  const SizedBox(width: 8),
                  const Text('دسترسی سریع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Expanded(child: _quick(
                    Icons.phone_in_talk_rounded, const Color(0xFFA78BFA),
                    'تماس‌ها', 'پشتیبانی', () => widget.onContacts?.call(),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _quick(
                    Icons.add_rounded, const Color(0xFF3B82F6),
                    'افزودن محصول', 'محصول جدید', () => widget.onAddProduct?.call(),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _quick(
                    Icons.receipt_long_rounded, const Color(0xFF22D3EE),
                    'سفارشات', 'مدیریت', () => widget.onNavigate?.call(1),
                  )),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: on ? const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]) : null,
        color: on ? null : const Color(0xFF0B1230),
        border: Border.all(color: on ? AppColors.purple.withOpacity(0.5) : const Color(0xFF1E2A55)),
        boxShadow: on ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
      ),
      child: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _kpi(IconData icon, Color color, String title, String value, String pct) {
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A2858), Color(0xFF121E42), Color(0xFF0C1530)],
        ),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 8)),
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SoftIconBox(icon: icon, color: color, size: 32),
          const Spacer(),
          Icon(Icons.more_horiz, color: AppColors.textMute.withOpacity(0.6), size: 16),
        ]),
        const Spacer(),
        Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(pct, style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _quick(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A2858), Color(0xFF121E42), Color(0xFF0C1530)],
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 7)),
              BoxShadow(color: color.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
            ],
          ),
          child: Column(children: [
            SoftIconBox(icon: icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 2),
            Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMute, fontSize: 9)),
          ]),
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List daily;
  final dynamic fallback;
  const _SalesChart({required this.daily, this.fallback});

  @override
  Widget build(BuildContext context) {
    final vals = <double>[];
    for (final p in daily) {
      if (p is Map) {
        final v = p['total'] ?? p['sales'] ?? p['value'] ?? 0;
        vals.add(v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
      }
    }
    if (vals.isEmpty) {
      final base = fallback is num ? fallback.toDouble() : double.tryParse('$fallback') ?? 1000;
      vals.addAll([base * 0.35, base * 0.5, base * 0.42, base * 0.65, base * 0.58, base * 0.8, base * 1.0]);
    }
    return CustomPaint(painter: _ChartPainter(vals), size: Size.infinite);
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  _ChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0) return;
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final n = values.length;
    final path = Path();
    final fill = Path();
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = size.height - (values[i] / maxV) * (size.height * 0.82) - 4;
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
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [const Color(0xFF6366F1).withOpacity(0.4), const Color(0xFF6366F1).withOpacity(0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF818CF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final lx = n == 1 ? size.width / 2 : size.width;
    final ly = size.height - (values.last / maxV) * (size.height * 0.82) - 4;
    canvas.drawCircle(Offset(lx, ly), 4.5, Paint()..color = const Color(0xFFA78BFA));
    canvas.drawCircle(Offset(lx, ly), 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.values != values;
}
