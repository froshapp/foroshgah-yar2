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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      final svc = context.read<ProductsService>();
      await svc.fetchCategories(auth);
      await svc.fetchProducts(auth, refresh: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _editProduct(Map<String, dynamic> p) async {
    final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
    if (id == 0) return;
    final priceCtrl = TextEditingController(text: p['regular_price']?.toString() ?? p['price']?.toString() ?? '');
    final saleCtrl = TextEditingController(text: p['sale_price']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: p['stock_quantity']?.toString() ?? '');
    String status = p['status']?.toString() ?? 'publish';
    bool manageStock = p['manage_stock'] == true || p['stock_quantity'] != null;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF252640),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p['name']?.toString() ?? 'ویرایش',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx, false)),
                    ],
                  ),
                  Text('شناسه: ${p['id']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Text('وضعیت محصول', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final s in [
                      ('publish', 'منتشر شده', const Color(0xFF10B981)),
                      ('draft', 'پیش‌نویس', Colors.orange),
                      ('pending', 'در انتظار', Colors.white54),
                    ])
                      ChoiceChip(
                        label: Text(s.$2, style: TextStyle(color: status == s.$1 ? Colors.white : Colors.white70, fontSize: 12)),
                        selected: status == s.$1,
                        selectedColor: s.$3.withOpacity(0.35),
                        backgroundColor: const Color(0xFF1A1B2E),
                        onSelected: (_) => setModal(() => status = s.$1),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _modalField(priceCtrl, 'قیمت اصلی')),
                    const SizedBox(width: 12),
                    Expanded(child: _modalField(saleCtrl, 'قیمت ویژه')),
                  ]),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('فعال‌سازی انبار', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: manageStock,
                    activeColor: const Color(0xFF6C63FF),
                    onChanged: (v) => setModal(() => manageStock = v),
                  ),
                  if (manageStock) _modalField(stockCtrl, 'موجودی انبار', number: true),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.check),
                    label: const Text('ذخیره تغییرات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (ok == true && mounted) {
      final auth = context.read<AuthService>();
      final svc = context.read<ProductsService>();
      final bodyOk = await svc.updateProduct(
        auth,
        id,
        price: priceCtrl.text.trim().isEmpty ? null : priceCtrl.text.trim(),
        regularPrice: priceCtrl.text.trim().isEmpty ? null : priceCtrl.text.trim(),
        stock: manageStock ? int.tryParse(stockCtrl.text.trim()) : null,
        status: status,
      );
      // sale price via extra put
      if (saleCtrl.text.trim().isNotEmpty) {
        try {
          await auth.api.dio.put('products/$id', data: {
            'sale_price': saleCtrl.text.trim(),
            'regular_price': priceCtrl.text.trim(),
          });
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bodyOk ? 'ذخیره شد' : 'خطا در ذخیره')),
        );
        svc.fetchProducts(auth, refresh: true);
      }
    }
    priceCtrl.dispose();
    saleCtrl.dispose();
    stockCtrl.dispose();
  }

  Widget _modalField(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1B2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _bulkPrice() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا محصول انتخاب کنید')));
      return;
    }
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252640),
        title: const Text('قیمت گروهی', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'قیمت جدید', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('اعمال')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
      final auth = context.read<AuthService>();
      final n = await context.read<ProductsService>().bulkUpdatePrice(auth, _selected.toList(), price: ctrl.text.trim());
      setState(() {
        _selected.clear();
        _selectMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n محصول به‌روز شد')));
        context.read<ProductsService>().fetchProducts(auth, refresh: true);
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ProductsService>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Expanded(child: Text('محصولات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                if (svc.loading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                else
                  IconButton(icon: const Icon(Icons.refresh, color: Colors.white54), onPressed: () => svc.fetchProducts(auth, refresh: true)),
                IconButton(
                  icon: Icon(_selectMode ? Icons.close : Icons.checklist, color: Colors.white54),
                  onPressed: () => setState(() {
                    _selectMode = !_selectMode;
                    _selected.clear();
                  }),
                ),
              ],
            ),
          ),
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'جستجوی محصول...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF252640),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) => svc.fetchProducts(auth, refresh: true, search: v),
            ),
          ),
          // category dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF252640),
                  value: svc.categoryId,
                  hint: const Text('همه دسته‌ها', style: TextStyle(color: Colors.white70)),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('همه دسته‌ها', style: TextStyle(color: Colors.white))),
                    ...svc.categories.map((c) {
                      final id = int.tryParse(c['id']?.toString() ?? '');
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(c['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    if (v == null) {
                      svc.clearCategory();
                      svc.fetchProducts(auth, refresh: true, categoryId: 0);
                    } else {
                      svc.fetchProducts(auth, refresh: true, categoryId: v);
                    }
                  },
                ),
              ),
            ),
          ),
          if (_selectMode && _selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('${_selected.length} انتخاب', style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  TextButton(onPressed: _bulkPrice, child: const Text('تغییر قیمت گروهی')),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: svc.loading && svc.products.isEmpty
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF))))
                : svc.error != null && svc.products.isEmpty
                    ? Center(child: Text(svc.error!, style: const TextStyle(color: Colors.redAccent)))
                    : svc.products.isEmpty
                        ? const Center(child: Text('محصولی یافت نشد', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            color: const Color(0xFF6C63FF),
                            onRefresh: () => svc.fetchProducts(auth, refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: svc.products.length + (svc.hasMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i >= svc.products.length) {
                                  svc.fetchProducts(auth);
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))),
                                  );
                                }
                                final p = svc.products[i];
                                final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
                                final selected = _selected.contains(id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
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
                                    leading: _selectMode
                                        ? Checkbox(
                                            value: selected,
                                            activeColor: const Color(0xFF6C63FF),
                                            onChanged: (_) {
                                              setState(() {
                                                if (selected) {
                                                  _selected.remove(id);
                                                } else {
                                                  _selected.add(id);
                                                }
                                              });
                                            },
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: (p['image'] != null && p['image'].toString().isNotEmpty)
                                                ? Image.network(p['image'].toString(), width: 48, height: 48, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                                                : _imgPlaceholder(),
                                          ),
                                    title: Text(p['name']?.toString() ?? '—',
                                        style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(
                                      '${_fmt(p['price'] ?? p['regular_price'])} تومان  •  موجودی: ${p['stock_quantity'] ?? '—'}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                    trailing: const Icon(Icons.edit_outlined, color: Colors.white24, size: 20),
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

  Widget _imgPlaceholder() => Container(
        width: 48,
        height: 48,
        color: const Color(0xFF1A1B2E),
        child: const Icon(Icons.image, color: Colors.white24, size: 22),
      );
}
