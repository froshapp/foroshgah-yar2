import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  List items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('notifications');
      if (res.data is Map && res.data['items'] is List) {
        items = res.data['items'] as List;
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  IconData _icon(String type) {
    switch (type) {
      case 'order': return Icons.shopping_bag_outlined;
      case 'task': return Icons.checklist_rtl;
      case 'announce': return Icons.campaign_outlined;
      default: return Icons.notifications_none;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'order': return const Color(0xFF6EE7B7); // pale green
      case 'task': return AppColors.blue;
      case 'announce': return AppColors.purpleGlow;
      default: return AppColors.textMute;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const GlassHeader(title: 'اعلان‌ها', subtitle: 'سفارش‌ها، کارها و اطلاعیه‌ها'),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : RefreshIndicator(
                    color: AppColors.purple,
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 100),
                            Center(child: Text('اعلانی نیست', style: TextStyle(color: AppColors.textDim))),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final m = Map<String, dynamic>.from(items[i] as Map);
                              final type = m['type']?.toString() ?? '';
                              final c = _color(type);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NeonCard(
                                  borderColor: c.withOpacity(0.3),
                                  child: Row(children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                      child: Icon(_icon(type), color: c, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(m['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text(m['body']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 11), maxLines: 2),
                                      ]),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ]),
      ),
    );
  }
}
