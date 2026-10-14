import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notif_badge_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool loading = true;
  List items = [];
  final titleCtrl = TextEditingController();
  String priority = 'medium'; // low medium high
  String filter = 'all'; // all | pending | done

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('tasks');
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        items = [];
      } else if (res.data is Map && res.data['items'] is List) {
        items = List.from(res.data['items'] as List);
      } else {
        items = [];
      }
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _add() async {
    final text = titleCtrl.text.trim();
    if (text.isEmpty) {
      showErr(context, 'عنوان کار را وارد کنید');
      return;
    }
    try {
      final res = await context.read<AuthService>().api.dio.post('tasks', data: {
        'title': text,
        'priority': priority,
        'done': false,
      });
      if ((res.statusCode ?? 0) >= 400) {
        showErr(context, 'ثبت نشد');
        return;
      }
      titleCtrl.clear();
      if (res.data is Map && res.data['items'] is List) {
        items = List.from(res.data['items'] as List);
      } else {
        await _load();
      try { await context.read<NotifBadgeService>().refresh(context.read<AuthService>()); } catch (_) {}
      }
      // به‌روزرسانی فوری عدد اعلان
      try {
        await context.read<NotifBadgeService>().refresh(context.read<AuthService>());
      } catch (_) {}
      if (mounted) {
        setState(() {});
        showOk(context, 'ثبت شد');
      }
    } catch (e) {
      showErr(context, e.toString());
    }
  }

  Future<void> _toggle(Map m) async {
    final id = m['id'];
    final wasDone = m['done'] == true;
    setState(() {
      items = items.map((e) {
        final mm = Map<String, dynamic>.from(e as Map);
        if (mm['id'] == id) mm['done'] = !wasDone;
        return mm;
      }).toList();
    });
    try {
      final res = await context.read<AuthService>().api.dio.post('tasks/action', data: {
        'action': 'toggle',
        'id': id,
      });
      if (res.data is Map && res.data['items'] is List) {
        items = List.from(res.data['items'] as List);
        if (mounted) setState(() {});
      }
    } catch (_) {
      await _load();
      try { await context.read<NotifBadgeService>().refresh(context.read<AuthService>()); } catch (_) {}
    }
  }

  Future<void> _delete(Map m) async {
    final id = m['id'];
    try {
      await context.read<AuthService>().api.dio.post('tasks/action', data: {
        'action': 'delete',
        'id': id,
      });
      items = items.where((e) => (e as Map)['id'] != id).toList();
      if (mounted) {
        setState(() {});
        showOk(context, 'حذف شد');
      }
    } catch (_) {
      await _load();
      try { await context.read<NotifBadgeService>().refresh(context.read<AuthService>()); } catch (_) {}
    }
  }

  List get _filtered {
    return items.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final done = m['done'] == true;
      if (filter == 'done') return done;
      if (filter == 'pending') return !done;
      return true;
    }).toList();
  }

  int get _doneCount => items.where((e) => (e as Map)['done'] == true).length;
  int get _pendingCount => items.length - _doneCount;

  Color _prioColor(String p) {
    switch (p) {
      case 'high':
        return AppColors.red;
      case 'low':
        return AppColors.cyan;
      default:
        return AppColors.purple;
    }
  }

  String _prioLabel(String p) {
    switch (p) {
      case 'high':
        return 'فوری';
      case 'low':
        return 'کم';
      default:
        return 'عادی';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'کارهای من',
          subtitle: '$_doneCount از ${items.length} انجام‌شده',
          leadingIcon: Icons.checklist_rtl_rounded,
          leadingColor: AppColors.blue,
          onRefresh: _load,
        ),
        // فرم افزودن — مثل موکاپ
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: NeonCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'عنوان کار جدید...',
                  hintStyle: TextStyle(color: AppColors.textMute),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _prioChip('فوری', 'high'),
                const SizedBox(width: 6),
                _prioChip('عادی', 'medium'),
                const SizedBox(width: 6),
                _prioChip('کم', 'low'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('ثبت'),
                ),
              ]),
            ]),
          ),
        ),
        // فیلتر همه / امروز سبک
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Expanded(child: _filterChip('همه', 'all', items.length, AppColors.purple)),
            const SizedBox(width: 8),
            Expanded(child: _filterChip('در صف انجام', 'pending', _pendingCount, AppColors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _filterChip('انجام شد', 'done', _doneCount, AppColors.green)),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : list.isEmpty
                  ? const Center(child: Text('کاری ثبت نشده', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final m = Map<String, dynamic>.from(list[i] as Map);
                          final done = m['done'] == true;
                          final title = m['title']?.toString() ?? '';
                          final p = (m['priority']?.toString() ?? 'medium');
                          final pc = _prioColor(p);
                          final date = m['created']?.toString() ?? m['date']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(children: [
                                GestureDetector(
                                  onTap: () => _toggle(m),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: done ? AppColors.green : AppColors.textMute, width: 2),
                                      color: done ? AppColors.green.withOpacity(0.2) : Colors.transparent,
                                    ),
                                    child: done
                                        ? const Icon(Icons.check, size: 14, color: AppColors.green)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: done ? AppColors.textMute : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        decoration: done ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: pc.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_prioLabel(p), style: TextStyle(color: pc, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (done ? AppColors.green : AppColors.orange).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          done ? 'انجام شد' : 'در صف انجام',
                                          style: TextStyle(
                                            color: done ? AppColors.green : AppColors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (date.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(date, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                                        ),
                                      ],
                                    ]),
                                  ]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                                  onPressed: () => _delete(m),
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

  Widget _prioChip(String label, String val) {
    final sel = priority == val;
    return GestureDetector(
      onTap: () => setState(() => priority = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: sel ? AppColors.purple.withOpacity(0.3) : const Color(0xFF0B1230),
          border: Border.all(color: sel ? AppColors.purple : const Color(0xFF1E2A55)),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _filterChip(String label, String val, int n, Color c) {
    final sel = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: NeonCard(
        borderColor: sel ? c : null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(children: [
          Text('$n', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        ]),
      ),
    );
  }
}
