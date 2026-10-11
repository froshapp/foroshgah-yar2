import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/products_service.dart';
import '../../core/theme/app_theme.dart';

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
    XFile? newImage;
    final picker = ImagePicker();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(p['name']?.toString() ?? 'ویرایش', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textDim), onPressed: () => Navigator.pop(ctx, false)),
                ]),
                const SizedBox(height: 12),
                // image
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: newImage != null
                        ? Image.file(File(newImage!.path), width: 64, height: 64, fit: BoxFit.cover)
                        : (p['image'] != null && p['image'].toString().isNotEmpty)
                            ? Image.network(p['image'].toString(), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                            : _ph(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                      if (f != null) setModal(() => newImage = f);
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('تغییر تصویر', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.purpleGlow),
                  )),
                ]),
                const SizedBox(height: 16),
                const Text('وضعیت', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final s in [('publish', 'منتشر', AppColors.cyan), ('draft', 'پیش‌نویس', AppColors.orange), ('pending', 'انتظار', AppColors.textDim)])
                    ChoiceChip(
                      label: Text(s.$2, style: TextStyle(color: status == s.$1 ? Colors.white : AppColors.textDim, fontSize: 12)),
                      selected: status == s.$1,
                      selectedColor: s.$3.withOpacity(0.35),
                      backgroundColor: AppColors.surface,
                      onSelected: (_) => setModal(() => status = s.$1),
                    ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(priceCtrl, 'قیمت اصلی')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(saleCtrl, 'قیمت ویژه')),
                ]),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('مدیریت موجودی', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: manageStock,
                  activeColor: AppColors.purple,
                  onChanged: (v) => setModal(() => manageStock = v),
                ),
                if (manageStock) _field(stockCtrl, 'موجودی', number: true),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ذخیره تغییرات'),
                ),
              ]),
            ),
          );
        });
      },
    );

    if (ok == true && mounted) {
      final auth = context.read<AuthService>();
      final svc = context.read<ProductsService>();
      // upload image
      if (newImage != null) {
        try {
          final form = FormData.fromMap({'file': await MultipartFile.fromFile(newImage!.path, filename: newImage!.name)});
          final media = await auth.api.dio.post('products/upload', data: form, options: Options(contentType: 'multipart/form-data'));
          final imageId = media.data is Map ? media.data['id'] : null;
          if (imageId != null) {
            await auth.api.dio.put('products/$id', data: {'image_id': imageId});
          }
        } catch (_) {}
      }
      await svc.updateProduct(auth, id,
        price: priceCtrl.text.trim().isEmpty ? null : priceCtrl.text.trim(),
        regularPrice: priceCtrl.text.trim().isEmpty ? null : priceCtrl.text.trim(),
        stock: manageStock ? int.tryParse(stockCtrl.text.trim()) : null,
        status: status,
      );
      if (saleCtrl.text.trim().isNotEmpty) {
        try {
          await auth.api.dio.put('products/$id', data: {'sale_price': saleCtrl.text.trim(), 'regular_price': priceCtrl.text.trim()});
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد')));
        svc.fetchProducts(auth, refresh: true);
      }
    }
    priceCtrl.dispose();
    saleCtrl.dispose();
    stockCtrl.dispose();
  }

  Widget _ph() => Container(width: 64, height: 64, color: AppColors.surface, child: const Icon(Icons.image, color: AppColors.textMute));

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.surface,
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
    String mode = 'fixed'; // fixed | percent
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('تغییر قیمت گروهی', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: ChoiceChip(
                label: const Text('مبلغ ثابت', style: TextStyle(fontSize: 12)),
                selected: mode == 'fixed',
                selectedColor: AppColors.purple.withOpacity(0.4),
                onSelected: (_) => setD(() => mode = 'fixed'),
              )),
              const SizedBox(width: 8),
              Expanded(child: ChoiceChip(
                label: const Text('درصد', style: TextStyle(fontSize: 12)),
                selected: mode == 'percent',
                selectedColor: AppColors.purple.withOpacity(0.4),
                onSelected: (_) => setD(() => mode = 'percent'),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: mode == 'fixed' ? 'مثلاً ۵۰۰۰۰ تومان اضافه' : 'مثلاً ۱۰ درصد افزایش',
                hintStyle: const TextStyle(color: AppColors.textMute, fontSize: 12),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('اعمال')),
          ],
        );
      }),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !mounted) {
      ctrl.dispose();
      return;
    }
    final auth = context.read<AuthService>();
    final svc = context.read<ProductsService>();
    final val = double.tryParse(ctrl.text.trim()) ?? 0;
    int done = 0;
    for (final id in _selected) {
      final p = svc.products.firstWhere((e) => e['id'].toString() == id.toString(), orElse: () => {});
      if (p.isEmpty) continue;
      final current = double.tryParse(p['regular_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0;
      double next;
      if (mode == 'percent') {
        next = current + (current * val / 100);
      } else {
        next = current + val;
      }
      if (await svc.updateProduct(auth, id, price: next.round().toString(), regularPrice: next.round().toString())) {
        done++;
      }
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$done محصول به‌روز شد')));
      svc.fetchProducts(auth, refresh: true);
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ProductsService>();

    return SafeArea(
      child: Column(children: [
        GlassHeader(
          title: 'محصولات',
          actions: [
            IconButton(
              icon: Icon(_selectMode ? Icons.close : Icons.attach_money_rounded, color: _selectMode ? Colors.white70 : AppColors.cyan),
              tooltip: 'قیمت گروهی',
              onPressed: () => setState(() { _selectMode = !_selectMode; _selected.clear(); }),
            ),
            if (svc.loading)
              const Padding(padding: EdgeInsets.all(8), child: MiniLoader(size: 18))
            else
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: () => svc.fetchProducts(auth, refresh: true)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 44,
                child: TextField(
                controller: _search,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'جستجو...',
                  hintStyle: const TextStyle(color: AppColors.textMute, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMute, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (v) => svc.fetchProducts(auth, refresh: true, search: v),
              ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppColors.card,
                    menuMaxHeight: 240,
                    value: svc.categoryId,
                    hint: const Text('دسته', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMute, size: 18),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('همه', style: TextStyle(color: Colors.white, fontSize: 12))),
                      ...svc.categories.map((c) {
                        final id = int.tryParse(c['id']?.toString() ?? '');
                        return DropdownMenuItem<int?>(value: id, child: Text(c['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis));
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
          ]),
        ),
        if (_selectMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selected.length == svc.products.length) {
                      _selected.clear();
                    } else {
                      for (final p in svc.products) {
                        final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
                        if (id > 0) _selected.add(id);
                      }
                    }
                  });
                },
                child: Text(_selected.length == svc.products.length && svc.products.isNotEmpty ? 'لغو همه' : 'انتخاب همه'),
              ),
              Text('${_selected.length} انتخاب', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              const Spacer(),
              if (_selected.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _bulkPrice,
                  icon: const Icon(Icons.attach_money_rounded, size: 18),
                  label: const Text('قیمت گروهی', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: svc.loading && svc.products.isEmpty
              ? const Center(child: MiniLoader())
              : svc.error != null && svc.products.isEmpty
                  ? Center(child: Text(svc.error!, style: const TextStyle(color: AppColors.red)))
                  : svc.products.isEmpty
                      ? const Center(child: Text('محصولی یافت نشد', style: TextStyle(color: AppColors.textDim)))
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: () => svc.fetchProducts(auth, refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: svc.products.length + (svc.hasMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i >= svc.products.length) {
                                svc.fetchProducts(auth);
                                return const Padding(padding: EdgeInsets.all(16), child: Center(child: MiniLoader(size: 22)));
                              }
                              final p = svc.products[i];
                              final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
                              final selected = _selected.contains(id);
                              final stock = p['stock_quantity'];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  onTap: () {
                                    if (_selectMode) {
                                      setState(() => selected ? _selected.remove(id) : _selected.add(id));
                                    } else {
                                      _editProduct(p);
                                    }
                                  },
                                  borderColor: AppColors.purple.withOpacity(0.25),
                                  child: Row(children: [
                                    if (_selectMode)
                                      Checkbox(value: selected, activeColor: AppColors.purple, onChanged: (_) => setState(() => selected ? _selected.remove(id) : _selected.add(id)))
                                    else
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.edit, color: AppColors.purpleGlow, size: 18),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(p['name']?.toString() ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: Text('${_fmt(p['price'] ?? p['regular_price'])} تومان', style: const TextStyle(color: AppColors.purpleGlow, fontSize: 11)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('موجودی: ${stock ?? '—'}', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                      ]),
                                    ])),
                                    const SizedBox(width: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: (p['image'] != null && p['image'].toString().isNotEmpty)
                                          ? Image.network(p['image'].toString(), width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                                          : _ph(),
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
