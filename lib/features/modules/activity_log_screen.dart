import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shamsi_picker.dart';

/// لاگ تغییرات مدیریت (قیمت، موجودی، وضعیت سفارش و ...)
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});
  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  bool loading = true;
  List items = [];
  String? error;

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
      final res = await context.read<AuthService>().api.dio.get('activity-log', queryParameters: {'per_page': 50});
      if (res.data is Map && res.data['items'] is List) {
        items = res.data['items'] as List;
      } else {
        items = [];
      }
    } catch (e) {
      error = 'خطا در دریافت لاگ';
      items = [];
    }
    if (mounted) setState(() => loading = false);
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
      default:
        return AppColors.blue;
    }
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
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : error != null
                    ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                    : items.isEmpty
                        ? const Center(child: Text('هنوز فعالیتی ثبت نشده', style: TextStyle(color: AppColors.textDim)))
                        : RefreshIndicator(
                            color: AppColors.purple,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final m = Map<String, dynamic>.from(items[i] as Map);
                                final type = m['type']?.toString() ?? '';
                                final c = _color(type);
                                final date = (m['created'] ?? '').toString();
                                final short = formatAnyDate(date);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: NeonCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
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
