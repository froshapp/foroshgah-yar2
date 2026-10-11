import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    final prefs = await SharedPreferences.getInstance();
    threshold = prefs.getInt('stock_threshold') ?? 5;
    try {
      final auth = context.read<AuthService>();
      final res = await auth.api.dio.get('low-stock', queryParameters: {'threshold': threshold});
      if (res.data is Map) {
        final m = res.data as Map;
        low = m['low_stock'] is List ? m['low_stock'] as List : [];
        out = m['out_of_stock'] is List ? m['out_of_stock'] as List : [];
        total = int.tryParse(m['total']?.toString() ?? '') ?? 0;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
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
      body: SafeArea(
        child: Column(children: [
          GlassHeader(
            title: 'یادآوری موجودی محصول',
            subtitle: 'مدیریت هوشمند موجودی کالاها',
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
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text('آستانه: $threshold عدد (از تنظیمات قابل تغییر)', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                            const SizedBox(height: 10),
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
                                padding: EdgeInsets.all(24),
                                child: Text('محصولی با این فیلتر یافت نشد', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim)),
                              ),
                            ..._items.map((e) {
                              final m = Map<String, dynamic>.from(e as Map);
                              final stock = m['stock'];
                              final isOut = (m['stock_status']?.toString() == 'outofstock') || (stock is num && stock <= 0);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  borderColor: (isOut ? AppColors.red : AppColors.orange).withOpacity(0.4),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(m['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('موجودی: ${stock ?? '—'}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                      ]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isOut ? AppColors.red : AppColors.orange).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(isOut ? 'تمام شده' : 'کم‌موجود', style: TextStyle(color: isOut ? AppColors.red : AppColors.orange, fontSize: 11)),
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
      ),
    );
  }

  Widget _stat(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.4),
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        ]),
      );

  Widget _chip(String label, String val) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12)),
        selected: sel,
        selectedColor: AppColors.purple.withOpacity(0.4),
        backgroundColor: AppColors.card,
        onSelected: (_) => setState(() => filter = val),
      ),
    );
  }
}
