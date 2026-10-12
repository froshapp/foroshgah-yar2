import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

/// پنل کشویی اعلان‌ها (شبیه پیشخوان وردپرس)
Future<void> openNotificationsPanel(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NotifSheet(),
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // سازگاری با مسیر قدیمی
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      openNotificationsPanel(context);
    });
    return const Scaffold(backgroundColor: AppColors.bg, body: Center(child: MiniLoader()));
  }
}

class _NotifSheet extends StatefulWidget {
  const _NotifSheet();
  @override
  State<_NotifSheet> createState() => _NotifSheetState();
}

class _NotifSheetState extends State<_NotifSheet> {
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

  Future<void> _dismiss(String id) async {
    try {
      await context.read<AuthService>().api.dio.post('notifications/dismiss', data: {'id': id});
      setState(() => items = items.where((e) => (e as Map)['id'] != id).toList());
    } catch (e) {
      if (mounted) showErr(context, '$e');
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'order': return Icons.shopping_bag_outlined;
      case 'stock': return Icons.inventory_2_outlined;
      case 'task': return Icons.checklist_rtl;
      case 'announce': return Icons.campaign_outlined;
      default: return Icons.notifications_none;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'order': return const Color(0xFF6EE7B7);
      case 'stock': return AppColors.orange;
      case 'task': return AppColors.blue;
      case 'announce': return AppColors.purpleGlow;
      default: return AppColors.textMute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.72;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(children: [
            const Text('اعلان‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Text('${items.length}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white54, size: 20), onPressed: _load),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : items.isEmpty
                  ? const Center(child: Text('اعلانی نیست', style: TextStyle(color: AppColors.textDim)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final m = Map<String, dynamic>.from(items[i] as Map);
                        final type = m['type']?.toString() ?? '';
                        final c = _color(type);
                        final id = m['id']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c.withOpacity(0.12), const Color(0xFF16183A)],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.withOpacity(0.35)),
                              boxShadow: [BoxShadow(color: c.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(children: [
                              Container(width: 4, height: 64, decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)))),
                              const SizedBox(width: 12),
                              Icon(_icon(type), color: c, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                    if ((m['body']?.toString() ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(m['body'].toString(), maxLines: 2, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                    ],
                                  ]),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textMute),
                                onPressed: () => _dismiss(id),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
