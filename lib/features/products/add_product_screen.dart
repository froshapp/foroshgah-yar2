import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/products_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  final _sku = TextEditingController();
  final _desc = TextEditingController();
  final _brand = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _saleFrom = TextEditingController();
  final _saleTo = TextEditingController();
  final _attrs = TextEditingController(); // ویژگی‌ها اختیاری
  String _status = 'publish';
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _shipping = [];
  String? _brandName;
  String? _shippingMethod;
  int? _categoryId;
  bool _saving = false;
  XFile? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      await context.read<ProductsService>().fetchCategories(auth);
      try {
        final b = await auth.api.dio.get('products/brands');
        if (b.data is Map && b.data['brands'] is List) {
          setState(() => _brands = (b.data['brands'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
        final s = await auth.api.dio.get('shipping-methods');
        if (s.data is Map && s.data['methods'] is List) {
          setState(() => _shipping = (s.data['methods'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _sku.dispose();
    _desc.dispose();
    _brand.dispose();
    _weight.dispose();
    _length.dispose();
    _width.dispose();
    _height.dispose();
    _saleFrom.dispose();
    _saleTo.dispose();
    _attrs.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final f = await _picker.pickImage(source: src, maxWidth: 1200, imageQuality: 85);
    if (f != null) setState(() => _image = f);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام محصول الزامی است')));
      setState(() => _step = 0);
      return;
    }
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthService>();
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      int? imageId;
      if (_image != null) {
        try {
          final form = FormData.fromMap({
            'file': await MultipartFile.fromFile(_image!.path, filename: _image!.name),
          });
          final media = await auth.api.dio.post(
            'products/upload',
            data: form,
            options: Options(contentType: 'multipart/form-data'),
          );
          if (media.data is Map && media.data['id'] != null) {
            imageId = int.tryParse(media.data['id'].toString());
          }
        } catch (e) {
          debugPrint('upload image failed: $e');
        }
      }

      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'type': 'simple',
        'status': _status,
        'regular_price': _price.text.trim().isEmpty ? '0' : _price.text.trim(),
        'description': _desc.text.trim(),
        'short_description': _desc.text.trim().length > 150
            ? _desc.text.trim().substring(0, 150)
            : _desc.text.trim(),
        'manage_stock': _stock.text.trim().isNotEmpty,
      };
      if (_salePrice.text.trim().isNotEmpty) body['sale_price'] = _salePrice.text.trim();
      if (_sku.text.trim().isNotEmpty) body['sku'] = _sku.text.trim();
      if (_stock.text.trim().isNotEmpty) body['stock_quantity'] = int.tryParse(_stock.text.trim()) ?? 0;
      if (_categoryId != null) body['categories'] = [_categoryId];
      if (imageId != null) body['image_id'] = imageId;
      if (_brand.text.trim().isNotEmpty) body['brand'] = _brand.text.trim();
      if (_weight.text.trim().isNotEmpty) body['weight'] = _weight.text.trim();
      if (_length.text.trim().isNotEmpty) body['length'] = _length.text.trim();
      if (_width.text.trim().isNotEmpty) body['width'] = _width.text.trim();
      if (_height.text.trim().isNotEmpty) body['height'] = _height.text.trim();
      if (_saleFrom.text.trim().isNotEmpty) body['date_on_sale_from'] = _saleFrom.text.trim();
      if (_saleTo.text.trim().isNotEmpty) body['date_on_sale_to'] = _saleTo.text.trim();
      if (_brandName != null) body['brand'] = _brandName;
      if (_shippingMethod != null) body['shipping_class'] = _shippingMethod;
      if (_attrs.text.trim().isNotEmpty) body['attributes_text'] = _attrs.text.trim();

      final res = await auth.api.dio.post('products', data: body);
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201 || res.data?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محصول اضافه شد')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data?['message']?.toString() ?? 'خطا در ذخیره')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<ProductsService>().categories;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        title: Text('افزودن محصول (${_step + 1}/3)', style: const TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // steps indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF6C63FF) : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_step == 0) ...[
                  _label('وضعیت'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _chip('publish', 'منتشر شده', const Color(0xFF10B981)),
                    _chip('draft', 'پیش‌نویس', Colors.orange),
                    _chip('pending', 'در انتظار', Colors.white54),
                  ]),
                  const SizedBox(height: 16),
                  _label('نام محصول'),
                  const SizedBox(height: 8),
                  _field(_name, 'نام محصول'),
                  const SizedBox(height: 16),
                  _label('توضیحات'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _desc,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('توضیحات محصول'),
                  ),
                  const SizedBox(height: 16),
                  _label('تصویر'),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_image!.path), width: 72, height: 72, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.image, color: Colors.white24),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 16),
                          label: const Text('گالری', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('دوربین', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                        )),
                      ]),
                    ),
                  ]),
                ] else if (_step == 1) ...[
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('قیمت اصلی'),
                      const SizedBox(height: 8),
                      _field(_price, '0', number: true),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('قیمت ویژه'),
                      const SizedBox(height: 8),
                      _field(_salePrice, 'اختیاری', number: true),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('موجودی'),
                      const SizedBox(height: 8),
                      _field(_stock, 'اختیاری', number: true),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('SKU'),
                      const SizedBox(height: 8),
                      _field(_sku, 'اختیاری'),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  _label('شروع فروش ویژه (شمسی)'),
                  const SizedBox(height: 8),
                  _dateField(_saleFrom, 'انتخاب تاریخ شروع'),
                  const SizedBox(height: 12),
                  _label('پایان فروش ویژه (شمسی)'),
                  const SizedBox(height: 8),
                  _dateField(_saleTo, 'انتخاب تاریخ پایان'),
                  const SizedBox(height: 16),
                  _label('برند'),
                  const SizedBox(height: 8),
                  if (_brands.isEmpty)
                    _field(_brand, 'اختیاری')
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF252640),
                          value: _brandName,
                          hint: const Text('انتخاب برند', style: TextStyle(color: Colors.white54)),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('بدون برند', style: TextStyle(color: Colors.white70))),
                            ..._brands.map((b) => DropdownMenuItem<String?>(
                              value: b['name']?.toString(),
                              child: Text(b['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                            )),
                          ],
                          onChanged: (v) => setState(() => _brandName = v),
                        ),
                      ),
                    ),
                ] else ...[
                  _label('دسته‌بندی'),
                  const SizedBox(height: 8),
                  if (cats.isEmpty)
                    const Text('دسته‌ای یافت نشد', style: TextStyle(color: Colors.white38))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF252640),
                          menuMaxHeight: 220,
                          value: _categoryId,
                          hint: const Text('انتخاب دسته', style: TextStyle(color: Colors.white54)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('بدون دسته', style: TextStyle(color: Colors.white70))),
                            ...cats.map((c) {
                              final id = int.tryParse(c['id']?.toString() ?? '');
                              return DropdownMenuItem<int?>(
                                value: id,
                                child: Text(c['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _label('وزن (کیلوگرم)'),
                  const SizedBox(height: 8),
                  _field(_weight, 'اختیاری', number: true),
                  const SizedBox(height: 16),
                  _label('ابعاد (سانتی‌متر)'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _field(_length, 'طول', number: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_width, 'عرض', number: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_height, 'ارتفاع', number: true)),
                  ]),
                  const SizedBox(height: 16),
                  _label('روش ارسال'),
                  const SizedBox(height: 8),
                  if (_shipping.isEmpty)
                    const Text('روش ارسالی تعریف نشده', style: TextStyle(color: Colors.white38, fontSize: 12))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF252640), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF252640),
                          value: _shippingMethod,
                          menuMaxHeight: 220,
                          hint: const Text('انتخاب روش ارسال', style: TextStyle(color: Colors.white54)),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('پیش‌فرض', style: TextStyle(color: Colors.white70))),
                            ..._shipping.map((s) => DropdownMenuItem<String?>(
                              value: s['title']?.toString(),
                              child: Text(s['title']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                            )),
                          ],
                          onChanged: (v) => setState(() => _shippingMethod = v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _label('ویژگی محصول (اختیاری)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _attrs,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'مثال: رنگ: آبی، جنس: نخ پنبه',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF252640),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('قبلی'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_step < 2) {
                                setState(() => _step++);
                              } else {
                                _save();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(_step < 2 ? 'مرحله بعد' : 'ذخیره محصول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: Colors.white54, fontSize: 12));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF252640),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(hint),
    );
  }

  Widget _chip(String value, String label, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12)),
      selected: selected,
      selectedColor: color.withOpacity(0.35),
      backgroundColor: const Color(0xFF252640),
      onSelected: (_) => setState(() => _status = value),
    );
  }
}
