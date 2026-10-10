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
        'per_page': 40,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('مدیریت مشتریان', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
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
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : customers.isEmpty
                      ? const Center(child: Text('مشتری یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: () => _load(q: search.text),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: customers.length,
                            itemBuilder: (_, i) {
                              final c = Map<String, dynamic>.from(customers[i] as Map);
                              final phone = c['phone']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  child: Row(children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.purple.withOpacity(0.2),
                                      child: Text((c['name']?.toString() ?? '?').isNotEmpty ? (c['name'].toString()[0]) : '?', style: const TextStyle(color: AppColors.purpleGlow)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: AppColors.textDim, fontSize: 12), textDirection: TextDirection.ltr),
                                      Text('${c['order_count'] ?? 0} سفارش', style: const TextStyle(color: AppColors.textMute, fontSize: 11)),
                                    ])),
                                    if (phone.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppColors.cyan),
                                        onPressed: () async {
                                          final u = Uri.parse('tel:$phone');
                                          if (await canLaunchUrl(u)) await launchUrl(u);
                                        },
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
}
