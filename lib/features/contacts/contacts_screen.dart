import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/orders_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _loading = true;
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final svc = context.read<OrdersService>();
    if (svc.orders.isEmpty) {
      await svc.fetchOrders(auth, refresh: true);
    }
    final map = <String, Map<String, String>>{};
    for (final o in svc.orders) {
      String name = 'مشتری';
      String phone = '';
      final c = o['customer'];
      if (c is Map) {
        name = c['name']?.toString() ??
            '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
        phone = c['phone']?.toString() ?? '';
      }
      final b = o['billing'];
      if (b is Map) {
        if (name.isEmpty || name == 'مشتری') {
          name = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();
        }
        if (phone.isEmpty) phone = b['phone']?.toString() ?? '';
      }
      if (phone.isEmpty) continue;
      final key = phone;
      if (!map.containsKey(key)) {
        map[key] = {'name': name.isEmpty ? 'مشتری' : name, 'phone': phone};
      }
    }
    setState(() {
      _contacts = map.values.toList();
      _loading = false;
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String phone) async {
    var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.startsWith('0')) p = '98${p.substring(1)}';
    final uri = Uri.parse('https://wa.me/$p');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        title: const Text('تماس‌ها', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white54), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF))))
          : _contacts.isEmpty
              ? const Center(child: Text('تماسی یافت نشد', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (ctx, i) {
                    final c = _contacts[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                            child: Text(c['name']!.isNotEmpty ? c['name']![0] : '?',
                                style: const TextStyle(color: Color(0xFF6C63FF))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                Text(c['phone']!, style: const TextStyle(color: Colors.white54, fontSize: 12), textDirection: TextDirection.ltr),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                            onPressed: () => _call(c['phone']!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                            onPressed: () => _whatsapp(c['phone']!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
