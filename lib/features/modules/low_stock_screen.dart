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
  int checked = 0;
  List items = [];
  String? error;
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
    setState(() {
      loading = true;
      error = null;
    });
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();

    // ۱) آستانه از سرور
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

    // ۲) لیست کمبود/ناموجود
    try {
      final res = await auth.api.dio.get('low-stock', queryParameters: {
        'threshold': threshold,
      });
      if (res.statusCode == 401) {
        error = 'نشست منقضی شده — دوباره وارد شوید';
        items = [];
      } else if (res.data is Map) {
        final m = res.data as Map;
        final low = m['low_stock'] is List ? List.from(m['low_stock'] as List) : <dynamic>[];
        final out = m['out_of_stock'] is List ? List.from(m['out_of_stock'] as List) : <dynamic>[];
        if (m['items'] is List && (m['items'] as List).isNotEmpty) {
          items = List.from(m['items'] as List);
        } else if (m['products'] is List && (m['products'] as List).isNotEmpty) {
          items = List.from(m['products'] as List);
        } else {
          items = [...low, ...out];
        }
        if (m['threshold'] != null) {
          final st = int.tryParse('${m['threshold']}');
          if (st != null) {
            threshold = st;
            thCtrl.text = '$st';
          }
        }
        checked = int.tryParse('${m['checked'] ?? m['total'] ?? 0}') ?? 0;
      } else {
        error = 'پاسخ نامعتبر از سرور';
        items = [];
      }
    } catch (e) {
      error = e.toString();
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveThreshold() async {
    final th = int.tryParse(thCtrl.text.trim());
    if (th == null || th < 0) {
      showErr(context, 'عدد معتبر وارد کنید');
      return;
    }
    setState(() => savingTh = true);
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'settings/threshold',
        data: {'threshold': th, 'enabled': true},
      );
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        if (mounted) showErr(context, 'ذخیره نشد ($code)');
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
      if (mounted) showOk(context, 'آستانه $saved ذخیره شد');
      await _load();
    } catch (e) {
      if (mounted) showErr(context, '$e');
    }
    if (mounted) setState(() => savingTh = false);
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = items.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final st = m['stock_status']?.toString() ?? '';
      final q = m['stock'];
      return st != 'outofstock' && q != null && (int.tryParse('$q') ?? 0) > 0;
    }).length;
    final outCount = items.length - lowCount;

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
                              items.isEmpty
                                  ? 'محصولی در آستانه نیست'
                                  : '$lowCount کمبود · $outCount ناموجود',
                              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                            ),
                            if (checked > 0)
                              Text('بررسی‌شده: $checked محصول',
                                  style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('آستانه هشدار (موجودی ≤ این عدد)', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
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
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _load, child: const Text('تلاش مجدد')),
                          ]),
                        ),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Text(
                              'محصولی با موجودی ≤ $threshold یافت نشد',
                              style: const TextStyle(color: AppColors.textDim),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.purple,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) {
                                final m = Map<String, dynamic>.from(items[i] as Map);
                                final name = m['name']?.toString() ?? '—';
                                final stock = m['stock'];
                                final st = m['stock_status']?.toString() ?? '';
                                final isOut = st == 'outofstock' || (stock != null && (int.tryParse('$stock') ?? 1) <= 0);
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
                                              Text(
                                                stock == null ? 'موجودی: نامشخص' : 'موجودی: $stock عدد',
                                                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (isOut ? AppColors.red : AppColors.orange).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                      color: (isOut ? AppColors.red : AppColors.orange).withOpacity(0.35)),
                                                ),
                                                child: Text(
                                                  isOut ? 'ناموجود' : 'در آستانه',
                                                  style: TextStyle(
                                                    color: isOut ? AppColors.red : AppColors.orange,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
