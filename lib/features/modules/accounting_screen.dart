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

                        ],
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _kpi(String t, String v, Color c) => SizedBox(
        height: 92,
        child: NeonCard(
          borderColor: c.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(height: 2),
              const Text('تومان', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
            ],
          ),
        ),
      );
}
