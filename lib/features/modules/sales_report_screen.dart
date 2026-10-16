import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});
  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool loading = true;
  String? error;
  Map data = {};
  int days = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('sales-report', queryParameters: {'days': days});
      if (res.data is Map) data = Map.from(res.data as Map);
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  String _fmt(dynamic v) {
    final n = double.tryParse('$v') ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final daily = data['daily'] is List ? data['daily'] as List : [];
    final top = data['top_products'] is List ? data['top_products'] as List : [];
    final byPay = data['by_payment'] is Map ? Map<String, dynamic>.from(data['by_payment'] as Map) : <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'گزارش فروش',
          subtitle: days == 7 ? '۷ روز گذشته' : '$days روز گذشته',
          leadingIcon: Icons.area_chart_rounded,
          leadingColor: AppColors.purple,
          showSettingsGear: false,
          onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(children: [
            for (final d in [7, 14, 30])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$d روز'),
                    selected: days == d,
                    onSelected: (_) { setState(() => days = d); _load(); },
                    selectedColor: AppColors.purple,
                    labelStyle: TextStyle(color: days == d ? Colors.white : AppColors.textDim, fontSize: 12),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          Row(children: [
                            Expanded(child: _statCard('فروش کل', '${_fmt(data['total_sales'])} ت', AppColors.purple)),
                            const SizedBox(width: 8),
                            Expanded(child: _statCard('تعداد سفارش', '${data['total_orders'] ?? 0}', AppColors.blue)),
                          ]),
                          const SizedBox(height: 8),
                          _statCard('میانگین هر سفارش', '${_fmt(data['avg_order'])} تومان', AppColors.cyan),
                          const SizedBox(height: 14),
                          NeonCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('نمودار فروش روزانه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              SizedBox(height: 140, child: _MiniBars(daily: daily)),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          if (byPay.isNotEmpty) ...[
                            const Text('بر اساس روش پرداخت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            NeonCard(
                              child: Column(
                                children: byPay.entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(children: [
                                    Expanded(child: Text(e.key, style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
                                    Text('${_fmt(e.value)} ت', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ]),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (top.isNotEmpty) ...[
                            const Text('پرفروش‌ترین محصولات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...top.map((p) {
                              final m = Map<String, dynamic>.from(p as Map);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NeonCard(
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(m['name']?.toString() ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        Text('تعداد: ${m['qty'] ?? 0}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                      ]),
                                    ),
                                    Text('${_fmt(m['total'])} ت', style: const TextStyle(color: AppColors.purpleGlow, fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, Color c) {
    return NeonCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
    );
  }
}

class _MiniBars extends StatelessWidget {
  final List daily;
  const _MiniBars({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(child: Text('داده‌ای نیست', style: TextStyle(color: AppColors.textMute)));
    }
    double maxV = 1;
    for (final d in daily) {
      final v = double.tryParse('${(d as Map)['sales'] ?? 0}') ?? 0;
      if (v > maxV) maxV = v;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: daily.map((d) {
        final m = Map<String, dynamic>.from(d as Map);
        final v = double.tryParse('${m['sales'] ?? 0}') ?? 0;
        final h = (v / maxV) * 110 + 4;
        final label = (m['date_jalali']?.toString() ?? m['date']?.toString() ?? '');
        final short = label.length >= 5 ? label.substring(label.length - 5) : label;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF7047F5), Color(0xFF2868FF)],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(short, style: const TextStyle(color: AppColors.textMute, fontSize: 9)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
