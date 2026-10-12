import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';
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
  List tickets = [];
  String filter = 'all';

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
    if (s.contains('close') || s.contains('بسته') || s.contains('حل') || s.contains('trash')) return 'closed';
    if (s.contains('answer') || s.contains('پاسخ') || s.contains('reply')) return 'answered';
    return 'open';
  }

  List get _filtered {
    if (filter == 'all') return tickets;
    return tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final open = tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == 'open').length;
    final answered = tickets.where((e) => _statusKey(Map<String, dynamic>.from(e as Map)) == 'answered').length;
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'تیکت و پشتیبانی',
          subtitle: 'پاسخگویی به درخواست‌های مشتریان',
          leadingIcon: Icons.headset_mic_rounded,
          leadingColor: const Color(0xFFA78BFA),
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : !available
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDim))))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          Row(children: [
                            Expanded(child: _chip('همه', tickets.length, 'all', AppColors.purple)),
                            const SizedBox(width: 8),
                            Expanded(child: _chip('باز', open, 'open', AppColors.orange)),
                            const SizedBox(width: 8),
                            Expanded(child: _chip('پاسخ‌داده‌شده', answered, 'answered', AppColors.green)),
                          ]),
                          const SizedBox(height: 12),
                          if (list.isEmpty)
                            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('تیکتی یافت نشد', style: TextStyle(color: AppColors.textDim)))),
                          ...list.map((e) {
                            final m = Map<String, dynamic>.from(e as Map);
                            final id = m['id'];
                            final title = m['title']?.toString() ?? 'بدون عنوان';
                            final user = m['customer'] is Map ? (m['customer']['name']?.toString() ?? '') : (m['customer_name']?.toString() ?? '');
                            final sk = _statusKey(m);
                            final sc = sk == 'closed' ? AppColors.textMute : (sk == 'answered' ? AppColors.green : AppColors.orange);
                            final sl = sk == 'closed' ? 'بسته' : (sk == 'answered' ? 'پاسخ‌داده‌شده' : 'باز');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NeonCard(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TicketDetailPage(ticketId: id, preview: m)),
                                  );
                                  _load();
                                },
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text('#$id', style: const TextStyle(color: AppColors.purpleGlow, fontWeight: FontWeight.w700, fontSize: 13)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: sc.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                      child: Text(sl, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  if (user.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(user, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                  ],
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

  Widget _chip(String label, int n, String val, Color c) {
    final sel = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: NeonCard(
        borderColor: sel ? c : null,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(children: [
          Text('$n', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        ]),
      ),
    );
  }
}

class TicketDetailPage extends StatefulWidget {
  final dynamic ticketId;
  final Map preview;
  const TicketDetailPage({super.key, required this.ticketId, required this.preview});
  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  bool loading = true;
  Map? ticket;
  String? error;
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
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('tickets/${widget.ticketId}');
      if ((res.statusCode ?? 0) >= 400) {
        error = (res.data is Map) ? '${res.data['message'] ?? res.statusCode}' : 'خطا';
        ticket = Map<String, dynamic>.from(widget.preview);
      } else if (res.data is Map && res.data['ticket'] is Map) {
        ticket = Map<String, dynamic>.from(res.data['ticket'] as Map);
      } else if (res.data is Map) {
        ticket = Map<String, dynamic>.from(res.data as Map);
      } else {
        ticket = Map<String, dynamic>.from(widget.preview);
      }
    } catch (e) {
      error = e.toString();
      ticket = Map<String, dynamic>.from(widget.preview);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _reply() async {
    final text = replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    try {
      final res = await context.read<AuthService>().api.dio.post(
        'tickets/${widget.ticketId}',
        data: {'content': text},
      );
      if ((res.statusCode ?? 0) >= 400) {
        showErr(context, 'ارسال نشد');
      } else {
        replyCtrl.clear();
        showOk(context, 'پاسخ ارسال شد');
        await _load();
      }
    } catch (e) {
      showErr(context, '$e');
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = ticket ?? widget.preview;
    final title = t['title']?.toString() ?? 'تیکت';
    final content = t['content']?.toString() ?? t['excerpt']?.toString() ?? '';
    final replies = t['replies'] is List ? t['replies'] as List : [];
    final customer = t['customer'] is Map ? t['customer'] as Map : {};
    final custName = customer['name']?.toString() ?? '';
    final custId = customer['id'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: '#${widget.ticketId}',
          subtitle: title,
          leadingIcon: Icons.confirmation_number_outlined,
          leadingColor: AppColors.purple,
          storeOpensSettings: false,
          onRefresh: _load,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(error!, style: const TextStyle(color: AppColors.orange, fontSize: 11)),
                      ),
                    NeonCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (custName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.textDim),
                            const SizedBox(width: 6),
                            Text(custName, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                            if (custId != null) ...[
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => CustomerDetailPage(customer: {
                                      'id': custId,
                                      'name': custName,
                                      'email': '',
                                      'phone': '',
                                    }),
                                  ));
                                },
                                child: const Text('پروفایل مشتری', style: TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
                              ),
                            ],
                          ]),
                        ],
                        if (content.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(content, style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.5)),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 14),
                    const Text('پاسخ‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (replies.isEmpty)
                      const NeonCard(child: Text('هنوز پاسخی نیست', style: TextStyle(color: AppColors.textDim)))
                    else
                      ...replies.map((r) {
                        final rm = Map<String, dynamic>.from(r as Map);
                        final staff = rm['is_staff'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NeonCard(
                            borderColor: staff ? AppColors.purple : null,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(rm['author']?.toString() ?? '', style: TextStyle(color: staff ? AppColors.purpleGlow : AppColors.textDim, fontWeight: FontWeight.w600, fontSize: 12)),
                                const Spacer(),
                                Text(rm['date']?.toString() ?? '', style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                              ]),
                              const SizedBox(height: 6),
                              Text(rm['content']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                            ]),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    NeonCard(
                      child: Column(children: [
                        TextField(
                          controller: replyCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'پاسخ خود را بنویسید...',
                            hintStyle: TextStyle(color: AppColors.textMute),
                            border: InputBorder.none,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: sending ? null : _reply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: sending ? const MiniLoader(size: 18) : const Text('ارسال پاسخ'),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}
