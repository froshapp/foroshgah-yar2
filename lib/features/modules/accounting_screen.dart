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

  List<Map<String, dynamic>> get _grouped {
    final recent = data['recent'] is List ? data['recent'] as List : [];
    final map = <String, Map<String, dynamic>>{};
    for (final e in recent) {
      final m = Map<String, dynamic>.from(e as Map);
      final key = '${m['order_number'] ?? m['id'] ?? ''}';
      if (key.isEmpty) continue;
      final st = m['status']?.toString() ?? '';
      final isCancel = st.contains('cancel') || st.contains('refund') || st.contains('failed');
      final label = m['label']?.toString() ?? '';
      final isShip = label.contains('ارسال') || label.contains('بسته');
      final total = double.tryParse('${m['total'] ?? 0}') ?? 0;
      map.putIfAbsent(key, () => {
            'order_number': key,
            'detail': '',
            'qty': 0,
            'sale': 0.0,
            'ship': 0.0,
            'cancelled': isCancel,
            'status': st,
          });
      final g = map[key]!;
      if (isShip) {
        g['ship'] = (g['ship'] as double) + total;
      } else {
        g['sale'] = (g['sale'] as double) + total;
        g['detail'] = m['detail']?.toString() ?? g['detail'];
        g['qty'] = m['qty'] ?? g['qty'];
        g['cancelled'] = isCancel;
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final daily = data['daily_sales'] is List ? data['daily_sales'] as List : [];
    final groups = _grouped;
    final maxY = daily.fold<double>(1, (m, e) {
      final t = double.tryParse('${(e as Map)['total'] ?? 0}') ?? 0;
      return t > m ? t : m;
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: loading
          ? const Center(child: MiniLoader())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
              : Column(children: [
                  GlassHeader(showSettingsGear: false, title: 'حسابداری فروشگاه', subtitle: 'گزارش مالی', onRefresh: _load),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          Row(children: [
                            Expanded(child: _kpi('درآمد کل', _fmt(data['total_income']), AppColors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpi('خالص', _fmt(data['net']), AppColors.cyan)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpi('هزینه‌ها', _fmt(data['shipping_cost']), AppColors.pink)),
                          ]),
                          const SizedBox(height: 12),
                          NeonCard(
                            borderColor: AppColors.purple,
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
                                                    borderRadius: BorderRadius.circular(8),
                                                    gradient: const LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [Color(0xFF4A2BB8), Color(0xFFA78BFF)],
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
                          
                        ],
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _kpi(String t, String v, Color c) => NeonCard(
        borderColor: c,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
          const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
        ]),
      );
}
