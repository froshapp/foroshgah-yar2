import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shamsi_picker.dart';

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
  String filter = 'all'; // all | hold | approve

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await context.read<AuthService>().api.dio.get('reviews', queryParameters: {
        'per_page': 50,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF4C8DFF),
      Color(0xFFF472B6),
      Color(0xFF2EE6A6),
      Color(0xFFA78BFA),
      Color(0xFFFF9F43),
      Color(0xFF06B6D4),
    ];
    final i = name.hashCode.abs() % colors.length;
    return colors[i];
  }

  String _statusLabel(String s) {
    if (s == 'approve' || s == 'approved') return 'پاسخ داده شده';
    if (s == 'spam') return 'اسپم';
    return 'در انتظار پاسخ';
  }

  Color _statusColor(String s) {
    if (s == 'approve' || s == 'approved') return AppColors.green;
    if (s == 'spam') return AppColors.red;
    return AppColors.purpleGlow;
  }

  void _openDetail(Map r) {
    final id = int.tryParse('${r['id']}') ?? 0;
    final status = r['status']?.toString() ?? '';
    final author = r['author']?.toString() ?? 'کاربر';
    final color = _avatarColor(author);
    final letter = author.isNotEmpty ? author.substring(0, 1) : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMute, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(letter, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    if ((r['product_name'] ?? '').toString().isNotEmpty)
                      Text(r['product_name'].toString(), style: const TextStyle(color: AppColors.textDim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                if (r['rating'] != null)
                  Text('★ ${r['rating']}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 14),
              NeonCard(
                child: Text(r['content']?.toString() ?? '', style: const TextStyle(color: Colors.white70, height: 1.5)),
              ),
              const SizedBox(height: 12),
              Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(children: [
                if (status != 'approve' && status != 'approved')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _moderate(id, 'approve');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green.withOpacity(0.2),
                        foregroundColor: AppColors.green,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('تأیید'),
                    ),
                  ),
                if (status != 'approve' && status != 'approved') const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _moderate(id, 'spam');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red.withOpacity(0.15),
                      foregroundColor: AppColors.red,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('اسپم'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = int.tryParse('${counts['all'] ?? reviews.length}') ?? reviews.length;
    final hold = int.tryParse('${counts['hold'] ?? 0}') ?? 0;
    final approve = int.tryParse('${counts['approve'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'پرسش و پاسخ مشتریان',
          subtitle: 'مدیریت سوالات و نظرات کاربران',
          leadingIcon: Icons.chat_bubble_rounded,
          leadingColor: const Color(0xFF2DD4BF),
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        // فیلترهای بالای لیست — سبک مرجع
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(children: [
            Expanded(child: _topFilter('همه', 'all', all, AppColors.purple)),
            const SizedBox(width: 8),
            Expanded(child: _topFilter('پاسخ داده شده', 'approve', approve, AppColors.cyan)),
            const SizedBox(width: 8),
            Expanded(child: _topFilter('در انتظار پاسخ', 'hold', hold, AppColors.orange)),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: AppColors.red), textAlign: TextAlign.center)))
                  : reviews.isEmpty
                      ? const Center(child: Text('نظری یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                            itemCount: reviews.length,
                            itemBuilder: (_, i) {
                              final r = Map<String, dynamic>.from(reviews[i] as Map);
                              final author = r['author']?.toString() ?? 'کاربر';
                              final status = r['status']?.toString() ?? '';
                              final color = _avatarColor(author);
                              final letter = author.isNotEmpty ? author.substring(0, 1) : '?';
                              final ago = r['ago']?.toString() ?? r['date']?.toString() ?? '';
                              final content = r['content']?.toString() ?? '';
                              final product = r['product_name']?.toString() ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  onTap: () => _openDetail(r),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // آواتار رنگی
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.28),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: color.withOpacity(0.55)),
                                          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
                                        ),
                                        child: Text(letter, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Row(children: [
                                            Expanded(
                                              child: Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                            ),
                                            if (ago.isNotEmpty)
                                              Text(formatAnyDate(ago), style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_left, color: AppColors.textMute, size: 18),
                                          ]),
                                          if (product.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(product, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            content,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.35),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: _statusColor(status).withOpacity(0.35)),
                                              ),
                                              child: Text(
                                                _statusLabel(status),
                                                style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            if (r['rating'] != null) ...[
                                              const Spacer(),
                                              Text('★ ${r['rating']}', style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                          ]),
                                        ]),
                                      ),
                                    ],
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

  Widget _topFilter(String label, String val, int count, Color c) {
    final sel = filter == val;
    return GestureDetector(
      onTap: () {
        setState(() => filter = val);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.18) : AppColors.card.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? c.withOpacity(0.55) : AppColors.cardBorder.withOpacity(0.5)),
          boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.2), blurRadius: 12)] : null,
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(color: sel ? c : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: sel ? c : AppColors.textDim, fontSize: 10)),
        ]),
      ),
    );
  }
}
