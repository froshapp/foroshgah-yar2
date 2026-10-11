import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
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
  int done = 0;
  final titleCtrl = TextEditingController();
  String priority = 'medium';

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
      if (res.data is Map) {
        items = res.data['items'] is List ? res.data['items'] as List : [];
        done = int.tryParse('${res.data['done'] ?? 0}') ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _add() async {
    final t = titleCtrl.text.trim();
    if (t.isEmpty) {
      showErr(context, 'عنوان کار را بنویسید');
      return;
    }
    try {
      final res = await context.read<AuthService>().api.dio.post('tasks', data: {
        'title': t,
        'priority': priority,
      });
      titleCtrl.clear();
      if (res.data is Map && res.data['items'] is List) {
        setState(() {
          items = res.data['items'] as List;
          done = items.where((e) => (e as Map)['done'] == true).length;
        });
      } else {
        await _load();
      }
      if (mounted) showOk(context, 'ثبت شد');
    } catch (e) {
      if (mounted) showErr(context, 'خطا در ثبت');
    }
  }

  Future<void> _delete(Map m) async {
    try {
      final res = await context.read<AuthService>().api.dio.post('tasks/action', data: {'action': 'delete', 'id': m['id']});
      if (res.data is Map && res.data['items'] is List) {
        setState(() {
          items = res.data['items'] as List;
          done = items.where((e) => (e as Map)['done'] == true).length;
        });
      } else {
        await _load();
      }
      if (mounted) showOk(context, 'حذف شد');
    } catch (e) {
      if (mounted) showErr(context, 'خطا در حذف');
    }
  }

  Future<void> _toggle(Map m) async {
    try {
      await context.read<AuthService>().api.dio.post('tasks/action', data: {'action': 'toggle', 'id': m['id']});
      await _load();
    } catch (_) {}
  }

  Color _priColor(String p) {
    switch (p) {
      case 'high': return AppColors.red;
      case 'low': return AppColors.green;
      default: return AppColors.orange;
    }
  }

  String _priLabel(String p) {
    switch (p) {
      case 'high': return 'بالا';
      case 'low': return 'پایین';
      default: return 'متوسط';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'کارهای من',
          subtitle: '$done از ${items.length} انجام‌شده',
                    onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: NeonCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'عنوان کار جدید...',
                  hintStyle: TextStyle(color: AppColors.textMute),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _priChip('low', 'پایین'),
                const SizedBox(width: 6),
                _priChip('medium', 'متوسط'),
                const SizedBox(width: 6),
                _priChip('high', 'بالا'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('ثبت'),
                ),
              ]),
            ]),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : items.isEmpty
                  ? const Center(child: Text('کاری ثبت نشده', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final m = Map<String, dynamic>.from(items[i] as Map);
                          final doneItem = m['done'] == true;
                          final pri = m['priority']?.toString() ?? 'medium';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NeonCard(
                              child: InkWell(
                                onTap: () => _toggle(m),
                                child: Row(children: [
                                  Icon(doneItem ? Icons.check_circle : Icons.circle_outlined,
                                      color: doneItem ? AppColors.green : AppColors.textMute),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(m['title']?.toString() ?? '',
                                          style: TextStyle(
                                            color: doneItem ? AppColors.textDim : Colors.white,
                                            decoration: doneItem ? TextDecoration.lineThrough : null,
                                          )),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _priColor(pri).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_priLabel(pri), style: TextStyle(color: _priColor(pri), fontSize: 11)),
                                      ),
                                    ]),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                                    onPressed: () => _delete(m),
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

  Widget _priChip(String key, String label) {
    final sel = priority == key;
    return GestureDetector(
      onTap: () => setState(() => priority = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _priColor(key).withOpacity(0.25) : AppColors.cardBorder.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? _priColor(key) : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: sel ? _priColor(key) : AppColors.textDim, fontSize: 11)),
      ),
    );
  }
}
