import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  bool loading = true;
  List coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('coupons');
      if (res.data is Map && res.data['coupons'] is List) {
        coupons = res.data['coupons'] as List;
      }
    } catch (_) {
      coupons = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    final codeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'percent';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1230),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: StatefulBuilder(builder: (ctx, setS) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('کوپن جدید', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'کد کوپن', labelStyle: TextStyle(color: AppColors.textDim)),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'مقدار', labelStyle: TextStyle(color: AppColors.textDim)),
              ),
              const SizedBox(height: 8),
              Row(children: [
                ChoiceChip(
                  label: const Text('درصدی'),
                  selected: type == 'percent',
                  onSelected: (_) => setS(() => type = 'percent'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('مبلغ ثابت'),
                  selected: type == 'fixed_cart',
                  onSelected: (_) => setS(() => type = 'fixed_cart'),
                ),
              ]),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                child: const Text('ایجاد'),
              ),
              const SizedBox(height: 12),
            ]);
          }),
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthService>().api.dio.post('coupons', data: {
        'code': codeCtrl.text.trim(),
        'amount': amountCtrl.text.trim(),
        'discount_type': type,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کوپن ایجاد شد'), backgroundColor: Color(0xFF065F46)));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: const Color(0xFF7F1D1D)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'کوپن و تخفیف',
          subtitle: 'مدیریت کدهای تخفیف',
          leadingIcon: Icons.local_offer_rounded,
          leadingColor: const Color(0xFF22C55E),
          onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('کوپن جدید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : coupons.isEmpty
                  ? const Center(child: Text('کوپنی نیست', style: TextStyle(color: AppColors.textDim)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: coupons.length,
                      itemBuilder: (_, i) {
                        final c = Map<String, dynamic>.from(coupons[i] as Map);
                        final isPercent = (c['discount_type']?.toString() ?? '').contains('percent');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NeonCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              SoftIconBox(icon: Icons.local_offer_rounded, color: const Color(0xFF22C55E), size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['code']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${c['amount'] ?? 0}${isPercent ? '٪' : ' تومان'} · استفاده: ${c['usage_count'] ?? 0}',
                                    style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                                  ),
                                ]),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
