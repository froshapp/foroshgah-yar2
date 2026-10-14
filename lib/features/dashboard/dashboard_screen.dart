import 'dart:math' as math;
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
  List _recentOrders = [];
  String _period = 'امروز';

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
      final api = context.read<AuthService>().api;
      final o = await api.dio.get('orders', queryParameters: {'per_page': 3, 'page': 1});
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dash = context.watch<DashboardService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final shortName = siteName.length > 14 ? '${siteName.substring(0, 14)}…' : siteName;
    final stats = dash.stats;

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
            GlassHeader(
              title: shortName,
              subtitle: 'مدیریت فروشگاه ووکامرس',
              leadingIcon: Icons.storefront_rounded,
              leadingColor: AppColors.purple,
            ),

            if (dash.loading && stats['total_products'] == 0)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: MiniLoader()))
            else ...[
              const SizedBox(height: 10),

              // ─── آمار کلی فروشگاه — ۴ کارت در یک ردیف ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: _deco(const Color(0xFF2A3A6A)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SoftIconBox(icon: Icons.bar_chart_rounded, color: AppColors.blue, size: 28),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('آمار کلی فروشگاه',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1230),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E2A55)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_period, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMute, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ۴ کارت در یک ردیف افقی
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _statTile(
                              title: 'سفارشات',
                              value: _fmt(stats['today_orders']),
                              pct: '٪۱۲+',
                              color: const Color(0xFF8B5CF6),
                              icon: Icons.shopping_cart_rounded,
                              spark: const [0.3, 0.45, 0.35, 0.6, 0.5, 0.75, 0.9],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _statTile(
                              title: 'درآمد',
                              value: _fmt(stats['today_sales']),
                              pct: '٪۱۸+',
                              color: const Color(0xFF3B82F6),
                              icon: Icons.receipt_long_rounded,
                              spark: const [0.4, 0.55, 0.45, 0.7, 0.6, 0.85, 1.0],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _statTile(
                              title: 'محصولات',
                              value: _fmt(stats['total_products']),
                              pct: '٪۵+',
                              color: const Color(0xFF22D3EE),
                              icon: Icons.view_in_ar_rounded,
                              spark: const [0.5, 0.4, 0.55, 0.48, 0.65, 0.7, 0.8],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _statTile(
                              title: 'مشتریان',
                              value: _fmt(stats['total_customers']),
                              pct: '٪۳+',
                              color: const Color(0xFFA78BFA),
                              icon: Icons.people_alt_rounded,
                              spark: const [0.35, 0.5, 0.42, 0.58, 0.52, 0.7, 0.85],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── دسترسی سریع ۳تایی کنار هم ───
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
                child: Row(children: [
                  Expanded(child: _quickTile(Icons.phone_in_talk_rounded, const Color(0xFF22D3EE), 'تماس‌ها', () => widget.onContacts?.call())),
                  const SizedBox(width: 8),
                  Expanded(child: _quickTile(Icons.add_rounded, const Color(0xFF8B5CF6), 'افزودن محصول', () => widget.onAddProduct?.call())),
                  const SizedBox(width: 8),
                  Expanded(child: _quickTile(Icons.receipt_long_rounded, const Color(0xFF3B82F6), 'سفارشات', () => widget.onNavigate?.call(1))),
                ]),
              ),

              const SizedBox(height: 14),

              // ─── فعالیت اخیر (قسمت علامت‌خورده موکاپ) ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onNavigate?.call(1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: _deco(const Color(0xFF2A3A6A)),
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
                          const SizedBox(width: 4),
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

  BoxDecoration _deco(Color border) => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2858), Color(0xFF121E42), Color(0xFF0C1530)],
        ),
        border: Border.all(color: border.withOpacity(0.55), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 18, offset: const Offset(0, 9)),
          BoxShadow(color: border.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      );

  Widget _statTile({
    required String title,
    required String value,
    required String pct,
    required Color color,
    required IconData icon,
    required List<double> spark,
    String? suffix,
  }) {
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152048), Color(0xFF0E1838)],
        ),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 9),
                ),
              ),
              SoftIconBox(icon: icon, color: color, size: 24),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 9, color: Color(0xFF34D399)),
              Flexible(
                child: Text(
                  pct,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 8, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            height: 16,
            child: CustomPaint(painter: _MiniSpark(spark, color)),
          ),
        ],
      ),
    );
  }

  Widget _quickTile(IconData icon, Color color, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          decoration: _deco(color.withOpacity(0.35)),
          child: Column(
            children: [
              SoftIconBox(icon: icon, color: color, size: 42),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.textMute, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSpark extends CustomPainter {
  final List<double> values;
  final Color color;
  _MiniSpark(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max).clamp(0.01, double.infinity);
    final n = values.length;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = size.height - (values[i] / maxV) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (n - 1);
        final prevY = size.height - (values[i - 1] / maxV) * size.height;
        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSpark old) => old.values != values;
}
