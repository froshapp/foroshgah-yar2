import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  bool loading = true;
  String? error;
  Map data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('accounting');
      if (res.data is Map) data = Map<String, dynamic>.from(res.data as Map);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  String _fmt(dynamic v) {
    if (v == null) return '۰';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
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
    final daily = data['daily_sales'] is List ? data['daily_sales'] as List : [];
    final recent = data['recent'] is List ? data['recent'] as List : [];
    final maxY = daily.fold<double>(1, (m, e) {
      final t = double.tryParse('${(e as Map)['total'] ?? 0}') ?? 0;
      return t > m ? t : m;
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: loading
            ? const Center(child: MiniLoader())
            : error != null
                ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                : RefreshIndicator(
                    color: AppColors.purple,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        GlassHeader(
                          title: 'حسابداری فروشگاه',
                          subtitle: 'گزارش مالی',
                          actions: [
                            IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _kpi('درآمد کل', _fmt(data['total_income']), AppColors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _kpi('خالص', _fmt(data['net']), AppColors.cyan)),
                          const SizedBox(width: 8),
                          Expanded(child: _kpi('هزینه‌ها', _fmt(data['shipping_cost']), AppColors.pink)),
                        ]),
                        const SizedBox(height: 12),
                        NeonCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Row(children: [
                              Text('نمودار فروش', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Spacer(),
                              Text('۷ روز اخیر', style: TextStyle(color: AppColors.textMute, fontSize: 11)),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: daily.isEmpty
                                  ? const Center(child: Text('داده‌ای نیست', style: TextStyle(color: AppColors.textMute)))
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: daily.map((e) {
                                        final m = Map<String, dynamic>.from(e as Map);
                                        final t = double.tryParse('${m['total'] ?? 0}') ?? 0;
                                        final h = (t / maxY) * 100;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 3),
                                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                              Container(
                                                height: h.clamp(4, 100),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [AppColors.purple.withOpacity(0.3), AppColors.purpleGlow],
                                                  ),
                                                ),
                                              ),
                                            ]),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        NeonCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('آخرین تراکنش‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            if (recent.isEmpty)
                              const Text('تراکنشی نیست', style: TextStyle(color: AppColors.textDim))
                            else
                              ...recent.map((e) {
                                final m = Map<String, dynamic>.from(e as Map);
                                final out = m['type'] == 'out';
                                final total = double.tryParse('${m['total'] ?? 0}') ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(children: [
                                    Expanded(child: Text(m['label']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
                                    Text(
                                      '${out ? '-' : '+'}${_fmt(total)}',
                                      style: TextStyle(color: out ? AppColors.red : AppColors.green, fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                                );
                              }),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        NeonCard(
                          child: Text('تعداد سفارشات محاسبه‌شده: ${data['order_count'] ?? 0}',
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _kpi(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.35),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
          const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
        ]),
      );
}
