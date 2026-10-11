import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

class InvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const InvoiceScreen({super.key, required this.order});
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool printing = false;
  Map<String, dynamic> inv = {};

  Map<String, dynamic> get order => widget.order;

  @override
  void initState() {
    super.initState();
    _loadInv();
  }

  Future<void> _loadInv() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('settings/invoice');
      if (res.data is Map && mounted) setState(() => inv = Map<String, dynamic>.from(res.data as Map));
    } catch (_) {}
  }

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
      if (raw is String && raw.isNotEmpty) dt = DateTime.tryParse(raw);
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

  Future<void> _print() async {
    setState(() => printing = true);
    try {
      final auth = context.read<AuthService>();
      final site = inv['store_name']?.toString().isNotEmpty == true ? inv['store_name'].toString() : (auth.site?['name']?.toString() ?? 'فروشگاه');
      final num = order['number'] ?? order['id'] ?? '';
      final b = _billing();
      final name = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
      final name2 = name.isNotEmpty ? name : (b['name']?.toString() ?? order['customer_name']?.toString() ?? '—');
      final phone = b['phone']?.toString() ?? '';
      final address = [b['state'], b['city'], b['address_1'], b['address_2']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join('، ');
      final date = order['date_jalali'] ?? _jalali(order['date_created'] ?? order['date']);
      final items = _items();
      final total = order['total'];
      final shipping = order['shipping_total'] ?? order['shipping'];

      final font = await PdfGoogleFonts.notoNaskhArabicRegular();
      final fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(site, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('فاکتور فروش', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('شماره: $num'),
                  pw.Text('تاریخ: $date'),
                ]),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('خریدار: $name2'),
                    if (phone.isNotEmpty) pw.Text('موبایل: $phone'),
                    if (address.isNotEmpty) pw.Text('آدرس: $address'),
                  ]),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('محصول')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('تعداد')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('مبلغ')),
                    ]),
                    ...items.map((it) {
                      final m = Map<String, dynamic>.from(it as Map);
                      return pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m['name']?.toString() ?? '—')),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${m['quantity'] ?? 1}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_fmt(m['total'] ?? m['subtotal'] ?? m['price']))),
                      ]);
                    }),
                  ],
                ),
                pw.SizedBox(height: 12),
                if (shipping != null && shipping.toString() != '0')
                  pw.Text('هزینه ارسال: ${_fmt(shipping)}'),
                pw.SizedBox(height: 6),
                pw.Text('جمع کل: ${_fmt(total)} تومان', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text('با تشکر از خرید شما', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (e) {
      if (mounted) showErr(context, 'خطا در چاپ: $e');
    }
    if (mounted) setState(() => printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final site = inv['store_name']?.toString().isNotEmpty == true ? inv['store_name'].toString() : (auth.site?['name']?.toString() ?? 'فروشگاه');
    final num = order['number'] ?? order['id'] ?? '';
    final b = _billing();
    final name = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
    final name2 = name.isNotEmpty ? name : (b['name']?.toString() ?? order['customer_name']?.toString() ?? '—');
    final phone = b['phone']?.toString() ?? '';
    final address = [b['state'], b['city'], b['address_1'], b['address_2']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join('، ');
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
            onPressed: () {
              final buf = StringBuffer()
                ..writeln(site)
                ..writeln('فاکتور #$num')
                ..writeln('تاریخ: $date')
                ..writeln('خریدار: $name2');
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('شماره: $num', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                Text('تاریخ: $date', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('خریدار: $name2', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (phone.isNotEmpty) Text('موبایل: $phone', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)), textDirection: TextDirection.ltr),
                  if (address.isNotEmpty) Text('آدرس: $address', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4)),
                ]),
              ),
              const SizedBox(height: 16),
              ...items.map((it) {
                final m = Map<String, dynamic>.from(it as Map);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(m['name']?.toString() ?? '—', style: const TextStyle(fontSize: 13))),
                    Text('×${m['quantity'] ?? 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(width: 12),
                    Text(_fmt(m['total'] ?? m['subtotal']), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
              const Divider(),
              if (shipping != null && shipping.toString() != '0' && shipping.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Text('ارسال', style: TextStyle(color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text(_fmt(shipping)),
                  ]),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Text('جمع کل', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                  const Spacer(),
                  Text('${_fmt(total)} تومان', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                ]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: printing ? null : _print,
            icon: printing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print_outlined),
            label: Text(printing ? 'در حال آماده‌سازی...' : 'چاپ / PDF'),
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
