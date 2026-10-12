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
    setState(() { loading = true; error = null; });
    final auth = context.read<AuthService>();
    // فقط از سرور بخوان — prefs فقط پشتیبان
    try {
      final st = await auth.api.dio.get('settings/threshold');
      if (st.data is Map && st.data['threshold'] != null) {
        threshold = int.tryParse('${st.data['threshold']}') ?? threshold;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('stock_threshold', threshold);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      threshold = prefs.getInt('stock_threshold') ?? threshold;
    }
    thCtrl.text = '$threshold';
    try {
      final res = await auth.api.dio.get('low-stock', queryParameters: {'threshold': threshold});
      if (res.data is Map) {
        final m = res.data as Map;
        low = m['low_stock'] is List ? m['low_stock'] as List : [];
        out = m['out_of_stock'] is List ? m['out_of_stock'] as List : [];
        total = int.tryParse(m['total']?.toString() ?? '') ?? (low.length + out.length);
        // اگر سرور آستانه برگرداند همان را بگیر
        if (m['threshold'] != null) {
          final st = int.tryParse('${m['threshold']}');
          if (st != null) {
            threshold = st;
            thCtrl.text = '$st';
          }
        }
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveThreshold() async {
    final raw = thCtrl.text.trim().replaceAll(RegExp(r'[^0-9۰-۹]'), '');
    // تبدیل ارقام فارسی
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();
    for (final ch in raw.split('')) {
      final i = fa.indexOf(ch);
      buf.write(i >= 0 ? '$i' : ch);
    }
    final th = int.tryParse(buf.toString()) ?? 5;
    setState(() => savingTh = true);
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'settings/threshold',
        data: {'threshold': th, 'enabled': true},
      );
      int saved = th;
      if (res.data is Map && res.data['threshold'] != null) {
        saved = int.tryParse('${res.data['threshold']}') ?? th;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stock_threshold', saved);
      threshold = saved;
      thCtrl.text = '$saved';
      if (mounted) {
        setState(() {});
        showOk(context, 'آستانه $saved ذخیره شد');
      }
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
          subtitle: 'آستانه فعلی: $threshold',
          leadingIcon: Icons.inventory_2_rounded,
          leadingColor: const Color(0xFF60A5FA),
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: AppColors.red))))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          NeonCard(
                            borderColor: AppColors.cyan,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(children: [
                              const Icon(Icons.tune_rounded, color: AppColors.cyan, size: 20),
                              const SizedBox(width: 10),
                              const Text('آستانه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 72,
                                child: TextField(
                                  controller: thCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                                  backgroundColor: AppColors.purple.withOpacity(0.35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: savingTh
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.w700)),
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
                                      Text('موجودی: ${stock ?? 0}  |  آستانه: $threshold', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
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
