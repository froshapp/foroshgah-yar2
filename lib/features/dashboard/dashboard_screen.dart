import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';

/// پیشخوان دقیقاً مطابق موکاپ:
/// هدر «پیشخوان» | ۴ کارت افقی | نمودار فروش ۷روز + حلقه | دسترسی سریع ۳ردیفی
class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  final VoidCallback? onAddProduct;
  final VoidCallback? onContacts;
  const DashboardScreen({super.key, this.onNavigate, this.onAddProduct, this.onContacts});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _rangeDays = 7;
  List _recentOrders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().fetchStats(context.read<AuthService>());
      _loadRecent();
    });
  }

  Future<void> _loadRecent() async {
    try {
      final o = await context.read<AuthService>().api.dio.get('orders', queryParameters: {'per_page': 3, 'page': 1});
      if (o.data is Map && o.data['orders'] is List && mounted) {
        setState(() => _recentOrders = o.data['orders'] as List);
      }
    } catch (_) {}
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = v is num ? v.round() : int.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return (n < 0 ? '-' : '') + buf.toString();
  }

  String _fmtShort(dynamic v) {
    final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return _fmt(n.round());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final stats = dash.stats;
    final daily = dash.dailySales;
    final weekTotal = daily.fold<double>(0, (a, e) {
      if (e is Map) {
        final v = e['total'] ?? e['sales'] ?? e['value'] ?? 0;
        return a + ((v is num) ? v.toDouble() : double.tryParse('$v') ?? 0);
      }
      return a;
    });
    final displayTotal = weekTotal > 0
        ? weekTotal
        : (stats['today_sales'] is num ? (stats['today_sales'] as num).toDouble() : 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          await dash.fetchStats(auth);
          await _loadRecent();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            // ─── هدر: عنوان «پیشخوان» ───
            GlassHeader(
              title: 'پیشخوان',
              subtitle: 'مدیریت فروشگاه ووکامرس',
              leadingIcon: Icons.storefront_rounded,
              leadingColor: AppColors.purple,
            ),

            if (dash.loading && stats['total_products'] == 0)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              const SizedBox(height: 8),

              // ─── ۴ کارت آمار در یک ردیف ───
              SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _kpi(
                      icon: Icons.shopping_cart_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'سفارشات امروز',
                      value: _fmt(stats['today_orders']),
                      pct: '٪۱۲+',
                      sub: 'نسبت به دیروز',
                    ),
                    _kpi(
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'درآمد امروز',
                      value: _fmt(stats['today_sales']),
                      pct: '٪۱۸+',
                      sub: 'نسبت به دیروز',
                    ),
                    _kpi(
                      icon: Icons.view_in_ar_rounded,
                      color: const Color(0xFF22D3EE),
                      title: 'محصولات',
                      value: _fmt(stats['total_products']),
                      pct: '٪۵+',
                      sub: 'موجود در فروشگاه',
                    ),
                    _kpi(
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFFA78BFA),
                      title: 'مشتریان',
                      value: _fmt(stats['total_customers']),
                      pct: '٪۳+',
                      sub: 'مشتریان فعال',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── فروش ۷ روز گذشته + حلقه درآمد ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: _cardDeco(AppColors.purple.withOpacity(0.3)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SoftIconBox(icon: Icons.area_chart_rounded, color: AppColors.purple, size: 30),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'فروش ۷ روز گذشته',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          _chip('۷ روز', 7),
                          const SizedBox(width: 4),
                          _chip('۳۰', 30),
                          const SizedBox(width: 4),
                          _chip('۹۰', 90),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 148,
                        child: Row(
                          children: [
                            // حلقه سمت راست در RTL = اول
                            SizedBox(
                              width: 108,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: CircularProgressIndicator(
                                            value: 0.72,
                                            strokeWidth: 7,
                                            backgroundColor: const Color(0xFF1A2748),
                                            color: AppColors.cyan,
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF2868FF), Color(0xFF7047F5)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(color: AppColors.purple.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 3)),
                                            ],
                                          ),
                                          child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('درآمد کل فروش', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                  Text(_fmt(displayTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                  const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 9)),
                                  const SizedBox(height: 2),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFF34D399)),
                                      Text('٪۱۸+', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const Text('نسبت به هفته قبل', style: TextStyle(color: AppColors.textMute, fontSize: 8)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: _SalesChart(daily: daily, fallback: stats['today_sales'], fmtShort: _fmtShort)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── دسترسی سریع — سه ردیف افقی با زیرعنوان ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    SoftIconBox(icon: Icons.bolt_rounded, color: AppColors.purple, size: 26),
                    const SizedBox(width: 8),
                    const Text('دسترسی سریع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _quick(
                      Icons.phone_in_talk_rounded,
                      const Color(0xFFA78BFA),
                      'تماس‌ها',
                      'پشتیبانی و ارتباط با مشتریان',
                      () => widget.onContacts?.call(),
                    ),
                    const SizedBox(height: 8),
                    _quick(
                      Icons.add_rounded,
                      const Color(0xFF3B82F6),
                      'افزودن محصول',
                      'ثبت محصول جدید',
                      () => widget.onAddProduct?.call(),
                    ),
                    const SizedBox(height: 8),
                    _quick(
                      Icons.receipt_long_rounded,
                      const Color(0xFF22D3EE),
                      'سفارشات',
                      'مشاهده و مدیریت سفارشات',
                      () => widget.onNavigate?.call(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── فعالیت اخیر ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onNavigate?.call(1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: _cardDeco(const Color(0xFF2A3A6A)),
                      child: Row(
                        children: [
                          SoftIconBox(icon: Icons.schedule_rounded, color: AppColors.blue, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _recentOrders.isEmpty
                                  ? 'آخرین بروزرسانی: همین الان'
                                  : 'آخرین بروزرسانی: ${_recentOrders.length} سفارش اخیر',
                              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                            ),
                          ),
                          Text(
                            '${_recentOrders.isEmpty ? 0 : _recentOrders.length} فعالیت اخیر',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const Icon(Icons.chevron_left_rounded, color: AppColors.textMute, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco(Color border) => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2858), Color(0xFF121E42), Color(0xFF0C1530)],
        ),
        border: Border.all(color: border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 18, offset: const Offset(0, 9)),
          BoxShadow(color: border.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      );

  Widget _chip(String label, int days) {
    final on = _rangeDays == days;
    return GestureDetector(
      onTap: () => setState(() => _rangeDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: on ? const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]) : null,
          color: on ? null : const Color(0xFF0B1230),
          border: Border.all(color: on ? AppColors.purple.withOpacity(0.55) : const Color(0xFF1E2A55)),
        ),
        child: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _kpi({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String pct,
    required String sub,
  }) {
    return Container(
      width: 152,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: _cardDeco(color.withOpacity(0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIconBox(icon: icon, color: color, size: 32),
              const Spacer(),
              Icon(Icons.more_horiz, color: AppColors.textMute.withOpacity(0.7), size: 16),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFF34D399)),
              Text(pct, style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMute, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quick(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: _cardDeco(color.withOpacity(0.28)),
          child: Row(
            children: [
              SoftIconBox(icon: icon, color: color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: AppColors.textMute.withOpacity(0.85), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List daily;
  final dynamic fallback;
  final String Function(dynamic) fmtShort;
  const _SalesChart({required this.daily, this.fallback, required this.fmtShort});

  @override
  Widget build(BuildContext context) {
    final vals = <double>[];
    final labels = <String>[];
    for (final p in daily) {
      if (p is Map) {
        final v = p['total'] ?? p['sales'] ?? p['value'] ?? 0;
        vals.add(v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
        final d = p['date']?.toString() ?? p['day']?.toString() ?? p['label']?.toString() ?? '';
        labels.add(d.length >= 5 ? d.substring(d.length - 5) : d);
      }
    }
    if (vals.isEmpty) {
      final base = fallback is num ? (fallback as num).toDouble() : double.tryParse('$fallback') ?? 800000;
      final factors = [0.28, 0.48, 0.38, 0.62, 0.55, 0.78, 1.0];
      for (final f in factors) {
        vals.add(base * f);
      }
      labels.addAll(['۱۵', '۱۶', '۱۷', '۱۸', '۱۹', '۲۰', '۲۱']);
    }
    while (labels.length < vals.length) {
      labels.add('${labels.length + 1}');
    }
    return CustomPaint(
      painter: _ChartPainter(vals, labels, fmtShort(vals.isNotEmpty ? vals.last : 0)),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final String lastLabel;
  _ChartPainter(this.values, this.labels, this.lastLabel);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final maxV = values.reduce(math.max).clamp(1.0, double.infinity);
    final n = values.length;
    final chartH = size.height - 18;
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = chartH - (values[i] / maxV) * (chartH * 0.82) - 8;
      points.add(Offset(x, y));
    }

    final path = Path();
    final fill = Path();
    path.moveTo(points.first.dx, points.first.dy);
    fill.moveTo(points.first.dx, chartH);
    fill.lineTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      fill.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    fill.lineTo(points.last.dx, chartH);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF6366F1).withOpacity(0.45), const Color(0xFF6366F1).withOpacity(0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF818CF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 5.5, Paint()..color = const Color(0xFFA78BFA));
    canvas.drawCircle(last, 2.8, Paint()..color = Colors.white);

    final tp = TextPainter(
      text: TextSpan(text: lastLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    final bw = tp.width + 12;
    final bh = tp.height + 8;
    var bx = last.dx - bw / 2;
    var by = last.dy - bh - 10;
    if (bx < 0) bx = 0;
    if (bx + bw > size.width) bx = size.width - bw;
    if (by < 0) by = last.dy + 10;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E2A55).withOpacity(0.95));
    tp.paint(canvas, Offset(bx + 6, by + 4));

    for (var i = 0; i < labels.length && i < points.length; i++) {
      final lp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: Color(0xFF6B7A9E), fontSize: 8)),
        textDirection: TextDirection.rtl,
      )..layout();
      final lx = points[i].dx - lp.width / 2;
      lp.paint(canvas, Offset(lx.clamp(0, size.width - lp.width), chartH + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values != values || old.labels != labels || old.lastLabel != lastLabel;
}
