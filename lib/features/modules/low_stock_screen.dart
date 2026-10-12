import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});
  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  bool loading = true;
  String? error;
  List low = [];
  List out = [];
  int total = 0;
  int threshold = 5;
  String filter = 'all';
  final thCtrl = TextEditingController();
  bool savingTh = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    thCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = context.read<AuthService>();
    threshold = prefs.getInt('stock_threshold') ?? 5;
    try {
      final st = await auth.api.dio.get('settings/threshold');
      if (st.data is Map && st.data['threshold'] != null) {
        threshold = int.tryParse('${st.data['threshold']}') ?? threshold;
        await prefs.setInt('stock_threshold', threshold);
      }
    } catch (_) {}
    thCtrl.text = '$threshold';
    try {
      final res = await auth.api.dio.get('low-stock', queryParameters: {'threshold': threshold});
      if (res.data is Map) {
        final m = res.data as Map;
        low = m['low_stock'] is List ? m['low_stock'] as List : [];
        out = m['out_of_stock'] is List ? m['out_of_stock'] as List : [];
        total = int.tryParse(m['total']?.toString() ?? '') ?? (low.length + out.length);
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveThreshold() async {
    final th = int.tryParse(thCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    setState(() => savingTh = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'settings/threshold',
        data: {'threshold': th, 'enabled': true},
        queryParameters: {'threshold': th, 'enabled': true},
      );
      int saved = th;
      if (res.data is Map && res.data['threshold'] != null) {
        saved = int.tryParse('${res.data['threshold']}') ?? th;
      }
      await prefs.setInt('stock_threshold', saved);
      threshold = saved;
      thCtrl.text = '$saved';
      if (mounted) showOk(context, 'آستانه $saved ذخیره شد');
      await _load();
    } catch (e) {
      if (mounted) showErr(context, 'ذخیره نشد: $e');
    }
    if (mounted) setState(() => savingTh = false);
  }

  List get _items {
    if (filter == 'low') return low;
    if (filter == 'out') return out;
    return [...out, ...low];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'یادآوری موجودی',
          subtitle: 'مدیریت هوشمند موجودی کالا',
          leadingIcon: Icons.inventory_2_rounded,
          leadingColor: const Color(0xFF60A5FA),
          storeOpensSettings: false,
          onRefresh: _load,
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
                          // تنظیم آستانه مینیمال همین صفحه
                          NeonCard(
                            borderColor: AppColors.cyan,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(children: [
                              const Icon(Icons.tune_rounded, color: AppColors.cyan, size: 20),
                              const SizedBox(width: 10),
                              const Text('آستانه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 64,
                                child: TextField(
                                  controller: thCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('عدد', style: TextStyle(color: AppColors.textMute, fontSize: 11)),
                              const Spacer(),
                              TextButton(
                                onPressed: savingTh ? null : _saveThreshold,
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.purple.withOpacity(0.25),
                                  foregroundColor: AppColors.purpleGlow,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: savingTh
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                                    : const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _stat('کل', '$total', AppColors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _stat('تمام‌شده', '${out.length}', AppColors.red)),
                            const SizedBox(width: 8),
                            Expanded(child: _stat('کم‌موجود', '${low.length}', AppColors.orange)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _chip('همه', 'all'),
                            _chip('کم‌موجود', 'low'),
                            _chip('تمام‌شده', 'out'),
                          ]),
                          const SizedBox(height: 12),
                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('محصولی یافت نشد', style: TextStyle(color: AppColors.textDim))),
                            ),
                          ..._items.map((e) {
                            final m = Map<String, dynamic>.from(e as Map);
                            final stock = m['stock'];
                            final isOut = (m['stock_status']?.toString() == 'outofstock') || (stock is num && stock <= 0);
                            final accent = isOut ? AppColors.red : AppColors.orange;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NeonCard(
                                borderColor: accent,
                                child: Row(children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(m['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      if ((m['sku'] ?? '').toString().isNotEmpty)
                                        Text(m['sku'].toString(), style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                      Text('موجودی: ${stock ?? 0}', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: accent.withOpacity(0.4)),
                                    ),
                                    child: Text(isOut ? 'تمام شده' : 'کم‌موجود', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _stat(String t, String v, Color c) => NeonCard(
        borderColor: c,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(children: [
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        ]),
      );

  Widget _chip(String label, String val) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12)),
        selected: sel,
        selectedColor: AppColors.purple.withOpacity(0.45),
        backgroundColor: AppColors.card,
        onSelected: (_) => setState(() => filter = val),
      ),
    );
  }
}
