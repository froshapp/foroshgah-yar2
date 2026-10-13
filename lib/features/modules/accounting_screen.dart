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
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await context.read<AuthService>().api.dio.get('accounting');
      if (res.data is Map) data = Map<String, dynamic>.from(res.data as Map);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  List get _recent {
    if (data['recent'] is List) return data['recent'] as List;
    if (data['transactions'] is List) return data['transactions'] as List;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final daily = data['daily_sales'] is List ? data['daily_sales'] as List : [];
    final income = data['total_income'] ?? data['income'] ?? data['total_sales'] ?? 0;
    final expense = data['total_expense'] ?? data['expense'] ?? data['costs'] ?? 0;
    final net = data['net'] ?? ((double.tryParse('$income') ?? 0) - (double.tryParse('$expense') ?? 0));
    final rawRecent = _recent;
    // گروه‌بندی بر اساس شماره سفارش
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final e in rawRecent) {
      final m = Map<String, dynamic>.from(e as Map);
      final key = '${m['order_number'] ?? m['id'] ?? ''}';
      if (key.isEmpty) continue;
      final total = double.tryParse('${m['total'] ?? m['amount'] ?? 0}') ?? 0;
      final st = (m['status']?.toString() ?? '').toLowerCase();
      final isCancel = st.contains('cancel') || st.contains('refund') || st.contains('fail');
      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'order_number': key,
          'total': 0.0,
          'label': m['label']?.toString() ?? m['detail']?.toString() ?? 'سفارش',
          'date': m['date']?.toString() ?? m['created']?.toString() ?? '',
          'cancelled': isCancel,
          'status': st,
        };
      }
      grouped[key]!['total'] = (grouped[key]!['total'] as double) + total;
      if (isCancel) grouped[key]!['cancelled'] = true;
    }
    final recent = grouped.values.toList();
    double sumRecent = 0;
    for (final m in recent) {
      sumRecent += (m['total'] as double?) ?? 0;
    }

    double maxY = 1;
    for (final e in daily) {
      final t = double.tryParse('${(e as Map)['total'] ?? 0}') ?? 0;
      if (t > maxY) maxY = t;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: loading
          ? const Center(child: MiniLoader())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
              : Column(children: [
                  GlassHeader(
                    showSettingsGear: false,
                    title: 'حسابداری فروشگاه',
                    subtitle: 'گزارش مالی و تراکنش‌ها',
                    leadingIcon: Icons.account_balance_wallet_rounded,
                    leadingColor: AppColors.purple,
                    onRefresh: _load,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          // سه KPI مثل موکاپ
                          Row(children: [
                            Expanded(child: _kpi('درآمد کل', _fmt(income), AppColors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpi('خالص', _fmt(net), AppColors.cyan)),
                            const SizedBox(width: 8),
                            Expanded(child: _kpi('هزینه‌ها', _fmt(expense), AppColors.pink)),
                          ]),
                          const SizedBox(height: 14),
                          // نمودار
                          NeonCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text('نمودار فروش',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                  Text('۷ روز اخیر', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                                ],
                              ),
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
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
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
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          // آخرین تراکنش‌ها مثل موکاپ
                          Row(children: [
                            const Expanded(
                              child: Text('آخرین تراکنش‌ها',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                            Text('جمع: ${_fmt(sumRecent)}',
                                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                          const SizedBox(height: 10),
                          if (recent.isEmpty)
                            const NeonCard(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('تراکنشی نیست', style: TextStyle(color: AppColors.textDim)),
                                ),
                              ),
                            )
                          else
                            ...recent.take(12).map((e) {
                              final m = Map<String, dynamic>.from(e);
                              final label = 'سفارش #${m['order_number'] ?? ''}';
                              final total = _fmt(m['total']);
                              final isCancel = m['cancelled'] == true;
                              final color = isCancel ? AppColors.red : AppColors.green;
                              final icon = isCancel ? Icons.close_rounded : Icons.shopping_bag_outlined;
                              final orderNo = m['order_number'] ?? '';
                              final date = m['date']?.toString() ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NeonCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(icon, color: color, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                        if (orderNo.toString().isNotEmpty || date.isNotEmpty)
                                          Text(
                                            [if (orderNo.toString().isNotEmpty) 'سفارش $orderNo', if (date.isNotEmpty) date].join(' · '),
                                            style: const TextStyle(color: AppColors.textMute, fontSize: 11),
                                          ),
                                      ]),
                                    ),
                                    Text(
                                      '${isCancel || isShip ? '' : '+'}$total',
                                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ]),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _kpi(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.35),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 6),
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
        ]),
      );
}
