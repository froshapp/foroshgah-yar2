import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'customers_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  bool loading = true;
  bool available = false;
  String message = '';
  String providerLabel = '';
  List tickets = [];
  String filter = 'all'; // all | open | answered | closed

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final api = context.read<AuthService>().api;
      final st = await api.dio.get('tickets/status');
      if (st.data is Map) {
        available = st.data['available'] == true;
        providerLabel = st.data['label']?.toString() ?? '';
        message = st.data['message']?.toString() ?? '';
      }
      if (available) {
        final res = await api.dio.get('tickets', queryParameters: {'per_page': 50});
        if (res.data is Map) {
          if (res.data['available'] == false) {
            available = false;
            message = res.data['message']?.toString() ?? message;
          }
          tickets = res.data['tickets'] is List ? res.data['tickets'] as List : [];
        }
      } else {
        message = message.isEmpty
            ? 'یکی از افزونه‌های تیکت پشتیبانی را روی سایت نصب و فعال کنید.'
            : message;
      }
    } catch (e) {
      available = false;
      message = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  String _statusKey(Map m) {
    final s = (m['status'] ?? m['status_label'] ?? '').toString().toLowerCase();
    if (s.contains('close') || s.contains('بسته') || s.contains('حل')) return 'closed';
    if (s.contains('answer') || s.contains('پاسخ') || s.contains('reply')) return 'answered';
    return 'open';
  }

  List get _filtered {
    if (filter == 'all') return tickets;
    return tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == filter).toList();
  }

  Color _statusColor(String k) {
    switch (k) {
      case 'closed': return AppColors.textMute;
      case 'answered': return AppColors.green;
      default: return AppColors.red;
    }
  }

  String _statusLabel(String k) {
    switch (k) {
      case 'closed': return 'بسته شده';
      case 'answered': return 'پاسخ داده شده';
      default: return 'جدید';
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == 'open').length;
    final answered = tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == 'answered').length;
    final closed = tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == 'closed').length;
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'تیکت و پشتیبانی',
          subtitle: providerLabel.isNotEmpty ? providerLabel : 'پاسخگویی به درخواست‌های مشتریان',
          leadingIcon: Icons.headset_mic_rounded,
          leadingColor: const Color(0xFFA78BFA),
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : !available
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDim)),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          Row(children: [
                            Expanded(child: _statChip('همه', tickets.length, filter == 'all', AppColors.purple, () => setState(() => filter = 'all'))),
                            const SizedBox(width: 8),
                            Expanded(child: _statChip('در حال بررسی', open, filter == 'open', AppColors.orange, () => setState(() => filter = 'open'))),
                            const SizedBox(width: 8),
                            Expanded(child: _statChip('پاسخ‌داده‌شده', answered, filter == 'answered', AppColors.green, () => setState(() => filter = 'answered'))),
                          ]),
                          const SizedBox(height: 12),
                          if (list.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('تیکتی یافت نشد', style: TextStyle(color: AppColors.textDim))),
                            )
                          else
                            ...list.map((e) {
                              final m = Map<String, dynamic>.from(e as Map);
                              final sk = _statusKey(m);
                              final id = m['id'] ?? m['number'] ?? '';
                              final title = m['title']?.toString() ?? m['subject']?.toString() ?? 'بدون عنوان';
                              final user = m['customer_name']?.toString() ?? m['user_name']?.toString() ?? m['author']?.toString() ?? '';
                              final ago = m['ago']?.toString() ?? m['date']?.toString() ?? '';
                              final customerId = int.tryParse('${m['customer_id'] ?? m['user_id'] ?? 0}') ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: AppColors.card,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      builder: (_) => Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                          Text('#$id — $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 8),
                                          Text(user, style: const TextStyle(color: AppColors.textDim)),
                                          if ((m['content'] ?? m['message'] ?? '').toString().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text((m['content'] ?? m['message']).toString(), style: const TextStyle(color: Colors.white70, height: 1.5)),
                                          ],
                                          const SizedBox(height: 16),
                                          if (customerId > 0)
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: {
                                                  'id': customerId,
                                                  'name': user,
                                                  'phone': m['phone'] ?? '',
                                                  'email': m['email'] ?? '',
                                                  'avatar': m['avatar'] ?? '',
                                                  'billing_address': '',
                                                })));
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
                                              child: const Text('مدیریت مشتری'),
                                            ),
                                        ]),
                                      ),
                                    );
                                  },
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Text('#$id', style: const TextStyle(color: AppColors.purpleGlow, fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ]),
                                        const SizedBox(height: 6),
                                        if (user.isNotEmpty) Text(user, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                        if (ago.isNotEmpty) Text(ago, style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(sk).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(_statusLabel(sk), style: TextStyle(color: _statusColor(sk), fontSize: 11)),
                                        ),
                                      ]),
                                    ),
                                    const Icon(Icons.chevron_left, color: AppColors.textMute),
                                  ]),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _statChip(String label, int n, bool sel, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? c.withOpacity(0.6) : AppColors.cardBorder),
        ),
        child: Column(children: [
          Text('$n', style: TextStyle(color: sel ? c : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: sel ? c : AppColors.textDim, fontSize: 10), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
