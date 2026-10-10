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
      if (res.data is Map) data = res.data as Map;
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  String _fmt(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '0') ?? 0;
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('حسابداری فروشگاه', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(child: MiniLoader())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
              : RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(children: [
                        Expanded(child: _card('درآمد کل', _fmt(data['total_income']), AppColors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _card('خالص', _fmt(data['net']), AppColors.cyan)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _card('هزینه ارسال', _fmt(data['shipping_cost']), AppColors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _card('مرجوعی', _fmt(data['refunds']), AppColors.red)),
                      ]),
                      const SizedBox(height: 16),
                      NeonCard(
                        child: Row(children: [
                          const Icon(Icons.receipt_long, color: AppColors.purpleGlow),
                          const SizedBox(width: 10),
                          Text('تعداد سفارشات محاسبه‌شده: ${data['order_count'] ?? 0}', style: const TextStyle(color: Colors.white)),
                        ]),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 6),
          Text('$v تومان', style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      );
}
