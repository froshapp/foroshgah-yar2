import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/products_service.dart';
import '../../core/theme/app_theme.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  String stockFilter = 'all'; // all | instock | outofstock
  int? catFilter;

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

  bool _inStock(Map p) {
    final status = (p['stock_status'] ?? '').toString().toLowerCase();
    if (status == 'outofstock') return false;
    if (status == 'instock') return true;
    final q = p['stock_quantity'];
    if (q == null) return true;
    final n = int.tryParse(q.toString());
    if (n == null) return true;
    return n > 0;
  }

  List<Map<String, dynamic>> _filtered(List products) {
    final q = _search.text.trim();
    return products.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).where((p) {
      if (stockFilter == 'instock' && !_inStock(p)) return false;
      if (stockFilter == 'outofstock' && _inStock(p)) return false;
      // فیلتر دسته فقط سمت سرور (شامل زیردسته)
      if (q.isEmpty) return true;
      return (p['name']?.toString() ?? '').contains(q) || (p['id']?.toString() ?? '').contains(q);
    }).toList();
  }

  Widget _ph({double s = 56}) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.image_outlined, color: AppColors.textMute),
      );

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
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: newImage != null
                        ? Image.file(File(newImage!.path), width: 64, height: 64, fit: BoxFit.cover)
                        : (p['image'] != null && p['image'].toString().isNotEmpty)
                            ? Image.network(p['image'].toString(), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(s: 64))
                            : _ph(s: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                        if (f != null) setModal(() => newImage = f);
                      },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('تغییر تصویر'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.purpleGlow),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('قیمت اصلی'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: saleCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('قیمت ویژه'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('موجودی'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('مدیریت موجودی', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: manageStock,
                  activeColor: AppColors.purple,
                  onChanged: (v) => setModal(() => manageStock = v),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      bool saved = false;
      try {
        dynamic imageId;
        if (newImage != null) {
          try {
            final form = FormData.fromMap({'file': await MultipartFile.fromFile(newImage!.path, filename: newImage!.name)});
            final media = await auth.api.dio.post('products/upload', data: form, options: Options(contentType: 'multipart/form-data'));
            if (media.data is Map) {
              imageId = media.data['id'] ?? media.data['attachment_id'] ?? media.data['image_id'];
            }
          } catch (_) {}
        }
        final body = <String, dynamic>{
          'regular_price': priceCtrl.text.trim().replaceAll(',', ''),
          'price': priceCtrl.text.trim().replaceAll(',', ''),
          'status': status,
        };
        final sale = saleCtrl.text.trim().replaceAll(',', '');
        body['sale_price'] = sale;
        final stockVal = int.tryParse(stockCtrl.text.trim());
        if (stockVal != null) {
          body['stock_quantity'] = stockVal;
          body['manage_stock'] = true;
        }
        if (imageId != null) body['image_id'] = imageId;
        final opt = Options(contentType: 'application/json', headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
        var res = await auth.api.dio.post('products/$id', data: body, options: opt);
        saved = res.statusCode == 200 || res.statusCode == 201 || (res.data is Map && res.data['success'] == true);
        if (!saved) {
          res = await auth.api.dio.put('products/$id', data: body, options: opt);
          saved = res.statusCode == 200 || res.statusCode == 201 || (res.data is Map && res.data['success'] == true);
        }
        if (!saved && res.data is Map) {
          final msg = res.data['message']?.toString() ?? res.data['code']?.toString() ?? '';
          if (msg.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF7F1D1D)));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: const Color(0xFF7F1D1D)));
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved ? 'تغییرات ذخیره شد' : 'ذخیره نشد — دوباره تلاش کنید'),
          backgroundColor: saved ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
        ));
        await svc.fetchProducts(auth, refresh: true);
      }
    }
    priceCtrl.dispose();
    saleCtrl.dispose();
    stockCtrl.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );



  String _catLabel(ProductsService svc) {
    if (catFilter == null) return 'همه دسته‌ها';
    for (final c in svc.categories) {
      final m = Map<String, dynamic>.from(c as Map);
      if (int.tryParse('${m['id']}') == catFilter) return m['name']?.toString() ?? 'دسته';
    }
    return 'دسته';
  }

  Future<void> _pickCategory(AuthService auth, ProductsService svc) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF0E1838),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        final cats = svc.categories;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.55,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMute, borderRadius: BorderRadius.circular(4))),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('انتخاب دسته‌بندی', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: cats.length + 1,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        final sel = catFilter == null;
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          selected: sel,
                          selectedTileColor: AppColors.purple.withOpacity(0.2),
                          leading: Icon(sel ? Icons.check_circle_rounded : Icons.apps_rounded, color: sel ? AppColors.purpleGlow : AppColors.textMute),
                          title: const Text('همه دسته‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          onTap: () => Navigator.pop(ctx, {'picked': true, 'id': null}),
                        );
                      }
                      final m = Map<String, dynamic>.from(cats[i - 1] as Map);
                      final id = int.tryParse('${m['id']}');
                      final sel = id == catFilter;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        selected: sel,
                        selectedTileColor: AppColors.purple.withOpacity(0.2),
                        leading: Icon(sel ? Icons.check_circle_rounded : Icons.folder_outlined, color: sel ? AppColors.purpleGlow : AppColors.textMute),
                        title: Text(m['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(ctx, {'picked': true, 'id': id}),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || result['picked'] != true) return;
    final v = result['id'] as int?;
    setState(() => catFilter = v);
    await svc.fetchProducts(auth, refresh: true, categoryId: v ?? 0);
  }

  Future<void> _openBulkPrice(AuthService auth, ProductsService svc) async {
    final mode = ValueNotifier<String>('percent');
    final valueCtrl = TextEditingController();
    final catId = ValueNotifier<int?>(null);
    final cats = svc.categories;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('تغییر قیمت گروهی', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ValueListenableBuilder<String>(
              valueListenable: mode,
              builder: (_, m, __) => Row(children: [
                Expanded(child: ChoiceChip(
                  label: const Text('درصدی'),
                  selected: m == 'percent',
                  onSelected: (_) => mode.value = 'percent',
                  selectedColor: AppColors.purple,
                  labelStyle: TextStyle(color: m == 'percent' ? Colors.white : AppColors.textDim),
                )),
                const SizedBox(width: 8),
                Expanded(child: ChoiceChip(
                  label: const Text('مبلغ ثابت'),
                  selected: m == 'fixed',
                  onSelected: (_) => mode.value = 'fixed',
                  selectedColor: AppColors.purple,
                  labelStyle: TextStyle(color: m == 'fixed' ? Colors.white : AppColors.textDim),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'مقدار (درصد یا تومان)',
                hintStyle: TextStyle(color: AppColors.textMute),
                filled: true,
                fillColor: Color(0xFF0B1230),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              ),
            ),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 12),
              ValueListenableBuilder<int?>(
                valueListenable: catId,
                builder: (_, cid, __) => DropdownButtonFormField<int?>(
                  value: cid,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF0B1230),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  hint: const Text('همه دسته‌ها', style: TextStyle(color: AppColors.textMute)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('همه دسته‌ها', style: TextStyle(color: Colors.white))),
                    ...cats.map((c) {
                      final m = Map<String, dynamic>.from(c as Map);
                      return DropdownMenuItem<int?>(
                        value: int.tryParse('${m['id']}'),
                        child: Text(m['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                      );
                    }),
                  ],
                  onChanged: (v) => catId.value = v,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('اعمال روی محصولات'),
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );

    if (ok != true || !mounted) return;
    final raw = valueCtrl.text.trim().replaceAll(',', '');
    final val = double.tryParse(raw);
    if (val == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مقدار معتبر وارد کنید')));
      return;
    }

    // جمع‌آوری شناسه‌ها از لیست فعلی + در صورت خالی بودن، همه محصولات
    var list = _filtered(svc.products);
    if (list.isEmpty) {
      await svc.fetchProducts(auth, refresh: true);
      list = _filtered(svc.products);
    }
    final ids = <int>[];
    for (final p in list) {
      if (catId.value != null) {
        final pcats = p['categories'];
        bool okCat = false;
        if (pcats is List) {
          for (final c in pcats) {
            final id = c is Map ? (c['id'] ?? c['term_id']) : c;
            if (int.tryParse('$id') == catId.value) okCat = true;
          }
        }
        // category_ids
        if (!okCat && p['category_ids'] is List) {
          for (final c in p['category_ids'] as List) {
            if (int.tryParse('$c') == catId.value) okCat = true;
          }
        }
        if (!okCat) continue;
      }
      final id = int.tryParse('${p['id']}') ?? 0;
      if (id > 0) ids.add(id);
    }
    // اگر لیست محلی خالی بود، سرور با category یا all پر می‌کند
    int done = 0;
    String? errMsg;
    try {
      final body = <String, dynamic>{
        'ids': ids,
        'mode': mode.value,
        'value': val,
        if (catId.value != null) 'category': catId.value,
        'all': ids.isEmpty,
      };
      // اطمینان از ارسال JSON
      final opt = Options(
        contentType: 'application/json',
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );
      final res = await auth.api.dio.post('products/bulk-price', data: body, options: opt);
      if (res.data is Map) {
        done = int.tryParse('${res.data['updated'] ?? 0}') ?? 0;
        errMsg = res.data['message']?.toString();
      }
      if (done == 0 && ids.isNotEmpty) {
        // fallback: یکی‌یکی
        for (final id in ids) {
          try {
            final p = list.firstWhere((e) => '${e['id']}' == '$id', orElse: () => <String, dynamic>{});
            final price = double.tryParse('${p['regular_price'] ?? p['price'] ?? 0}') ?? 0;
            final newPrice = mode.value == 'percent' ? price * (1 + val / 100) : price + val;
            final b = {
              'regular_price': newPrice.round().toString(),
              'price': newPrice.round().toString(),
            };
            var r = await auth.api.dio.put('products/$id', data: b);
            var ok = r.statusCode == 200 || r.statusCode == 201 || (r.data is Map && r.data['success'] == true);
            if (!ok) {
              r = await auth.api.dio.post('products/$id', data: {...b, '_method': 'PUT'});
              ok = r.statusCode == 200 || r.statusCode == 201 || (r.data is Map && r.data['success'] == true);
            }
            if (ok) done++;
          } catch (_) {}
        }
      }
    } catch (e) {
      errMsg = e.toString();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(done > 0 ? '$done محصول به‌روز شد' : (errMsg ?? 'هیچ محصولی به‌روز نشد')),
        backgroundColor: done > 0 ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
      ));
      await svc.fetchProducts(auth, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ProductsService>();
    final list = _filtered(svc.products);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'محصولات',
          subtitle: 'مدیریت محصولات فروشگاه',
          leadingIcon: Icons.inventory_2_rounded,
          leadingColor: AppColors.purple,
          onRefresh: () => svc.fetchProducts(auth, refresh: true, search: _search.text.trim().isEmpty ? null : _search.text.trim()),
        ),
        // جستجو
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
                  controller: _search,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onSubmitted: (v) => svc.fetchProducts(auth, refresh: true, search: v.trim().isEmpty ? null : v.trim()),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'جستجو در محصولات...',
                    hintStyle: TextStyle(color: AppColors.textMute, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.purpleGlow, size: 22),
                tooltip: 'تغییر قیمت گروهی',
                onPressed: () => _openBulkPrice(auth, svc),
              ),
            ]),
          ),
        ),
        // دسته + افزودن محصول کنار هم
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _pickCategory(auth, svc),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2A55)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined, color: AppColors.purpleGlow, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _catLabel(svc),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMute, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () async {
                  final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                  if (ok == true && mounted) svc.fetchProducts(auth, refresh: true);
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]),
                    boxShadow: [
                      BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text('افزودن محصول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
        // فیلتر موجودی
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            children: [
              _chip('همه', 'all', AppColors.purple),
              _chip('موجود', 'instock', AppColors.green),
              _chip('ناموجود', 'outofstock', AppColors.red),
            ],
          ),
        ),
        Expanded(
          child: svc.loading && svc.products.isEmpty
              ? const Center(child: MiniLoader())
              : list.isEmpty
                  ? const Center(child: Text('محصولی یافت نشد', style: TextStyle(color: AppColors.textDim)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      backgroundColor: AppColors.card,
                      onRefresh: () => svc.fetchProducts(auth, refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final p = list[i];
                          final inStock = _inStock(p);
                          final stock = p['stock_quantity'];
                          final img = p['image']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NeonCard(
                              onTap: () => _editProduct(p),
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                // تصویر محصول
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: img.isNotEmpty
                                      ? Image.network(img, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(s: 64))
                                      : _ph(s: 64),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(
                                      p['name']?.toString() ?? '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_fmt(p['price'] ?? p['regular_price'])} تومان',
                                      style: const TextStyle(color: AppColors.purpleGlow, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (inStock ? AppColors.green : AppColors.red).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: (inStock ? AppColors.green : AppColors.red).withOpacity(0.35)),
                                      ),
                                      child: Text(
                                        inStock ? 'موجود${stock != null ? ' · $stock' : ''}' : 'ناموجود',
                                        style: TextStyle(color: inStock ? AppColors.green : AppColors.red, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ),
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

  Widget _chip(String label, String val, Color c) {
    final sel = stockFilter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => stockFilter = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: sel ? LinearGradient(colors: [c, c.withOpacity(0.75)]) : null,
            color: sel ? null : const Color(0xFF0B1230),
            border: Border.all(color: sel ? c.withOpacity(0.5) : const Color(0xFF1E2A55)),
          ),
          child: Text(
            label,
            style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
