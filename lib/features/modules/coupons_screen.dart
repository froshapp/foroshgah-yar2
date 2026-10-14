import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shamsi_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// مدیریت حرفه‌ای کوپن ووکامرس
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

  String _typeLabel(String? t) {
    switch (t) {
      case 'percent':
        return 'درصدی';
      case 'fixed_cart':
        return 'مبلغ ثابت سبد';
      case 'fixed_product':
        return 'مبلغ ثابت محصول';
      default:
        return t ?? '—';
    }
  }

  Future<void> _create() async {
    final codeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    final perUserCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'percent';
    bool individual = false;
    bool freeShip = false;
    Jalali? expires;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1230),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setS) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 14),
                const Text('کوپن جدید', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _field(codeCtrl, 'کد کوپن *', Icons.confirmation_number_outlined),
                const SizedBox(height: 10),
                _field(amountCtrl, 'مقدار تخفیف *', Icons.percent_rounded, number: true),
                const SizedBox(height: 12),
                const Text('نوع تخفیف', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('درصدی', 'percent', type, (v) => setS(() => type = v)),
                  _chip('مبلغ ثابت سبد', 'fixed_cart', type, (v) => setS(() => type = v)),
                  _chip('مبلغ ثابت محصول', 'fixed_product', type, (v) => setS(() => type = v)),
                ]),
                const SizedBox(height: 12),
                _field(minCtrl, 'حداقل مبلغ سبد (اختیاری)', Icons.shopping_bag_outlined, number: true),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(limitCtrl, 'سقف کل استفاده', Icons.tag, number: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(perUserCtrl, 'سقف هر کاربر', Icons.person_outline, number: true)),
                ]),
                const SizedBox(height: 10),
                _field(descCtrl, 'توضیح (اختیاری)', Icons.notes_outlined),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final j = await pickShamsiDate(ctx, initial: expires);
                    if (j != null) setS(() => expires = j);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121E42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A3A6A)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.event_rounded, color: AppColors.purpleGlow, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        expires != null ? 'انقضا: ${formatJalali(expires!)}' : 'تاریخ انقضا (اختیاری)',
                        style: TextStyle(color: expires != null ? Colors.white : AppColors.textDim, fontSize: 13),
                      ),
                      const Spacer(),
                      if (expires != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMute, size: 18),
                          onPressed: () => setS(() => expires = null),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('استفاده تکی (با کوپن دیگر ترکیب نشود)', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: individual,
                  activeColor: AppColors.purple,
                  onChanged: (v) => setS(() => individual = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ارسال رایگان', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: freeShip,
                  activeColor: AppColors.purple,
                  onChanged: (v) => setS(() => freeShip = v),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    if (codeCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('کد و مقدار لازم است')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ایجاد کوپن', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }),
        );
      },
    );

    if (ok != true || !mounted) return;

    // تبدیل شمسی به میلادی برای ووکامرس
    String? expiresIso;
    if (expires != null) {
      final g = expires!.toDateTime();
      expiresIso = '${g.year.toString().padLeft(4, '0')}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}';
    }

    try {
      await context.read<AuthService>().api.dio.post('coupons', data: {
        'code': codeCtrl.text.trim(),
        'amount': amountCtrl.text.trim(),
        'discount_type': type,
        if (minCtrl.text.trim().isNotEmpty) 'minimum_amount': minCtrl.text.trim(),
        if (limitCtrl.text.trim().isNotEmpty) 'usage_limit': limitCtrl.text.trim(),
        if (perUserCtrl.text.trim().isNotEmpty) 'usage_limit_per_user': perUserCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
        if (expiresIso != null) 'date_expires': expiresIso,
        'individual_use': individual,
        'free_shipping': freeShip,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('کوپن ایجاد شد و در تسویه حساب سایت اعمال می‌شود'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ));
      }
    }
  }

  Future<void> _delete(Map c) async {
    final id = int.tryParse('${c['id']}') ?? 0;
    if (id <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('حذف کوپن؟', style: TextStyle(color: Colors.white)),
        content: Text('کد «${c['code']}» حذف شود.', style: const TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.dio.delete('coupons/$id');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حذف شد'), backgroundColor: Color(0xFF065F46)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: const Color(0xFF7F1D1D)));
      }
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textMute, size: 20),
        filled: true,
        fillColor: const Color(0xFF121E42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A3A6A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A3A6A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple)),
      ),
    );
  }

  Widget _chip(String label, String value, String selected, ValueChanged<String> onSel) {
    final on = selected == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.textDim, fontSize: 12)),
      selected: on,
      selectedColor: AppColors.purple,
      backgroundColor: const Color(0xFF121E42),
      onSelected: (_) => onSel(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'کوپن و تخفیف',
          subtitle: 'مدیریت کدهای تخفیف ووکامرس',
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
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : coupons.isEmpty
                  ? const Center(child: Text('کوپنی ثبت نشده', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: coupons.length,
                        itemBuilder: (_, i) {
                          final c = Map<String, dynamic>.from(coupons[i] as Map);
                          final isPercent = (c['discount_type']?.toString() ?? '').contains('percent');
                          final amount = c['amount']?.toString() ?? '0';
                          final used = c['usage_count'] ?? 0;
                          final limit = c['usage_limit'];
                          final exp = c['date_expires']?.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                SoftIconBox(icon: Icons.local_offer_rounded, color: const Color(0xFF22C55E), size: 48),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(c['code']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${isPercent ? '$amount٪' : '$amount تومان'} · ${_typeLabel(c['discount_type']?.toString())}',
                                      style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'استفاده: $used${limit != null && limit.toString() != '0' && limit.toString().isNotEmpty ? ' / $limit' : ''}'
                                      '${exp != null && exp.isNotEmpty ? ' · انقضا: $exp' : ''}',
                                      style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                                    ),
                                    if ((c['minimum_amount'] ?? '').toString().isNotEmpty && c['minimum_amount'].toString() != '0')
                                      Text('حداقل سبد: ${c['minimum_amount']}', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                  ]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
                                  onPressed: () => _delete(c),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
