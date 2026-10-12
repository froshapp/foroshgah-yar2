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
  bool savingTh = false;
  int threshold = 5;
  List items = [];
  final thCtrl = TextEditingController();

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
    setState(() => loading = true);
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();
    try {
      final st = await auth.api.dio.get('settings/threshold');
      if (st.data is Map && st.data['threshold'] != null) {
        threshold = int.tryParse('${st.data['threshold']}') ?? threshold;
        await prefs.setInt('stock_threshold', threshold);
      }
    } catch (_) {
      threshold = prefs.getInt('stock_threshold') ?? threshold;
    }
    thCtrl.text = '$threshold';
    try {
      final res = await auth.api.dio.get('low-stock', queryParameters: {'threshold': threshold});
      if (res.data is Map) {
        final m = res.data as Map;
        items = m['items'] is List
            ? m['items'] as List
            : (m['products'] is List ? m['products'] as List : []);
        if (m['threshold'] != null) {
          final st = int.tryParse('${m['threshold']}');
          if (st != null) threshold = st;
        }
      }
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveThreshold() async {
    final th = int.tryParse(thCtrl.text.trim()) ?? threshold;
    setState(() => savingTh = true);
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'settings/threshold',
        data: {'threshold': th, 'enabled': true},
      );
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        if (mounted) showErr(context, 'ذخیره نشد');
        if (mounted) setState(() => savingTh = false);
        return;
      }
      int saved = th;
      if (res.data is Map && res.data['threshold'] != null) {
        saved = int.tryParse('${res.data['threshold']}') ?? th;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stock_threshold', saved);
      threshold = saved;
      thCtrl.text = '$saved';
      if (mounted) showOk(context, 'ذخیره شد');
      await _load();
    } catch (e) {
      if (mounted) showErr(context, '$e');
    }
    if (mounted) setState(() => savingTh = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GlassHeader(
            showSettingsGear: false,
            title: 'یادآوری موجودی محصول',
            subtitle: 'هشدار کمبود موجودی',
            leadingIcon: Icons.notifications_active_rounded,
            leadingColor: AppColors.blue,
            onRefresh: _load,
          ),
          // کارت وضعیت / آستانه
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: NeonCard(
              borderColor: AppColors.purple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SoftIconBox(icon: Icons.inventory_2_rounded, color: AppColors.purple, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وضعیت موجودی',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} محصول در آستانه موجودی',
                              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('آستانه هشدار', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1230),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E2A55)),
                          ),
                          child: TextField(
                            controller: thCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'مثلاً ۵',
                              hintStyle: TextStyle(color: AppColors.textMute),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: savingTh ? null : _saveThreshold,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: savingTh
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('ذخیره'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : items.isEmpty
                    ? const Center(child: Text('محصولی در آستانه نیست', style: TextStyle(color: AppColors.textDim)))
                    : RefreshIndicator(
                        color: AppColors.purple,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final m = Map<String, dynamic>.from(items[i] as Map);
                            final name = m['name']?.toString() ?? '—';
                            final stock = m['stock'] ?? m['stock_quantity'] ?? 0;
                            final img = m['image']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NeonCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: img.isNotEmpty
                                          ? Image.network(img, width: 56, height: 56, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _ph())
                                          : _ph(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          Text('موجودی: $stock عدد',
                                              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.red.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppColors.red.withOpacity(0.35)),
                                            ),
                                            child: const Text('در آستانه',
                                                style: TextStyle(
                                                    color: AppColors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_left, color: AppColors.textMute),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.image_outlined, color: AppColors.textMute),
      );
}
