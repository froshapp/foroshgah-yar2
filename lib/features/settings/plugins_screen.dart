import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});
  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  bool loading = true;
  String? error;
  List plugins = [];
  int activeCount = 0;
  final search = TextEditingController();
  String? toggling;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('plugins');
      if (res.data is Map) {
        plugins = res.data['plugins'] is List ? res.data['plugins'] as List : [];
        activeCount = int.tryParse('${res.data['active'] ?? 0}') ?? 0;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _toggle(Map m) async {
    final file = m['file']?.toString() ?? '';
    final next = !(m['active'] == true);
    setState(() => toggling = file);
    try {
      final res = await context.read<AuthService>().api.dio.post('plugins/toggle', data: {
        'file': file,
        'active': next,
      });
      final msg = res.data is Map ? (res.data['message']?.toString() ?? 'انجام شد') : 'انجام شد';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => toggling = null);
  }

  List get filtered {
    final q = search.text.trim();
    if (q.isEmpty) return plugins;
    return plugins.where((p) {
      if (p is! Map) return false;
      return '${p['name'] ?? ''} ${p['file'] ?? ''}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('افزونه‌های سایت', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: NeonCard(
            child: Row(children: [
              const Icon(Icons.extension, color: AppColors.purpleGlow),
              const SizedBox(width: 10),
              Expanded(child: Text('$activeCount فعال از ${plugins.length} افزونه', style: const TextStyle(color: Colors.white))),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجوی افزونه...',
              hintStyle: const TextStyle(color: AppColors.textMute),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMute),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: AppColors.red), textAlign: TextAlign.center)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final m = Map<String, dynamic>.from(list[i] as Map);
                          final active = m['active'] == true;
                          final file = m['file']?.toString() ?? '';
                          final busy = toggling == file;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NeonCard(
                              borderColor: active ? AppColors.green.withOpacity(0.35) : null,
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m['name']?.toString() ?? file, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 3),
                                    Text('v${m['version'] ?? ''} • ${active ? 'فعال' : 'غیرفعال'}',
                                        style: TextStyle(color: active ? AppColors.green : AppColors.textMute, fontSize: 11)),
                                  ]),
                                ),
                                if (busy)
                                  const SizedBox(width: 24, height: 24, child: MiniLoader(size: 20))
                                else
                                  Switch(
                                    value: active,
                                    activeColor: AppColors.green,
                                    onChanged: (_) => _toggle(m),
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
}
