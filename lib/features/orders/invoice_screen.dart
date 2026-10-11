import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const InvoiceScreen({super.key, required this.order});

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _jalali(dynamic raw) {
    try {
      DateTime? dt;
      if (raw is String && raw.isNotEmpty) {
        dt = DateTime.tryParse(raw);
      }
      dt ??= DateTime.now();
      final j = Jalali.fromDateTime(dt);
      return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw?.toString() ?? '';
    }
  }

  List _items() {
    final i = order['items'] ?? order['line_items'];
    if (i is List) return i;
    return [];
  }

  Map _billing() {
    final b = order['billing'] ?? order['customer'];
    if (b is Map) return Map<String, dynamic>.from(b);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final site = auth.site?['name']?.toString() ?? 'فروشگاه';
    final num = order['number'] ?? order['id'] ?? '';
    final b = _billing();
    final name = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
    final name2 = name.isNotEmpty ? name : (b['name']?.toString() ?? order['customer_name']?.toString() ?? '—');
    final phone = b['phone']?.toString() ?? '';
    final address = [
      b['state'],
      b['city'],
      b['address_1'],
      b['address_2'],
    ].where((e) => e != null && e.toString().isNotEmpty).join('، ');
    final date = order['date_jalali'] ?? _jalali(order['date_created'] ?? order['date']);
    final items = _items();
    final total = order['total'];
    final shipping = order['shipping_total'] ?? order['shipping'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('فاکتور سفارش', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'کپی متن',
            onPressed: () {
              final buf = StringBuffer();
              buf.writeln(site);
              buf.writeln('فاکتور #$num');
              buf.writeln('تاریخ: $date');
              buf.writeln('خریدار: $name2');
              if (phone.isNotEmpty) buf.writeln('موبایل: $phone');
              if (address.isNotEmpty) buf.writeln('آدرس: $address');
              buf.writeln('---');
              for (final it in items) {
                final m = Map<String, dynamic>.from(it as Map);
                buf.writeln('${m['name']} | تعداد ${m['quantity']} | ${_fmt(m['total'] ?? m['subtotal'])}');
              }
              buf.writeln('جمع کل: ${_fmt(total)}');
              Clipboard.setData(ClipboardData(text: buf.toString()));
              showOk(context, 'کپی شد');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(site, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              const Text('فاکتور فروش', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('شماره: $num', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                  Text('تاریخ: $date', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('خریدار: $name2', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                  if (phone.isNotEmpty) Text('موبایل: $phone', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)), textDirection: TextDirection.ltr),
                  if (address.isNotEmpty) Text('آدرس: $address', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4)),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Row(children: [
                      Expanded(flex: 4, child: Text('محصول', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('تعداد', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('مبلغ', textAlign: TextAlign.left, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ]),
                  ),
                  ...items.map((it) {
                    final m = Map<String, dynamic>.from(it as Map);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                      child: Row(children: [
                        Expanded(flex: 4, child: Text(m['name']?.toString() ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
                        Expanded(flex: 1, child: Text('${m['quantity'] ?? 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text(_fmt(m['total'] ?? m['subtotal'] ?? m['price']), textAlign: TextAlign.left, style: const TextStyle(fontSize: 12))),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 14),
              if (shipping != null && shipping.toString() != '0' && shipping.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Text('هزینه ارسال', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text(_fmt(shipping), style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Text('جمع کل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                  const Spacer(),
                  Text('${_fmt(total)} تومان', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('با تشکر از خرید شما', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // کاربر می‌تواند از منوی اشتراک‌گذاری سیستم / اسکرین‌شات چاپ کند
              showOk(context, 'فاکتور آماده است — از اشتراک‌گذاری سیستم چاپ کنید');
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('آماده چاپ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
