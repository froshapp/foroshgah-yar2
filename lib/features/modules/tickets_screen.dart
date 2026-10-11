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
        final res = await api.dio.get('tickets', queryParameters: {'per_page': 30});
        if (res.data is Map) {
          if (res.data['available'] == false) {
            available = false;
            message = res.data['message']?.toString() ?? message;
          }
          tickets = res.data['tickets'] is List ? res.data['tickets'] as List : [];
        }
      } else {
        message = message.isEmpty
            ? 'یکی از افزونه‌های تیکت پشتیبانی (مثل مهرنوش، Awesome Support، Support Candy) را روی سایت نصب و فعال کنید.'
            : message;
      }
    } catch (e) {
      available = false;
      message = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('تیکت و پشتیبانی', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
        actions: [if (available) IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: MiniLoader())
          : !available
              ? _disabled()
              : tickets.isEmpty
                  ? Center(child: Text('تیکتی ثبت نشده\n($providerLabel)', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tickets.length,
                        itemBuilder: (_, i) {
                          final t = Map<String, dynamic>.from(tickets[i] as Map);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => TicketDetailPage(id: int.tryParse(t['id'].toString()) ?? 0),
                              )).then((_) => _load()),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('#${t['number'] ?? t['id']} — ${t['title'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(t['customer'] is Map ? (t['customer']['name']?.toString() ?? 'کاربر #${t['customer']['id'] ?? ''}') : 'کاربر نامشخص', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                  if (t['customer'] is Map && t['customer']['id'] != null)
                                    TextButton(
                                      onPressed: () {
                                        final c = Map<String, dynamic>.from(t['customer'] as Map);
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: c)));
                                      },
                                      child: const Text('مدیریت مشتری', style: TextStyle(fontSize: 11, color: AppColors.purpleGlow)),
                                    ),
                                  Text(t['updated_at']?.toString() ?? '', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(t['status_label']?.toString() ?? t['status']?.toString() ?? '', style: const TextStyle(color: AppColors.purpleGlow, fontSize: 11)),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _disabled() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.support_agent, size: 56, color: AppColors.textMute.withOpacity(0.5)),
        const SizedBox(height: 16),
        const Text('ماژول تیکت غیرفعال است', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          message.isNotEmpty
              ? message
              : 'برای فعال‌سازی، یکی از افزونه‌های تیکت پشتیبانی را روی وردپرس نصب کنید:\n• مهرنوش تیکت\n• Awesome Support\n• Support Candy\n• نیر وب / وردپرس‌یار',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textDim, height: 1.5),
        ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: _load, child: const Text('بررسی مجدد')),
      ]),
    );
  }
}

class TicketDetailPage extends StatefulWidget {
  final int id;
  const TicketDetailPage({super.key, required this.id});
  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  bool loading = true;
  Map? ticket;
  final replyCtrl = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('tickets/${widget.id}');
      if (res.data is Map && res.data['ticket'] is Map) {
        ticket = Map<String, dynamic>.from(res.data['ticket'] as Map);
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _send() async {
    if (replyCtrl.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await context.read<AuthService>().api.dio.post('tickets/${widget.id}', data: {'content': replyCtrl.text.trim()});
      replyCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final replies = ticket?['replies'] is List ? ticket!['replies'] as List : [];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(ticket != null ? '#${ticket!['number'] ?? widget.id}' : 'تیکت', style: const TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(child: MiniLoader())
          : ticket == null
              ? const Center(child: Text('بارگذاری نشد', style: TextStyle(color: AppColors.textDim)))
              : Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        NeonCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(ticket!['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(ticket!['content']?.toString() ?? ticket!['excerpt']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        const Text('پاسخ‌ها', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...replies.map((r) {
                          final m = Map<String, dynamic>.from(r as Map);
                          final staff = m['is_staff'] == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NeonCard(
                              borderColor: staff ? AppColors.purple.withOpacity(0.35) : null,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['author']?.toString() ?? '', style: TextStyle(color: staff ? AppColors.purpleGlow : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(m['content']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                                Text(m['date']?.toString() ?? '', style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                              ]),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'پاسخ...',
                              hintStyle: const TextStyle(color: AppColors.textMute),
                              filled: true,
                              fillColor: AppColors.card,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: sending ? null : _send,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, minimumSize: const Size(56, 48)),
                          child: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                        ),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}
