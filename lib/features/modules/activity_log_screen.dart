import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shamsi_picker.dart';

/// لاگ تغییرات مدیریت با فیلتر نوع و پاک‌سازی
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});
  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  bool loading = true;
  List items = [];
  String? error;
  String filter = 'all';
  bool selectMode = false;
  final Set<String> selected = {};

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
      final res = await context.read<AuthService>().api.dio.get(
        'activity-log',
        queryParameters: {
          'per_page': 100,
          if (filter != 'all') 'type': filter,
        },
      );
      if (res.data is Map && res.data['items'] is List) {
        items = res.data['items'] as List;
      } else {
        items = [];
      }
    } catch (e) {
      error = 'خطا در دریافت لاگ';
      items = [];
    }
    if (mounted) {
      setState(() {
        loading = false;
        selected.clear();
        selectMode = false;
      });
    }
  }

  Future<void> _clear({bool all = false}) async {
    if (!all && selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(all ? 'پاک کردن همه لاگ‌ها؟' : 'حذف ${selected.length} مورد؟', style: const TextStyle(color: Colors.white)),
        content: const Text('این عمل قابل بازگشت نیست.', style: TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthService>().api.dio.post('activity-log', data: {
        if (all) 'all': true,
        if (!all) 'ids': selected.toList(),
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('پاک شد'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ));
      }
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'price':
        return Icons.price_change_rounded;
      case 'stock':
        return Icons.inventory_2_rounded;
      case 'order':
        return Icons.receipt_long_rounded;
      case 'coupon':
        return Icons.local_offer_rounded;
      case 'product':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'price':
        return const Color(0xFF8B5CF6);
      case 'stock':
        return const Color(0xFFF59E0B);
      case 'order':
        return const Color(0xFF3B82F6);
      case 'coupon':
        return const Color(0xFF22C55E);
      case 'product':
        return const Color(0xFF2868FF);
      default:
        return AppColors.blue;
    }
  }

  Widget _filterChip(String label, String value) {
    final on = filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: on ? Colors.white : AppColors.textDim, fontSize: 11)),
        selected: on,
        selectedColor: AppColors.purple,
        backgroundColor: const Color(0xFF121E42),
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          setState(() => filter = value);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GlassHeader(
            showSettingsGear: false,
            title: 'لاگ تغییرات',
            subtitle: 'فعالیت‌های اخیر مدیریت',
            leadingIcon: Icons.history_rounded,
            leadingColor: AppColors.blue,
            onRefresh: _load,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              _filterChip('همه', 'all'),
              _filterChip('قیمت', 'price'),
              _filterChip('محصول', 'product'),
              _filterChip('سفارش', 'order'),
              _filterChip('کوپن', 'coupon'),
              _filterChip('موجودی', 'stock'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  selectMode = !selectMode;
                  if (!selectMode) selected.clear();
                }),
                icon: Icon(selectMode ? Icons.close : Icons.checklist_rounded, size: 18, color: AppColors.purpleGlow),
                label: Text(selectMode ? 'انصراف' : 'انتخاب', style: const TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
              ),
              if (selectMode)
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (selected.length == items.length && items.isNotEmpty) {
                        selected.clear();
                      } else {
                        selected
                          ..clear()
                          ..addAll(items.map((e) {
                            final m = Map<String, dynamic>.from(e as Map);
                            return m['id']?.toString() ?? '';
                          }).where((id) => id.isNotEmpty));
                      }
                    });
                  },
                  child: Text(
                    selected.length == items.length && items.isNotEmpty ? 'لغو همه' : 'انتخاب همه',
                    style: const TextStyle(color: AppColors.blue, fontSize: 12),
                  ),
                ),
              if (selectMode && selected.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _clear(all: false),
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                  label: Text('حذف (${selected.length})', style: const TextStyle(color: AppColors.red, fontSize: 12)),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => _clear(all: true),
                child: Text('پاک کردن همه', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
              ),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : error != null
                    ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                    : items.isEmpty
                        ? const Center(child: Text('موردی نیست', style: TextStyle(color: AppColors.textDim)))
                        : RefreshIndicator(
                            color: AppColors.purple,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final m = Map<String, dynamic>.from(items[i] as Map);
                                final type = m['type']?.toString() ?? '';
                                final id = m['id']?.toString() ?? '$i';
                                final c = _color(type);
                                final date = (m['date_display'] ?? m['date_jalali'] ?? m['created'] ?? '').toString();
                                final short = date.contains('/') ? date : formatAnyDate(date);
                                final isSel = selected.contains(id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: NeonCard(
                                    onTap: selectMode
                                        ? () => setState(() {
                                              if (isSel) {
                                                selected.remove(id);
                                              } else {
                                                selected.add(id);
                                              }
                                            })
                                        : null,
                                    onLongPress: () => setState(() {
                                      selectMode = true;
                                      selected.add(id);
                                    }),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        if (selectMode)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Icon(
                                              isSel ? Icons.check_circle : Icons.circle_outlined,
                                              color: isSel ? AppColors.purpleGlow : AppColors.textMute,
                                              size: 22,
                                            ),
                                          ),
                                        SoftIconBox(icon: _icon(type), color: c, size: 44),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m['message']?.toString() ?? '—',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${m['user_name'] ?? 'سیستم'} · $short',
                                                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
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
}
