import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notif_badge_service.dart';
import '../../core/theme/app_theme.dart';

Future<void> openNotificationsPanel(BuildContext context) async {
  await Navigator.of(context).push(
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
  final Set<String> selected = {};
  bool selectMode = false;

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
    final sid = id?.toString() ?? '';
    if (sid.isEmpty) return;
    try {
      await context.read<AuthService>().api.dio.post('notifications/dismiss', data: {'id': sid});
      setState(() {
        items = items.where((e) => (e as Map)['id']?.toString() != sid).toList();
        selected.remove(sid);
      });
      // به‌روزرسانی فوری badge
      try {
        context.read<NotifBadgeService>().setCount(items.length);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _dismissSelected() async {
    final ids = selected.toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      try {
        await context.read<AuthService>().api.dio.post('notifications/dismiss', data: {'id': id});
      } catch (_) {}
    }
    setState(() {
      items = items.where((e) => !ids.contains((e as Map)['id']?.toString())).toList();
      selected.clear();
      selectMode = false;
    });
    try {
      context.read<NotifBadgeService>().setCount(items.length);
    } catch (_) {}
  }

  void _toggleSelectAll() {
    final list = _filtered;
    final allIds = list.map((e) => (e as Map)['id']?.toString() ?? '').where((e) => e.isNotEmpty).toSet();
    setState(() {
      if (selected.containsAll(allIds) && allIds.isNotEmpty) {
        selected.removeAll(allIds);
      } else {
        selected.addAll(allIds);
        selectMode = true;
      }
    });
  }

  IconData _icon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'stock':
        return Icons.inventory_2_rounded;
      case 'task':
        return Icons.checklist_rtl_rounded;
      case 'announce':
        return Icons.campaign_rounded;
      case 'review':
        return Icons.reviews_rounded;
      case 'ticket':
        return Icons.headset_mic_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF3B82F6);
      case 'stock':
        return const Color(0xFFF59E0B);
      case 'task':
        return const Color(0xFF22D3EE);
      case 'announce':
        return const Color(0xFFA78BFA);
      case 'review':
        return const Color(0xFFFBBF24);
      case 'ticket':
        return const Color(0xFF34D399);
      default:
        return AppColors.purple;
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
        // نوار انتخاب فقط بعد از نگه‌داشتن طولانی
        if (selectMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(children: [
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  selected.isNotEmpty && selected.length >= _filtered.length && _filtered.isNotEmpty
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: AppColors.purpleGlow, size: 20,
                ),
                label: Text(
                  selected.isEmpty ? 'انتخاب همه' : 'انتخاب‌شده (${selected.length})',
                  style: const TextStyle(color: AppColors.purpleGlow, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => setState(() { selected.clear(); selectMode = false; }),
                child: const Text('لغو', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              ),
              const Spacer(),
              if (selected.isNotEmpty)
                TextButton.icon(
                  onPressed: _dismissSelected,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                  label: const Text('حذف انتخاب‌ها', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                ),
            ]),
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

                          final sid = id?.toString() ?? '';
                          final isSel = selected.contains(sid);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  selectMode = true;
                                  selected.add(sid);
                                });
                              },
                              onTap: selectMode
                                  ? () {
                                      setState(() {
                                        if (isSel) {
                                          selected.remove(sid);
                                          if (selected.isEmpty) selectMode = false;
                                        } else {
                                          selected.add(sid);
                                        }
                                      });
                                    }
                                  : null,
                              child: NeonCard(
                              padding: const EdgeInsets.all(12),
                              borderColor: isSel ? AppColors.purple : null,
                              child: Row(children: [
                                if (selectMode) ...[
                                  Icon(
                                    isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    color: isSel ? AppColors.purpleGlow : AppColors.textMute,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                SoftIconBox(icon: _icon(type), color: _iconBg(type), size: 44),
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
                                if (!selectMode)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMute),
                                    onPressed: () => _dismiss(id),
                                  ),
                              ]),
                            ),
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
