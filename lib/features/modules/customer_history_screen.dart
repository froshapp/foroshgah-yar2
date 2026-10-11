import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'customers_screen.dart';

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});
  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
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

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('customers', queryParameters: {'per_page': 80});
      if (res.data is Map && res.data['customers'] is List) {
        customers = (res.data['customers'] as List)
            .where((c) => c is Map && (int.tryParse('${c['order_count'] ?? 0}') ?? 0) > 0)
            .toList();
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  List get filtered {
    final q = search.text.trim();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      if (c is! Map) return false;
      return '${c['name'] ?? ''} ${c['phone'] ?? ''}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.white), onPressed: () => Navigator.pop(context)),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('سوابق مشتریان', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('تاریخچه خرید و تعاملات', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ]),
              ),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.history, color: AppColors.blue),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              ),
              onChanged: (_) => setState(() {}),
            ),
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
                            ? ListView(children: [SizedBox(height: 100), Center(child: Text('سابقه‌ای یافت نشد', style: TextStyle(color: AppColors.textDim)))])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final m = Map<String, dynamic>.from(list[i] as Map);
                                  final count = m['order_count'] ?? 0;
                                  final last = m['last_order_date']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: NeonCard(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => CustomerDetailPage(customer: m),
                                      )),
                                      child: Row(children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.blue.withOpacity(0.2),
                                          ),
                                          child: const Icon(Icons.person, color: AppColors.blue),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(m['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 3),
                                            Text('$count خرید${last.isNotEmpty ? '  •  آخرین خرید: $last' : ''}',
                                                style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
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
      ),
    );
  }
}
