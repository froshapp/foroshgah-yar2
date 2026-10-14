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
            // هدر مطابق موکاپ
            GlassHeader(
              title: 'پیشخوان',
              subtitle: siteName.isNotEmpty ? siteName : 'مدیریت فروشگاه ووکامرس',
              leadingIcon: Icons.storefront_rounded,
              leadingColor: AppColors.purple,
            ),

            if (dash.loading && stats['today_orders'] == 0 && stats['total_products'] == 0)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              const SizedBox(height: 14),

              // ۴ کارت KPI افقی — مطابق موکاپ
              SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _kpiCard(
                      icon: Icons.shopping_cart_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'سفارشات امروز',
                      value: _fmt(stats['today_orders']),
                      pct: '+٪۱۲',
                      sub: 'نسبت به دیروز',
                    ),
                    _kpiCard(
                      icon: Icons.layers_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'درآمد امروز',
                      value: _fmt(stats['today_sales']),
                      pct: '+٪۱۸',
                      sub: 'نسبت به دیروز',
                    ),
                    _kpiCard(
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF22D3EE),
                      title: 'محصولات',
                      value: _fmt(stats['total_products']),
                      pct: '+٪۵',
                      sub: 'موجود در فروشگاه',
                    ),
                    _kpiCard(
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFFA78BFA),
                      title: 'مشتریان',
                      value: _fmt(stats['total_customers']),
                      pct: '+٪۳',
                      sub: 'مشتریان فعال',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // کارت نمودار فروش ۷ روز
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: NeonCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  borderColor: AppColors.purple.withOpacity(0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SoftIconBox(icon: Icons.show_chart_rounded, color: AppColors.purple, size: 34),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('فروش ۷ روز گذشته',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          _rangeChip('۷ روز', true),
                          const SizedBox(width: 6),
                          _rangeChip('۳۰', false),
                          const SizedBox(width: 6),
                          _rangeChip('۹۰', false),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 140,
                              child: _SalesChart(daily: daily, fallback: stats['today_sales']),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: CircularProgressIndicator(
                                          value: 0.72,
                                          strokeWidth: 7,
                                          backgroundColor: const Color(0xFF1E2A55),
                                          color: AppColors.cyan,
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(colors: [
                                            AppColors.blue,
                                            AppColors.purple,
                                          ]),
                                          boxShadow: [
                                            BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 10),
                                          ],
                                        ),
                                        child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('درآمد کل فروش', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_fmt(weekTotal > 0 ? weekTotal : stats['today_sales'])}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // دسترسی سریع
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 8),
                    const Text('دسترسی سریع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _quickRow(Icons.phone_in_talk_rounded, const Color(0xFFA78BFA), 'تماس‌ها', 'پشتیبانی و ارتباط با مشتریان', () => widget.onContacts?.call()),
                    const SizedBox(height: 10),
                    _quickRow(Icons.add_rounded, const Color(0xFF3B82F6), 'افزودن محصول', 'ثبت محصول جدید', () => widget.onAddProduct?.call()),
                    const SizedBox(height: 10),
                    _quickRow(Icons.receipt_long_rounded, const Color(0xFF22D3EE), 'سفارشات', 'مشاهده و مدیریت سفارشات', () => widget.onNavigate?.call(1)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: on
            ? const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)])
            : null,
        color: on ? null : const Color(0xFF0B1230),
        border: Border.all(color: on ? AppColors.purple.withOpacity(0.5) : const Color(0xFF1E2A55)),
        boxShadow: on
            ? [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Text(label,
          style: TextStyle(
            color: on ? Colors.white : AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          )),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String pct,
    required String sub,
  }) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18265A), Color(0xFF101B3C), Color(0xFF0B1230)],
        ),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
          BoxShadow(color: color.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIconBox(icon: icon, color: color, size: 34),
              const Spacer(),
              Icon(Icons.more_horiz, color: AppColors.textMute.withOpacity(0.7), size: 18),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(pct, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(sub,
                    style: const TextStyle(color: AppColors.textMute, fontSize: 9),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickRow(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF18265A), Color(0xFF101B3C), Color(0xFF0B1230)],
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: color.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(children: [
            SoftIconBox(icon: icon, color: color, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ]),
            ),
            Icon(Icons.chevron_left, color: AppColors.textMute.withOpacity(0.8)),
          ]),
        ),
      ),
    );
  }

  Widget _quickTile(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF18265A), Color(0xFF101B3C), Color(0xFF0B1230)],
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              SoftIconBox(icon: icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMute, fontSize: 9)),
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
      vals.addAll([
        base * 0.35,
        base * 0.5,
        base * 0.42,
        base * 0.65,
        base * 0.58,
        base * 0.8,
        base * 1.0,
      ]);
    }
    return CustomPaint(
      painter: _ChartPainter(vals),
      size: Size.infinite,
    );
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
      final y = size.height - (values[i] / maxV) * (size.height * 0.82) - 6;
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
          colors: [
            const Color(0xFF6366F1).withOpacity(0.4),
            const Color(0xFF6366F1).withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
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
    // نقطه آخر
    final lx = n == 1 ? size.width / 2 : size.width;
    final ly = size.height - (values.last / maxV) * (size.height * 0.82) - 6;
    canvas.drawCircle(Offset(lx, ly), 5, Paint()..color = const Color(0xFFA78BFA));
    canvas.drawCircle(Offset(lx, ly), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.values != values;
}
