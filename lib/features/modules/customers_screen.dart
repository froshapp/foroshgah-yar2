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
  int totalCustomers = 0;
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
      final res = await context.read<AuthService>().api.dio.get('customers', queryParameters: {
        'per_page': 80,
        if (q != null && q.isNotEmpty) 'search': q,
      });
      if (res.data is Map && res.data['customers'] is List) {
        customers = res.data['customers'] as List;
        totalCustomers = int.tryParse('${res.data['total'] ?? customers.length}') ?? customers.length;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  List get filtered {
    final q = search.text.trim();
    Iterable list = customers;
    if (filter == 'active') {
      list = list.where((c) => c is Map && (int.tryParse('${c['order_count'] ?? 0}') ?? 0) > 0);
    } else if (filter == 'inactive') {
      list = list.where((c) => c is Map && (int.tryParse('${c['order_count'] ?? 0}') ?? 0) == 0);
    }
    if (q.isNotEmpty) {
      list = list.where((c) {
        if (c is! Map) return false;
        final blob = '${c['name'] ?? ''} ${c['phone'] ?? ''} ${c['email'] ?? ''}';
        return blob.contains(q);
      });
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final total = customers.length;
    final active = customers.where((c) => c is Map && (int.tryParse('${c['order_count'] ?? 0}') ?? 0) > 0).length;
    final neu = customers.where((c) {
      if (c is! Map) return false;
      final r = c['registered_jalali']?.toString() ?? '';
      // تقریبی: اگر تاریخ عضویت اخیر در لیست باشد به‌عنوان جدید
      return (int.tryParse('${c['order_count'] ?? 0}') ?? 0) <= 1;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          GlassHeader(
            title: 'مدیریت مشتریان',
            subtitle: 'کل: $totalCustomers',
            showBack: true,
            onRefresh: _load,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: _stat('کل مشتریان', '$total', AppColors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _stat('دارای سفارش', '$active', AppColors.cyan)),
              const SizedBox(width: 8),
              Expanded(child: _stat('مشتریان جدید', '$neu', AppColors.purpleGlow)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: search,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'جستجوی مشتری...',
                hintStyle: const TextStyle(color: AppColors.textMute),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMute),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => _load(q: v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              _chip('همه', 'all'),
              _chip('دارای سفارش', 'active'),
              _chip('بدون سفارش', 'inactive'),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : error != null
                    ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                    : RefreshIndicator(
                        color: AppColors.purple,
                        onRefresh: _load,
                        child: list.isEmpty
                            ? ListView(children: [SizedBox(height: 120), Center(child: Text('مشتری‌ای یافت نشد', style: TextStyle(color: AppColors.textDim)))])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final m = Map<String, dynamic>.from(list[i] as Map);
                                  final activeC = (int.tryParse('${m['order_count'] ?? 0}') ?? 0) > 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: NeonCard(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => CustomerDetailPage(customer: m),
                                      )).then((_) => _load()),
                                      child: Row(children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(colors: [AppColors.purple.withOpacity(0.5), AppColors.blue.withOpacity(0.4)]),
                                          ),
                                          child: (m['avatar']?.toString().isNotEmpty == true)
                          ? ClipOval(child: Image.network(m['avatar'].toString(), width: 40, height: 40, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white70, size: 22)))
                          : const Icon(Icons.person, color: Colors.white70, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(m['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 3),
                                            Text(m['phone']?.toString().isNotEmpty == true ? m['phone'].toString() : (m['email']?.toString() ?? ''),
                                                style: const TextStyle(color: AppColors.textDim, fontSize: 12), textDirection: TextDirection.ltr),
                                          ]),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (activeC ? AppColors.green : AppColors.textMute).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(activeC ? 'دارای سفارش' : 'بدون سفارش',
                                              style: TextStyle(color: activeC ? const Color(0xFF6EE7B7) : AppColors.textMute, fontSize: 11)),
                                        ),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String t, String v, Color c) => NeonCard(
        borderColor: c.withOpacity(0.35),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(children: [
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
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
        selectedColor: AppColors.purple.withOpacity(0.45),
        backgroundColor: AppColors.card,
        onSelected: (_) => setState(() => filter = val),
      ),
    );
  }
}

class CustomerDetailPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailPage({super.key, required this.customer});
  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late TextEditingController phone;
  late TextEditingController address;
  bool saving = false;
  bool loadingOrders = true;
  List orders = [];

  @override
  void initState() {
    super.initState();
    phone = TextEditingController(text: widget.customer['phone']?.toString() ?? '');
    address = TextEditingController(text: widget.customer['billing_address']?.toString() ?? '');
    _loadOrders();
  }

  @override
  void dispose() {
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => loadingOrders = true);
    try {
      final id = widget.customer['id'];
      final res = await context.read<AuthService>().api.dio.get('customers/$id/orders');
      if (res.data is Map && res.data['orders'] is List) {
        orders = res.data['orders'] as List;
      }
    } catch (_) {}
    if (mounted) setState(() => loadingOrders = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final id = widget.customer['id'];
      await context.read<AuthService>().api.dio.post('customers/$id', data: {
        'phone': phone.text.trim(),
        'billing': {'address_1': address.text.trim()},
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final name = c['name']?.toString() ?? '—';
    final reg = c['registered_jalali']?.toString().isNotEmpty == true
        ? c['registered_jalali'].toString()
        : (c['registered']?.toString() ?? '—');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(name, style: const TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: saving ? null : _save, child: saving ? const MiniLoader(size: 18) : const Text('ذخیره', style: TextStyle(color: AppColors.purpleGlow))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.purple.withOpacity(0.6), AppColors.blue.withOpacity(0.5)]),
                ),
                child: (m['avatar']?.toString().isNotEmpty == true)
                ? ClipOval(child: Image.network(m['avatar'].toString(), width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 36)))
                : const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('سطح: عادی', style: TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          NeonCard(
            child: Column(children: [
              _editRow(Icons.phone, 'موبایل', phone, ltr: true),
              const Divider(color: Colors.white10),
              _editRow(Icons.location_on_outlined, 'آدرس', address),
              const Divider(color: Colors.white10),
              Row(children: [
                const Icon(Icons.calendar_today, color: AppColors.textMute, size: 18),
                const SizedBox(width: 10),
                const Text('تاریخ عضویت', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                const Spacer(),
                Text(reg, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('سفارشات اخیر', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (loadingOrders)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: MiniLoader()))
          else if (orders.isEmpty)
            const NeonCard(child: Text('سفارشی ثبت نشده', style: TextStyle(color: AppColors.textDim)))
          else
            ...orders.map((o) {
              final m = Map<String, dynamic>.from(o as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NeonCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#${m['number'] ?? m['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(m['date_jalali']?.toString() ?? m['date']?.toString() ?? '', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                        Text(
                          (m['product_names']?.toString().isNotEmpty == true)
                              ? m['product_names'].toString()
                              : '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                        ),
                      ]),
                    ),
                    Text(m['status_label']?.toString() ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('${m['total'] ?? ''}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
          const SizedBox(height: 12),
          if ((c['phone']?.toString() ?? '').isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${c['phone']}')),
              icon: const Icon(Icons.call),
              label: const Text('تماس'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
            ),
        ],
      ),
    );
  }

  Widget _editRow(IconData icon, String label, TextEditingController ctrl, {bool ltr = false}) {
    return Row(children: [
      Icon(icon, color: AppColors.textMute, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
            border: InputBorder.none,
          ),
        ),
      ),
    ]);
  }
}
