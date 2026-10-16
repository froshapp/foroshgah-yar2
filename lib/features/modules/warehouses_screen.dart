import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});
  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  bool loading = true;
  List items = [];
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('warehouses');
      if (res.data is Map && res.data['warehouses'] is List) {
        items = List.from(res.data['warehouses'] as List);
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    try {
      await context.read<AuthService>().api.dio.post('warehouses', data: {'warehouses': items});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('انبارها ذخیره شد'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: const Color(0xFF7F1D1D)));
      }
    }
  }

  void _add() {
    final n = nameCtrl.text.trim();
    if (n.isEmpty) return;
    setState(() {
      items.add({'id': 'wh_${DateTime.now().millisecondsSinceEpoch}', 'name': n});
      nameCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'انبارها',
          subtitle: 'مدیریت انبار / شعبه',
          leadingIcon: Icons.warehouse_rounded,
          leadingColor: AppColors.cyan,
          showSettingsGear: false,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    NeonCard(
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'نام انبار جدید',
                              hintStyle: TextStyle(color: AppColors.textMute),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(onPressed: _add, icon: const Icon(Icons.add_circle, color: AppColors.purpleGlow)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(items.length, (i) {
                      final m = Map<String, dynamic>.from(items[i] as Map);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NeonCard(
                          child: Row(children: [
                            const Icon(Icons.store_mall_directory_outlined, color: AppColors.cyan),
                            const SizedBox(width: 10),
                            Expanded(child: Text(m['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                            IconButton(
                              onPressed: () => setState(() => items.removeAt(i)),
                              icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                            ),
                          ]),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ذخیره انبارها'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'انبارها را اینجا تعریف کن. بعد در ویرایش هر محصول، از لیست کشویی «انبار» یکی را انتخاب و ذخیره کن.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}
