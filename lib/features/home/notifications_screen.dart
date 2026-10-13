import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

void openNotificationsPanel(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  List items = [];
  String filter = 'all'; // all | order | task | stock | announce

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = <dynamic>[];
    final auth = context.read<AuthService>();
    try {
      final res = await auth.api.dio.get('notifications');
      if (res.data is Map && res.data['items'] is List) {
        list.addAll(res.data['items'] as List);
      }
    } catch (_) {}
    // کارهای در صف از API جداگانه (اگر در اعلان‌ها نیامده باشند)
    try {
      final tres = await auth.api.dio.get('tasks');
      if (tres.data is Map && tres.data['items'] is List) {
        final existing = list.map((e) => (e as Map)['id']?.toString()).toSet();
        for (final raw in tres.data['items'] as List) {
          if (raw is! Map) continue;
          if (raw['done'] == true || raw['done'] == 1 || raw['done'] == '1') continue;
          final id = raw['id']?.toString() ?? '';
          if (id.isEmpty || existing.contains(id)) continue;
          list.add({
            'id': id,
            'type': 'task',
            'title': 'کار: ${raw['title'] ?? ''}',
            'body': 'در صف انجام',
            'created': raw['created'] ?? '',
            'ref_id': id,
          });
          existing.add(id);
        }
      }
    } catch (_) {}
    items = list;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _dismiss(dynamic id) async {
    try {
      await context.read<AuthService>().api.dio.post('notifications/dismiss', data: {'id': id});
      setState(() => items = items.where((e) => (e as Map)['id'] != id).toList());
    } catch (_) {}
  }

  IconData _icon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart_outlined;
      case 'stock':
        return Icons.inventory_2_outlined;
      case 'task':
        return Icons.checklist_rtl_rounded;
      case 'announce':
        return Icons.campaign_outlined;
      case 'review':
        return Icons.star_outline_rounded;
      case 'ticket':
        return Icons.headset_mic_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'order':
        return AppColors.blue;
      case 'stock':
        return AppColors.orange;
      case 'task':
        return AppColors.cyan;
      case 'announce':
        return AppColors.purple;
      case 'review':
        return AppColors.pink;
      case 'ticket':
        return const Color(0xFFA78BFA);
      default:
        return AppColors.textDim;
    }
  }

  List get _filtered {
    if (filter == 'all') return items;
    return items.where((e) {
      final t = (e as Map)['type']?.toString() ?? '';
      return t == filter;
    }).toList();
  }

  int _count(String type) {
    if (type == 'all') return items.length;
    return items.where((e) => (e as Map)['type']?.toString() == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'اعلان‌ها',
          subtitle: 'پیام‌ها و هشدارهای مهم',
          leadingIcon: Icons.notifications_active_rounded,
          leadingColor: AppColors.blue,
          onRefresh: _load,
        ),
        // فیلتر چیپ‌ها مثل موکاپ
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            children: [
              _chip('همه', 'all', _count('all'), AppColors.purple),
              _chip('سفارشات', 'order', _count('order'), AppColors.blue),
              _chip('کارهای من', 'task', _count('task'), AppColors.cyan),
              _chip('محصولات', 'stock', _count('stock'), AppColors.orange),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : list.isEmpty
                  ? const Center(child: Text('اعلانی نیست', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final m = Map<String, dynamic>.from(list[i] as Map);
                          final type = m['type']?.toString() ?? '';
                          final c = _color(type);
                          final id = m['id'];
                          final created = m['created']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                SoftIconBox(icon: _icon(type), color: c, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m['title']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                    if ((m['body']?.toString() ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(m['body'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                    ],
                                    if (created.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(created, style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                                    ],
                                  ]),
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
        ),
      ]),
    );
  }

  Widget _chip(String label, String val, int n, Color c) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => filter = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: sel ? LinearGradient(colors: [c, c.withOpacity(0.75)]) : null,
            color: sel ? null : const Color(0xFF0B1230),
            border: Border.all(color: sel ? c.withOpacity(0.5) : const Color(0xFF1E2A55)),
          ),
          child: Text(
            n > 0 ? '$label ($n)' : label,
            style: TextStyle(
              color: sel ? Colors.white : AppColors.textDim,
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
