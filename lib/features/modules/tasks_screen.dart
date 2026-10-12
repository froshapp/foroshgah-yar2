import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';
import '../../core/utils/shamsi_picker.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool loading = true;
  List items = [];
  final titleCtrl = TextEditingController();
  String priority = 'normal';
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
        if (mounted) showErr(context, 'خطا در بارگذاری ($code)');
      } else if (res.data is Map && res.data['items'] is List) {
        items = List.from(res.data['items'] as List);
      } else {
        items = [];
      }
    } catch (e) {
      items = [];
      if (mounted) showErr(context, 'خطا در بارگذاری کارها');
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
      final pri = (priority == 'normal') ? 'medium' : priority;
      final res = await context.read<AuthService>().api.dio.post('tasks', data: {
        'title': text,
        'priority': pri,
        'done': false,
      });
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        final msg = (res.data is Map) ? (res.data['message'] ?? res.data['code'] ?? code) : code;
        showErr(context, 'ثبت نشد ($msg)');
        return;
      }
      titleCtrl.clear();
      if (res.data is Map && res.data['items'] is List) {
        items = List.from(res.data['items'] as List);
        if (mounted) setState(() {});
      } else {
        await _load();
      }
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
    }
  }

  Future<void> _delete(Map m) async {
    final id = m['id'];
    setState(() {
      items = items.where((e) => (e as Map)['id'] != id).toList();
    });
    try {
      await context.read<AuthService>().api.dio.post('tasks/action', data: {
        'action': 'delete',
        'id': id,
      });
      showOk(context, 'حذف شد');
    } catch (_) {
      await _load();
    }
  }

  List get _filtered {
    if (filter == 'done') return items.where((e) => (e as Map)['done'] == true).toList();
    if (filter == 'pending') return items.where((e) => (e as Map)['done'] != true).toList();
    return items;
  }

  int get _doneCount => items.where((e) => (e as Map)['done'] == true).length;
  int get _pendingCount => items.length - _doneCount;

  Color _priColor(String p) {
    switch (p) {
      case 'high': return AppColors.red;
      case 'low': return AppColors.cyan;
      default: return AppColors.purpleGlow;
    }
  }

  String _priLabel(String p) {
    switch (p) {
      case 'high': return 'فوری';
      case 'low': return 'کم';
      case 'medium':
      case 'normal':
      default: return 'عادی';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(showSettingsGear: false, 
          title: 'کارهای من',
          subtitle: '$_doneCount از ${items.length} انجام‌شده',
          leadingIcon: Icons.checklist_rtl_rounded,
          leadingColor: AppColors.blue,
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    NeonCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'عنوان کار جدید...',
                            hintStyle: TextStyle(color: AppColors.textMute),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          _priChip('high', 'فوری'),
                          const SizedBox(width: 6),
                          _priChip('normal', 'عادی'),
                          const SizedBox(width: 6),
                          _priChip('low', 'کم'),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _add,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('ثبت'),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      _filterChip('all', 'همه', items.length),
                      const SizedBox(width: 8),
                      _filterChip('pending', 'در صف انجام', _pendingCount),
                      const SizedBox(width: 8),
                      _filterChip('done', 'انجام شد', _doneCount),
                    ]),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('کاری ثبت نشده', style: TextStyle(color: AppColors.textDim))),
                      )
                    else
                      ...list.map((e) {
                        final m = Map<String, dynamic>.from(e as Map);
                        final doneItem = m['done'] == true;
                        final pri = m['priority']?.toString() ?? 'normal';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NeonCard(
                            child: Row(children: [
                              GestureDetector(
                                onTap: () => _toggle(m),
                                child: Icon(
                                  doneItem ? Icons.check_circle : Icons.circle_outlined,
                                  color: doneItem ? AppColors.green : AppColors.textMute,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    m['title']?.toString() ?? '',
                                    style: TextStyle(
                                      color: doneItem ? AppColors.textDim : Colors.white,
                                      decoration: doneItem ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _priColor(pri).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_priLabel(pri), style: TextStyle(color: _priColor(pri), fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (doneItem ? AppColors.green : AppColors.orange).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        doneItem ? 'انجام شد' : 'در صف انجام',
                                        style: TextStyle(
                                          color: doneItem ? AppColors.green : AppColors.orange,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    if ((m['created'] ?? m['date'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Flexible(child: Text(formatAnyDate(m['created'] ?? m['date']), style: const TextStyle(color: AppColors.textMute, fontSize: 10), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ]),
                                ]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                                onPressed: () => _delete(m),
                              ),
                            ]),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _priChip(String key, String label) {
    final sel = priority == key;
    return GestureDetector(
      onTap: () => setState(() => priority = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.purple.withOpacity(0.25) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? AppColors.purple : AppColors.cardBorder),
        ),
        child: Text(label, style: TextStyle(color: sel ? AppColors.purpleGlow : AppColors.textDim, fontSize: 12)),
      ),
    );
  }

  Widget _filterChip(String key, String label, int n) {
    final sel = filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.purple.withOpacity(0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.purple.withOpacity(0.5) : AppColors.cardBorder),
          ),
          child: Column(children: [
            Text('$n', style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: sel ? AppColors.purpleGlow : AppColors.textMute, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
