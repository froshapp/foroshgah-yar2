import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/shamsi_picker.dart';

Color avatarColor(dynamic id) {
  final colors = [
    const Color(0xFF7C6CFF),
    const Color(0xFF5B8DEF),
    const Color(0xFF2DD4BF),
    const Color(0xFFFBBF24),
    const Color(0xFFE879A9),
    const Color(0xFF34D399),
    const Color(0xFFF43F5E),
    const Color(0xFF60A5FA),
  ];
  final n = int.tryParse('${id ?? 0}') ?? 0;
  return colors[n.abs() % colors.length];
}

Widget letterAvatar(String letter, Color c, double size) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, c.withOpacity(0.65)],
      ),
      boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Text(
      letter.toUpperCase(),
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4),
    ),
  );
}

Widget avatarWidget(Map m, {double size = 40}) {
  final url = m['avatar']?.toString() ?? '';
  final name = m['name']?.toString() ?? '?';
  final letter = name.isNotEmpty ? name.substring(0, 1) : '?';
  final c = avatarColor(m['id']);
  // اگر آواتار واقعی (نه گراواتار پیش‌فرض خالی) باشد نشان بده
  final isDefaultGravatar = url.contains('d=mm') || url.contains('d=mp') || url.contains('d=blank');
  if (url.isNotEmpty && url.startsWith('http') && !isDefaultGravatar) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => letterAvatar(letter, c, size),
      ),
    );
  }
  return letterAvatar(letter, c, size);
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool loading = true;
  List items = [];
  String filter = 'all';
  final search = TextEditingController();
  int total = 0;

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

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('customers', queryParameters: {'per_page': 100});
      if (res.data is Map) {
        items = res.data['customers'] is List ? res.data['customers'] as List : (res.data['items'] is List ? res.data['items'] as List : []);
        total = int.tryParse('${res.data['total'] ?? items.length}') ?? items.length;
      }
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  List get _filtered {
    final q = search.text.trim();
    return items.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final orders = int.tryParse('${m['orders_count'] ?? m['order_count'] ?? 0}') ?? 0;
      if (filter == 'active' && orders <= 0) return false;
      if (filter == 'inactive' && orders > 0) return false;
      if (q.isEmpty) return true;
      final name = m['name']?.toString() ?? '';
      final email = m['email']?.toString() ?? '';
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final active = items.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return (int.tryParse('${m['orders_count'] ?? m['order_count'] ?? 0}') ?? 0) > 0;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'مشتریان',
          subtitle: 'مدیریت مشتریان فروشگاه',
          leadingIcon: Icons.people_alt_rounded,
          leadingColor: AppColors.blue,
          onRefresh: _load,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1230),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2A55)),
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.textMute, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: search,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'جستجو در مشتریان...',
                    hintStyle: TextStyle(color: AppColors.textMute, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Expanded(child: NeonCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                SoftIconBox(icon: Icons.people_outline, color: AppColors.blue, size: 36),
                const SizedBox(height: 8),
                Text('$total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                const Text('مشتریان کل', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
              ]),
            )),
            const SizedBox(width: 10),
            Expanded(child: NeonCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                SoftIconBox(icon: Icons.person_add_alt_1_rounded, color: AppColors.purple, size: 36),
                const SizedBox(height: 8),
                Text('$active', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                const Text('دارای سفارش', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
              ]),
            )),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : list.isEmpty
                  ? const Center(child: Text('مشتری‌ای یافت نشد', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final m = Map<String, dynamic>.from(list[i] as Map);
                          final name = m['name']?.toString() ?? '—';
                          final email = m['email']?.toString() ?? '';
                          final orders = m['orders_count'] ?? m['order_count'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailPage(customer: m))).then((_) => _load()),
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                avatarWidget(m, size: 48),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(email, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text('$orders سفارش', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                  ]),
                                ),
                                const Icon(Icons.chevron_left, color: AppColors.textMute),
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
                child: avatarWidget(c, size: 64),
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('#${m['number'] ?? m['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${m['total'] ?? ''}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      (m['product_names']?.toString().isNotEmpty == true)
                          ? m['product_names'].toString()
                          : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Text(
                          () {
                            final raw = m['status_label']?.toString() ?? m['status']?.toString() ?? '';
                            return raw
                                .replaceAll(RegExp(r'basalam', caseSensitive: false), 'باسلام')
                                .replaceAll(RegExp(r'torob', caseSensitive: false), 'ترب')
                                .replaceAll(RegExp(r'pending', caseSensitive: false), 'در انتظار')
                                .replaceAll(RegExp(r'processing', caseSensitive: false), 'در حال انجام')
                                .replaceAll(RegExp(r'completed', caseSensitive: false), 'تکمیل شده');
                          }(),
                          style: const TextStyle(color: AppColors.purpleGlow, fontSize: 11),
                        ),
                      ),
                      Text(
                        formatAnyDate(m['date_display'] ?? m['date_jalali'] ?? m['date_created_jalali'] ?? m['date']),
                        style: const TextStyle(color: AppColors.textMute, fontSize: 11),
                      ),
                    ]),
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
