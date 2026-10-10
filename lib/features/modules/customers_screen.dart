import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool loading = true;
  String? error;
  List customers = [];
  final search = TextEditingController();
  String filter = 'all';

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

  Future<void> _load({String? q}) async {
    setState(() { loading = true; error = null; });
    try {
      final auth = context.read<AuthService>();
      final res = await auth.api.dio.get('customers', queryParameters: {
        'per_page': 50,
        if (q != null && q.isNotEmpty) 'search': q,
      });
      if (res.data is Map && res.data['customers'] is List) {
        customers = res.data['customers'] as List;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  List get filtered {
    if (filter == 'active') {
      return customers.where((c) => (c is Map && (int.tryParse(c['order_count']?.toString() ?? '0') ?? 0) > 0)).toList();
    }
    if (filter == 'inactive') {
      return customers.where((c) => (c is Map && (int.tryParse(c['order_count']?.toString() ?? '0') ?? 0) == 0)).toList();
    }
    return customers;
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final total = customers.length;
    final active = customers.where((c) => c is Map && (int.tryParse(c['order_count']?.toString() ?? '0') ?? 0) > 0).length;
    final inactive = total - active;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('مدیریت مشتریان', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Expanded(child: _top('کل', '$total', AppColors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _top('فعال', '$active', AppColors.green)),
            const SizedBox(width: 8),
            Expanded(child: _top('جدید/بدون خرید', '$inactive', AppColors.orange)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجوی مشتری...',
              hintStyle: const TextStyle(color: AppColors.textMute),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMute),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            onSubmitted: (v) => _load(q: v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _fchip('همه', 'all'),
            _fchip('فعال', 'active'),
            _fchip('غیرفعال', 'inactive'),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : list.isEmpty
                      ? const Center(child: Text('مشتری یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: () => _load(q: search.text),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final c = Map<String, dynamic>.from(list[i] as Map);
                              final phone = c['phone']?.toString() ?? '';
                              final orders = int.tryParse(c['order_count']?.toString() ?? '0') ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => CustomerDetailPage(customer: c),
                                    ));
                                  },
                                  child: Row(children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.purple.withOpacity(0.2),
                                      child: Text(
                                        (c['name']?.toString() ?? '?').isNotEmpty ? c['name'].toString()[0] : '?',
                                        style: const TextStyle(color: AppColors.purpleGlow),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: AppColors.textDim, fontSize: 12), textDirection: TextDirection.ltr),
                                      Text('$orders سفارش', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                    ])),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (orders > 0 ? AppColors.green : AppColors.textMute).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(orders > 0 ? 'فعال' : 'جدید', style: TextStyle(color: orders > 0 ? AppColors.green : AppColors.textMute, fontSize: 11)),
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

  Widget _top(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.35),
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(t, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        ]),
      );

  Widget _fchip(String label, String val) {
    final sel = filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12)),
        selected: sel,
        selectedColor: AppColors.purple.withOpacity(0.45),
        backgroundColor: AppColors.card,
        onSelected: (_) => setState(() => filter = val),
      ),
    );
  }
}

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final phone = customer['phone']?.toString() ?? '';
    final email = customer['email']?.toString() ?? '';
    final orders = customer['order_count'] ?? 0;
    final reg = customer['registered']?.toString() ?? '—';
    final level = (int.tryParse(orders.toString()) ?? 0) >= 5
        ? 'ویژه'
        : (int.tryParse(orders.toString()) ?? 0) >= 1
            ? 'عادی'
            : 'جدید';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(customer['name']?.toString() ?? 'مشتری', style: const TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonCard(
            borderColor: AppColors.purple.withOpacity(0.35),
            child: Column(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.purple.withOpacity(0.25),
                child: Text(
                  (customer['name']?.toString() ?? '?').isNotEmpty ? customer['name'].toString()[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
              const SizedBox(height: 10),
              Text(customer['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('سطح: $level', style: const TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _row(Icons.phone, 'موبایل', phone.isEmpty ? '—' : phone, phone.isNotEmpty
              ? () async {
                  final u = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(u)) await launchUrl(u);
                }
              : null),
          _row(Icons.email_outlined, 'ایمیل', email.isEmpty ? '—' : email, null),
          _row(Icons.shopping_bag_outlined, 'تعداد سفارشات', '$orders', null),
          _row(Icons.calendar_today_outlined, 'تاریخ عضویت', reg, null),
          const SizedBox(height: 8),
          NeonCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('آدرس پیش‌فرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('از اطلاعات صورتحساب سفارشات خوانده می‌شود. برای ویرایش کامل از پنل وردپرس استفاده کنید.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonCard(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: AppColors.purpleGlow, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ])),
          if (onTap != null) const Icon(Icons.chevron_left, color: AppColors.textMute),
        ]),
      ),
    );
  }
}
