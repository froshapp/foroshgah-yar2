import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';

class ManualOrderScreen extends StatefulWidget {
  const ManualOrderScreen({super.key});
  @override
  State<ManualOrderScreen> createState() => _ManualOrderScreenState();
}

class _ManualOrderScreenState extends State<ManualOrderScreen> {
  bool loadingProducts = true;
  bool submitting = false;
  List products = [];
  final Map<int, int> cart = {}; // productId -> qty
  final noteCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  String customerName = '';
  String customerPhone = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => loadingProducts = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('products', queryParameters: {
        'per_page': 100,
        'status': 'publish',
      });
      if (res.data is Map && res.data['products'] is List) {
        products = List.from(res.data['products'] as List);
      } else if (res.data is List) {
        products = List.from(res.data as List);
      }
    } catch (_) {
      products = [];
    }
    if (mounted) setState(() => loadingProducts = false);
  }

  List get _filtered {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) return products;
    return products.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return (m['name']?.toString() ?? '').contains(q);
    }).toList();
  }

  int get _totalItems => cart.values.fold(0, (a, b) => a + b);

  Future<void> _submit() async {
    if (cart.isEmpty) {
      showErr(context, 'حداقل یک محصول انتخاب کنید');
      return;
    }
    setState(() => submitting = true);
    try {
      final items = cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
      final res = await context.read<AuthService>().api.dio.post('orders', data: {
        'items': items,
        'status': 'pending',
        'note': [
          if (customerName.trim().isNotEmpty) 'مشتری: ${customerName.trim()}',
          if (customerPhone.trim().isNotEmpty) 'تلفن: ${customerPhone.trim()}',
          if (noteCtrl.text.trim().isNotEmpty) noteCtrl.text.trim(),
        ].join('\n'),
      });
      final code = res.statusCode ?? 0;
      if (code >= 400 || (res.data is Map && res.data['success'] == false)) {
        final msg = res.data is Map ? (res.data['message']?.toString() ?? 'ثبت نشد') : 'ثبت نشد';
        showErr(context, msg);
      } else {
        showOk(context, 'سفارش ثبت شد');
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      showErr(context, '$e');
    }
    if (mounted) setState(() => submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'سفارش دستی',
          subtitle: 'انتخاب محصول و ثبت سفارش',
          leadingIcon: Icons.add_shopping_cart_rounded,
          leadingColor: AppColors.blue,
        ),
        // مشخصات مشتری
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: NeonCard(
            child: Column(children: [
              TextField(
                onChanged: (v) => customerName = v,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'نام مشتری (اختیاری)',
                  hintStyle: TextStyle(color: AppColors.textMute),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              const Divider(color: Color(0xFF1E2A55), height: 16),
              TextField(
                onChanged: (v) => customerPhone = v,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'شماره تماس (اختیاری)',
                  hintStyle: TextStyle(color: AppColors.textMute),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ]),
          ),
        ),
        // جستجو
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1230),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2A55)),
            ),
            child: Row(children: [
              const Icon(Icons.search, color: AppColors.textMute, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'جستجوی محصول...',
                    hintStyle: TextStyle(color: AppColors.textMute, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ),
        ),
        Expanded(
          child: loadingProducts
              ? const Center(child: MiniLoader())
              : list.isEmpty
                  ? const Center(child: Text('محصولی نیست', style: TextStyle(color: AppColors.textDim)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final m = Map<String, dynamic>.from(list[i] as Map);
                        final id = int.tryParse('${m['id']}') ?? 0;
                        final name = m['name']?.toString() ?? '';
                        final price = m['price']?.toString() ?? m['regular_price']?.toString() ?? '0';
                        final img = m['image']?.toString() ?? '';
                        final qty = cart[id] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NeonCard(
                            padding: const EdgeInsets.all(10),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: img.isNotEmpty
                                    ? Image.network(img, width: 48, height: 48, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _ph())
                                    : _ph(),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('$price تومان', style: const TextStyle(color: AppColors.purpleGlow, fontSize: 12)),
                                ]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMute),
                                onPressed: qty <= 0
                                    ? null
                                    : () => setState(() {
                                          if (qty <= 1) {
                                            cart.remove(id);
                                          } else {
                                            cart[id] = qty - 1;
                                          }
                                        }),
                              ),
                              Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.purple),
                                onPressed: () => setState(() => cart[id] = qty + 1),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
        // ثبت
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ElevatedButton(
              onPressed: submitting || cart.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: submitting
                  ? const MiniLoader(size: 22)
                  : Text('ثبت سفارش ($_totalItems قلم)', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _ph() => Container(
        width: 48,
        height: 48,
        color: AppColors.surface,
        child: const Icon(Icons.image_outlined, color: AppColors.textMute, size: 20),
      );
}
