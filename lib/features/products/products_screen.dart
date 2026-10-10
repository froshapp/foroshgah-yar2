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
  final Set<int> _selected = {};
  bool _selectMode = false;

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

  String _fmtMoney(dynamic v) {
    if (v == null) return '—';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _editProduct(Map<String, dynamic> p) async {
    final auth = context.read<AuthService>();
    final svc = context.read<ProductsService>();
    final id = int.tryParse(p['id'].toString()) ?? 0;
    final priceCtrl = TextEditingController(text: p['price']?.toString() ?? p['regular_price']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: p['stock_quantity']?.toString() ?? p['stock']?.toString() ?? '');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF252640),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(p['name']?.toString() ?? 'محصول',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              const Text('قیمت (تومان)', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1B2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              const Text('موجودی', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1B2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ذخیره تغییرات'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (ok == true && mounted) {
      final price = priceCtrl.text.trim();
      final stock = int.tryParse(stockCtrl.text.trim());
      final success = await svc.updateProduct(
        auth,
        id,
        price: price.isEmpty ? null : price,
        regularPrice: price.isEmpty ? null : price,
        stock: stock,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'محصول به‌روز شد' : 'خطا در ذخیره — API را بررسی کنید')),
        );
      }
    }
  }

  Future<void> _bulkPrice() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا محصولات را انتخاب کنید')));
      return;
    }
    final priceCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252640),
        title: const Text('تغییر گروهی قیمت', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_selected.length} محصول انتخاب شده', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'قیمت جدید (تومان)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('اعمال')),
        ],
      ),
    );

    if (ok == true && priceCtrl.text.trim().isNotEmpty && mounted) {
      final auth = context.read<AuthService>();
      final svc = context.read<ProductsService>();
      final n = await svc.bulkUpdatePrice(auth, _selected.toList(), price: priceCtrl.text.trim());
      setState(() {
        _selected.clear();
        _selectMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n محصول به‌روز شد')));
      }
    }
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
                if (_selectMode) ...[
                  TextButton(onPressed: _bulkPrice, child: const Text('قیمت گروهی', style: TextStyle(color: Color(0xFF6C63FF)))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => setState(() {
                      _selectMode = false;
                      _selected.clear();
                    }),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.checklist, color: Colors.white54),
                    tooltip: 'انتخاب گروهی',
                    onPressed: () => setState(() => _selectMode = true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white54),
                    onPressed: () => svc.fetchProducts(auth, refresh: true),
                  ),
                ],
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(svc.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
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
                                final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
                                final name = p['name']?.toString() ?? 'بدون نام';
                                final price = p['price'] ?? p['regular_price'];
                                final stock = p['stock_quantity'] ?? p['stock'];
                                final img = p['image']?.toString() ??
                                    (p['images'] is List && (p['images'] as List).isNotEmpty
                                        ? ((p['images'][0] is Map)
                                            ? p['images'][0]['src']
                                            : p['images'][0])
                                            ?.toString()
                                        : null);
                                final selected = _selected.contains(id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252640),
                                    borderRadius: BorderRadius.circular(14),
                                    border: selected ? Border.all(color: const Color(0xFF6C63FF), width: 1.5) : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        if (_selectMode) {
                                          setState(() {
                                            if (selected) {
                                              _selected.remove(id);
                                            } else {
                                              _selected.add(id);
                                            }
                                          });
                                        } else {
                                          _editProduct(p);
                                        }
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _selectMode = true;
                                          _selected.add(id);
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            if (_selectMode)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Icon(
                                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                                  color: selected ? const Color(0xFF6C63FF) : Colors.white38,
                                                ),
                                              ),
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
                                                      errorBuilder: (_, __, ___) =>
                                                          const Icon(Icons.image, color: Colors.white24))
                                                  : const Icon(Icons.image, color: Colors.white24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text('شناسه: $id', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(_fmtMoney(price),
                                                          style: const TextStyle(
                                                              color: Color(0xFF10B981),
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        stock != null ? 'موجودی: $stock' : '—',
                                                        style: TextStyle(
                                                          color: (stock == 0 || stock == '0')
                                                              ? Colors.redAccent
                                                              : Colors.white54,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.edit_outlined, color: Colors.white24, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
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
