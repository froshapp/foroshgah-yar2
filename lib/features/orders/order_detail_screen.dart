import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';

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

  static const statuses = [
    ('pending', 'در انتظار پرداخت', Color(0xFFF59E0B)),
    ('processing', 'در حال انجام', Color(0xFF3B82F6)),
    ('on-hold', 'در انتظار بررسی', Color(0xFF8B5CF6)),
    ('completed', 'تکمیل شده', Color(0xFF10B981)),
    ('cancelled', 'لغو شده', Color(0xFFEF4444)),
    ('refunded', 'مسترد شده', Color(0xFFEF4444)),
    ('failed', 'ناموفق', Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
    _loadFull();
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

  Map<String, dynamic> _billing() {
    final b = order['billing'];
    if (b is Map) return Map<String, dynamic>.from(b);
    return {};
  }

  Map<String, dynamic> _shipping() {
    final s = order['shipping'];
    if (s is Map) return Map<String, dynamic>.from(s);
    return {};
  }

  String _name() {
    final c = order['customer'];
    if (c is Map) {
      final n = c['name']?.toString() ?? '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
      if (n.isNotEmpty) return n;
    }
    final b = _billing();
    final n = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
    return n.isEmpty ? 'مشتری' : n;
  }

  String _phone() {
    final c = order['customer'];
    if (c is Map && c['phone'] != null) return c['phone'].toString();
    return _billing()['phone']?.toString() ?? '';
  }

  String _address() {
    final s = _shipping();
    final b = _billing();
    final parts = <String>[
      s['state']?.toString() ?? b['state']?.toString() ?? '',
      s['city']?.toString() ?? b['city']?.toString() ?? '',
      s['address_1']?.toString() ?? b['address_1']?.toString() ?? '',
      s['address_2']?.toString() ?? b['address_2']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' | ');
  }

  List<Map<String, dynamic>> _items() {
    final line = order['line_items'] ?? order['items'] ?? order['products'];
    if (line is List) {
      return line.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> _changeStatus(String status) async {
    final id = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    setState(() => saving = true);
    final auth = context.read<AuthService>();
    final ok = await context.read<OrdersService>().updateStatus(auth, id, status);
    if (mounted) {
      setState(() {
        saving = false;
        if (ok) order['status'] = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'وضعیت به‌روز شد' : 'خطا در ذخیره')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? '';
    final statusInfo = statuses.firstWhere((s) => s.$1 == status, orElse: () => (status, status, Colors.white54));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        title: Text('سفارش #${order['id'] ?? ''}', style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: _MiniLoader())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status button
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
                              backgroundColor: const Color(0xFF252640),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (ctx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تغییر وضعیت سفارش',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ...statuses.map((s) => ListTile(
                                            title: Text(s.$2, style: TextStyle(color: s.$3, fontWeight: FontWeight.w600)),
                                            trailing: status == s.$1
                                                ? Icon(Icons.check, color: s.$3)
                                                : null,
                                            onTap: () => Navigator.pop(ctx, s.$1),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            if (selected != null) await _changeStatus(selected);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.sync_alt, color: statusInfo.$3, size: 20),
                          const SizedBox(width: 10),
                          const Text('وضعیت سفارش: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          Text(statusInfo.$2,
                              style: TextStyle(color: statusInfo.$3, fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          if (saving)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                          else
                            const Icon(Icons.expand_more, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Customer
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_phone().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_phone(), style: const TextStyle(color: Colors.white54, fontSize: 13), textDirection: TextDirection.ltr),
                      ],
                      if (_address().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('آدرس: ${_address()}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      ],
                      if ((_shipping()['postcode'] ?? _billing()['postcode']) != null) ...[
                        const SizedBox(height: 4),
                        Text('کدپستی: ${_shipping()['postcode'] ?? _billing()['postcode']}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Shipping / payment
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('حمل و پرداخت', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      _row('روش ارسال', order['shipping_method_title'] ?? order['shipping_lines'] is List && (order['shipping_lines'] as List).isNotEmpty
                          ? ((order['shipping_lines'] as List).first is Map
                              ? (order['shipping_lines'] as List).first['method_title']
                              : null)
                          : order['shipping_total']),
                      _row('روش پرداخت', order['payment_method_title'] ?? order['payment_method'] ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Costs
                _card(
                  child: Column(
                    children: [
                      _row('محصولات', _fmt(order['total'] ?? order['subtotal'])),
                      _row('حمل و نقل', _fmt(order['shipping_total'])),
                      _row('تخفیف', _fmt(order['discount_total'])),
                      const Divider(color: Colors.white12),
                      _row('جمع کل', _fmt(order['total']), bold: true, valueColor: const Color(0xFF10B981)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Line items
                if (_items().isNotEmpty)
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('محصولات', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        ..._items().map((item) {
                          final name = item['name']?.toString() ?? '—';
                          final qty = item['quantity'] ?? 1;
                          final total = item['total'] ?? item['price'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                Text('×$qty', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                const SizedBox(width: 12),
                                Text(_fmt(total), style: const TextStyle(color: Color(0xFF10B981), fontSize: 13)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _row(String label, dynamic value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            value?.toString() ?? '—',
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF)),
    );
  }
}
