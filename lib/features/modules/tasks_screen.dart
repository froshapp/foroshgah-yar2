import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

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
    if (titleCtrl.text.trim().isEmpty) return;
    try {
      await context.read<AuthService>().api.dio.post('tasks', data: {
        'title': titleCtrl.text.trim(),
        'priority': priority,
      });
      titleCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggle(Map m) async {
    try {
      await context.read<AuthService>().api.dio.put('tasks/${m['id']}', data: {
        'done': !(m['done'] == true),
      });
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
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('کارهای من', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$done / ${items.length}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeonCard(
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'افزودن کار جدید...',
                        hintStyle: TextStyle(color: AppColors.textMute),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: priority,
                    dropdownColor: AppColors.card,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('پایین', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'medium', child: Text('متوسط', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'high', child: Text('بالا', style: TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                    onChanged: (v) => setState(() => priority = v ?? 'medium'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                    child: const Text('ثبت'),
                  ),
                ]),
              ]),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : RefreshIndicator(
                    color: AppColors.purple,
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(children: const [SizedBox(height: 80), Center(child: Text('کاری ثبت نشده', style: TextStyle(color: AppColors.textDim)))])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final m = Map<String, dynamic>.from(items[i] as Map);
                              final doneItem = m['done'] == true;
                              final pr = m['priority']?.toString() ?? 'medium';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NeonCard(
                                  onTap: () => _toggle(m),
                                  child: Row(children: [
                                    Icon(doneItem ? Icons.check_circle : Icons.circle_outlined,
                                        color: doneItem ? AppColors.green : AppColors.textMute),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        m['title']?.toString() ?? '',
                                        style: TextStyle(
                                          color: doneItem ? AppColors.textDim : Colors.white,
                                          decoration: doneItem ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _priColor(pr).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_priLabel(pr), style: TextStyle(color: _priColor(pr), fontSize: 11)),
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
