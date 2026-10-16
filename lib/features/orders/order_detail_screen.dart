import '../../core/utils/shamsi_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';
import 'invoice_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> order;
  bool loading = false;
  bool saving = false;
  List<Map<String, dynamic>> statusList = [];

  static const _colorMap = {
    'pending': Color(0xFFF59E0B),
    'processing': Color(0xFF3B82F6),
    'on-hold': Color(0xFF8B5CF6),
    'completed': Color(0xFF10B981),
    'cancelled': Color(0xFFEF4444),
    'refunded': Color(0xFFEF4444),
    'failed': Color(0xFFEF4444),
  };

  Color _statusColor(String key, String group) {
    if (_colorMap.containsKey(key)) return _colorMap[key]!;
    if (group == 'cod24') return const Color(0xFF06B6D4);
    if (group == 'basalam') return const Color(0xFFF472B6);
    if (group == 'torob') return const Color(0xFFA78BFA);
    return const Color(0xFF94A3B8);
  }

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
    _loadFull();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('orders/statuses');
      if (res.data is Map && res.data['statuses'] is List) {
        statusList = (res.data['statuses'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _loadFull() async {
    final id = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    setState(() => loading = true);
    final auth = context.read<AuthService>();
    final full = await context.read<OrdersService>().fetchOrder(auth, id);
    if (full != null && mounted) {
      setState(() {
        order = full;
        loading = false;
      });
    } else if (mounted) {
      setState(() => loading = false);
    }
  }


  Future<void> _deleteOrder() async {
    final id = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    final isManual = order['is_manual'] == true || order['is_manual'] == 1 ||
        order['_fy_manual'] == 1 || (order['created_via']?.toString() ?? '').contains('manual');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121E42),
        title: const Text('حذف سفارش؟', style: TextStyle(color: Colors.white)),
        content: Text(
          isManual ? 'این سفارش دستی برای همیشه حذف می‌شود.' : 'سفارش به سطل زباله منتقل می‌شود.',
          style: const TextStyle(color: Color(0xFF9AA9CC)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => saving = true);
    try {
      final auth = context.read<AuthService>();
      await auth.api.dio.delete('orders/$id', queryParameters: {'force': isManual});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('سفارش حذف شد'),
          backgroundColor: Color(0xFF065F46),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حذف نشد: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ));
      }
    }
    if (mounted) setState(() => saving = false);
  }

  String _fmt(dynamic v) {
    if (v == null) return '۰';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Map<String, dynamic> _addr(String key) {
    final a = order[key];
    if (a is Map) return Map<String, dynamic>.from(a);
    return {};
  }

  String _name() {
    final c = order['customer'];
    if (c is Map) {
      final n = c['name']?.toString() ?? '';
      if (n.isNotEmpty) return n;
    }
    final b = _addr('billing');
    final n = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
    return n.isEmpty ? 'مشتری' : n;
  }

  String _phone() {
    final c = order['customer'];
    if (c is Map && (c['phone']?.toString().isNotEmpty ?? false)) return c['phone'].toString();
    return _addr('billing')['phone']?.toString() ?? '';
  }

  String _fullAddress() {
    final s = _addr('shipping');
    final b = _addr('billing');
    final parts = <String>[
      s['state']?.toString() ?? b['state']?.toString() ?? '',
      s['city']?.toString() ?? b['city']?.toString() ?? '',
      s['address_1']?.toString() ?? b['address_1']?.toString() ?? '',
      s['address_2']?.toString() ?? b['address_2']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' | ');
  }

  List<Map<String, dynamic>> _items() {
    final line = order['line_items'] ?? order['items'];
    if (line is List) {
      return line.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> _changeStatus(String status) async {
    final id = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    setState(() => saving = true);
    final ok = await context.read<OrdersService>().updateStatus(context.read<AuthService>(), id, status);
    if (mounted) {
      setState(() {
        saving = false;
        if (ok) order['status'] = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'وضعیت به‌روز شد' : 'خطا در ذخیره')));
    }
  }

  Future<void> _call() async {
    final p = _phone();
    if (p.isEmpty) return;
    final uri = Uri.parse('tel:$p');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _wa() async {
    var p = _phone().replaceAll(RegExp(r'[^0-9]'), '');
    if (p.startsWith('0')) p = '98${p.substring(1)}';
    final uri = Uri.parse('https://wa.me/$p');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }


  Future<void> _openCod24() async {
    final id = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    try {
      final res = await context.read<AuthService>().api.dio.get('cod24/meta', queryParameters: {'order_id': id});
      if (res.data is! Map || res.data['available'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('افزونه COD24 روی سایت فعال نیست')));
        }
        return;
      }
      final cartons = Map<String, dynamic>.from(res.data['cartons'] as Map? ?? {});
      final weightCtrl = TextEditingController(text: '${res.data['default_weight'] ?? 0}');
      String carton = cartons.keys.isNotEmpty ? cartons.keys.first : '1';
      final content = res.data['content']?.toString() ?? '';
      final actions = (res.data['actions_initial'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      String action = actions.isNotEmpty ? actions.first['key'].toString() : 'add';

      if (!mounted) return;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0F172A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setS) {
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('ارسال به پنل COD24', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'وزن کل سفارش (گرم)', labelStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: carton,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(labelText: 'سایز بسته‌بندی', labelStyle: TextStyle(color: Colors.white54)),
                    items: cartons.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                    onChanged: (v) => setS(() => carton = v ?? carton),
                  ),
                  const SizedBox(height: 12),
                  const Text('محتوای بسته', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(content.isEmpty ? '—' : content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: action,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(labelText: 'عملیات', labelStyle: TextStyle(color: Colors.white54)),
                    items: actions.map((a) => DropdownMenuItem(value: a['key'].toString(), child: Text(a['label'].toString(), style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setS(() => action = v ?? action),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                    child: const Text('ارسال به پنل COD24'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                ]),
              ),
            );
          });
        },
      );
      if (ok == true && mounted) {
        final sub = await context.read<AuthService>().api.dio.post('cod24/submit', data: {
          'order_id': id,
          'action': action,
          'weight': int.tryParse(weightCtrl.text) ?? 0,
          'carton_size': carton,
        });
        final msg = sub.data is Map ? (sub.data['message']?.toString() ?? 'انجام شد') : 'انجام شد';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          await _loadFull();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString().replaceFirst('wc-', '') ?? '';
    Map<String, dynamic>? stMatch;
    for (final s in statusList) {
      if (s['key']?.toString() == status) { stMatch = s; break; }
    }
    final rawStatus = status.toLowerCase();
    String statusLabel = stMatch?['label']?.toString() ?? order['status_label']?.toString() ?? status;
    // اگر انگلیسی بود فارسی کن
    final faMap = {
      'completed': 'تکمیل شده', 'processing': 'در حال انجام', 'pending': 'در انتظار پرداخت',
      'on-hold': 'در انتظار بررسی', 'cancelled': 'لغو شده', 'refunded': 'مسترد شده', 'failed': 'ناموفق',
    };
    if (faMap.containsKey(rawStatus)) statusLabel = faMap[rawStatus]!;
    else {
      statusLabel = statusLabel
          .replaceAll(RegExp(r'basalam', caseSensitive: false), 'باسلام')
          .replaceAll(RegExp(r'torob', caseSensitive: false), 'ترب')
          .replaceAll(RegExp(r'pending', caseSensitive: false), 'در انتظار')
          .replaceAll(RegExp(r'processing', caseSensitive: false), 'در حال انجام')
          .replaceAll(RegExp(r'completed', caseSensitive: false), 'تکمیل شده');
    }
    final statusColor = _statusColor(status, stMatch?['group']?.toString() ?? '');
    final shipTitle = order['shipping_method_title']?.toString() ?? '';
    final payTitle = order['payment_method_title']?.toString() ?? order['payment_method']?.toString() ?? '';

    return Scaffold(


      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'فاکتور',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(order: order))),
          ),
        ],
        backgroundColor: const Color(0xFF1A1B2E),
        title: Text('سفارش #${order['number'] ?? order['id'] ?? ''}', style: const TextStyle(fontSize: 16)),
      ),
      body: loading
          ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF))))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if ((order['date_created_jalali'] ?? order['date_created'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: const Color(0xFF252640),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF9B7BFF), size: 18),
                          const SizedBox(width: 10),
                          const Text('تاریخ سفارش', style: TextStyle(color: Color(0xFF9A9AB5), fontSize: 12)),
                          const Spacer(),
                          Text(formatAnyDate(order['date_created_jalali'] ?? order['date_created']),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                // status
                Material(
                  color: const Color(0xFF252640),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: saving
                        ? null
                        : () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              backgroundColor: const Color(0xFF0F172A),
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (ctx) {
                                final groups = <String, List<Map<String, dynamic>>>{};
                                for (final s in statusList) {
                                  final g = s['group']?.toString() ?? 'custom';
                                  groups.putIfAbsent(g, () => []).add(s);
                                }
                                final shipG = order['shipping_group']?.toString() ?? '';
                                final orderG = shipG == 'cod24'
                                    ? ['cod24', 'woocommerce', 'basalam', 'torob', 'custom']
                                    : shipG == 'basalam'
                                        ? ['basalam', 'woocommerce', 'cod24', 'torob', 'custom']
                                        : ['woocommerce', 'cod24', 'basalam', 'torob', 'custom'];
                                final titles = {
                                  'woocommerce': 'وضعیت ووکامرس',
                                  'cod24': 'COD24 / ارسال',
                                  'basalam': 'باسلام',
                                  'torob': 'ترب',
                                  'custom': 'سایر',
                                };
                                return SafeArea(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text('تغییر وضعیت سفارش', textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        ...orderG.where((g) => groups.containsKey(g)).expand((g) {
                                          final items = groups[g]!;
                                          return [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                              child: Text(titles[g] ?? g, style: TextStyle(color: _statusColor('', g), fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                            ...items.map((s) {
                                              final key = s['key']?.toString() ?? '';
                                              final label = s['label']?.toString() ?? key;
                                              final c = _statusColor(key, s['group']?.toString() ?? '');
                                              return ListTile(
                                                title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                                trailing: status == key ? Icon(Icons.check_circle, color: c, size: 20) : null,
                                                onTap: () => Navigator.pop(ctx, key),
                                              );
                                            }),
                                          ];
                                        }),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            if (selected != null) await _changeStatus(selected);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(Icons.sync_alt, color: statusColor, size: 20),
                        const SizedBox(width: 10),
                        const Text('وضعیت: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (saving)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                        else
                          const Icon(Icons.expand_more, color: Colors.white38),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // customer + call
                _card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_name(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_phone().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text(_phone(), style: const TextStyle(color: Colors.white54), textDirection: TextDirection.ltr)),
                        IconButton(icon: const Icon(Icons.phone, color: Color(0xFF10B981)), onPressed: _call),
                        IconButton(icon: const Icon(Icons.chat, color: Color(0xFF25D366)), onPressed: _wa),
                      ]),
                    ],
                    if (_fullAddress().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('آدرس: ${_fullAddress()}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    ],
                    if ((_addr('shipping')['postcode'] ?? _addr('billing')['postcode'] ?? '').toString().isNotEmpty)
                      Builder(builder: (_) {
                        final post = _addr('shipping')['postcode'] ?? _addr('billing')['postcode'];
                        return Text('کدپستی: $post', style: const TextStyle(color: Colors.white38, fontSize: 12));
                      }),
                  ]),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('حمل و پرداخت', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    if ((order['shipping_group']?.toString() == 'cod24') || (order['shipping_method']?.toString() ?? '').toLowerCase().contains('cod24') || (order['shipping_method_title']?.toString() ?? '').contains('COD24') || (order['shipping_method_title']?.toString() ?? '').contains('پیشتاز'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          onPressed: _openCod24,
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: const Text('پنل COD24 / بسته‌بندی'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF06B6D4), side: const BorderSide(color: Color(0xFF06B6D4))),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _row('روش ارسال', shipTitle.isEmpty ? '—' : shipTitle),
                    _row('روش پرداخت', payTitle.isEmpty ? '—' : payTitle),
                  ]),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(children: [
                    _row('مبلغ محصولات', '${_fmt(order['subtotal'] ?? order['total'])} تومان'),
                    _row('هزینه ارسال', '${_fmt(order['shipping_total'])} تومان'),
                    _row('تخفیف', '${_fmt(order['discount_total'])} تومان'),
                    const Divider(color: Colors.white12),
                    _row('جمع کل', '${_fmt(order['total'])} تومان', bold: true, valueColor: const Color(0xFF10B981)),
                  ]),
                ),
                if (_items().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _card(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('اقلام سفارش', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      ..._items().map((item) {
                        final qty = item['quantity'] ?? 1;
                        final lineTotal = item['total'] ?? item['subtotal'] ?? item['price'];
                        final unit = item['price'] ?? item['subtotal'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('تعداد: $qty', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 12),
                              if (unit != null)
                                Text('فی: ${_fmt(unit)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              const Spacer(),
                              Text('${_fmt(lineTotal)} تومان', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ]),
                        );
                      }),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(14)),
        child: child,
      );

  Widget _row(String label, dynamic value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Text(value?.toString() ?? '—',
            style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}
