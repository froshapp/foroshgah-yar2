import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool loading = true;
  String? error;
  List reviews = [];
  Map counts = {};
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('reviews', queryParameters: {
        'per_page': 40,
        'status': filter == 'all' ? 'all' : filter,
      });
      if (res.data is Map) {
        reviews = res.data['reviews'] is List ? res.data['reviews'] as List : [];
        counts = res.data['counts'] is Map ? Map<String, dynamic>.from(res.data['counts'] as Map) : {};
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _moderate(int id, String action) async {
    try {
      await context.read<AuthService>().api.dio.post('reviews/$id', data: {'action': action});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      
      body: Column(children: [
          GlassHeader(title: 'نظرات محصولات', actions: [
            IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white70), onPressed: () => Navigator.pop(context)),
          ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Expanded(child: _stat('همه', '${counts['all'] ?? '—'}', AppColors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _stat('در انتظار', '${counts['hold'] ?? '—'}', AppColors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _stat('تأیید', '${counts['approve'] ?? '—'}', AppColors.green)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _chip('همه', 'all'),
            _chip('در انتظار', 'hold'),
            _chip('تأیید شده', 'approve'),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : reviews.isEmpty
                      ? const Center(child: Text('نظری یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: reviews.length,
                            itemBuilder: (_, i) {
                              final r = Map<String, dynamic>.from(reviews[i] as Map);
                              final id = int.tryParse(r['id'].toString()) ?? 0;
                              final status = r['status']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(r['product_name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                      if (r['rating'] != null)
                                        Text('${r['rating']}★', style: const TextStyle(color: AppColors.orange, fontSize: 12)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(r['author']?.toString() ?? '', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Text(r['content']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      if (status != 'approve')
                                        TextButton(onPressed: () => _moderate(id, 'approve'), child: const Text('تأیید', style: TextStyle(color: AppColors.green, fontSize: 12))),
                                      if (status == 'approve')
                                        TextButton(onPressed: () => _moderate(id, 'hold'), child: const Text('در انتظار', style: TextStyle(color: AppColors.orange, fontSize: 12))),
                                      TextButton(onPressed: () => _moderate(id, 'spam'), child: const Text('اسپم', style: TextStyle(color: AppColors.red, fontSize: 12))),
                                    ]),
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

  Widget _stat(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.35),
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        ]),
      );

  Widget _chip(String label, String val) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12)),
        selected: sel,
        selectedColor: AppColors.purple.withOpacity(0.4),
        backgroundColor: AppColors.card,
        onSelected: (_) { setState(() => filter = val); _load(); },
      ),
    );
  }
}
