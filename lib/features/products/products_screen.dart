import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/products_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      context.read<ProductsService>().fetchProducts(auth, refresh: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ProductsService>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('محصولات', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => svc.fetchProducts(auth, refresh: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'جستجو در محصولات...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF252640),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) => svc.fetchProducts(auth, refresh: true, search: v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: svc.loading && svc.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : svc.error != null && svc.products.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(svc.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                      ))
                    : svc.products.isEmpty
                        ? const Center(child: Text('محصولی یافت نشد', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            color: const Color(0xFF6C63FF),
                            onRefresh: () => svc.fetchProducts(auth, refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: svc.products.length,
                              itemBuilder: (ctx, i) {
                                final p = svc.products[i];
                                final name = p['name']?.toString() ?? 'بدون نام';
                                final price = p['price']?.toString() ?? p['regular_price']?.toString() ?? '—';
                                final stock = p['stock_quantity'] ?? p['stock'] ?? p['quantity'];
                                final status = p['status']?.toString() ?? '';
                                final img = p['image']?.toString() ??
                                    (p['images'] is List && (p['images'] as List).isNotEmpty
                                        ? (p['images'][0] is Map ? p['images'][0]['src'] : p['images'][0])?.toString()
                                        : null);
                                final id = p['id']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252640),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1B2E),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: img != null && img.toString().startsWith('http')
                                            ? Image.network(img.toString(), fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24))
                                            : const Icon(Icons.image, color: Colors.white24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('شناسه: $id', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text('$price', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 12),
                                                Text(
                                                  stock != null ? 'موجودی: $stock' : (status == 'publish' ? 'منتشر شده' : status),
                                                  style: TextStyle(
                                                    color: stock == 0 || stock == '0' ? Colors.redAccent : Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
