import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  final _sku = TextEditingController();
  final _desc = TextEditingController();
  String _status = 'publish';
  bool _saving = false;
  XFile? _image;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _sku.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final f = await _picker.pickImage(source: src, maxWidth: 1200, imageQuality: 85);
    if (f != null) setState(() => _image = f);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام محصول الزامی است')));
      return;
    }
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthService>();
      try {
        await auth.api.ensureReachable();
      } catch (_) {}

      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'type': 'simple',
        'status': _status,
        'regular_price': _price.text.trim().isEmpty ? '0' : _price.text.trim(),
        'price': _price.text.trim().isEmpty ? '0' : _price.text.trim(),
        'description': _desc.text.trim(),
        'short_description': _desc.text.trim().length > 120
            ? _desc.text.trim().substring(0, 120)
            : _desc.text.trim(),
      };
      if (_salePrice.text.trim().isNotEmpty) {
        body['sale_price'] = _salePrice.text.trim();
      }
      if (_sku.text.trim().isNotEmpty) body['sku'] = _sku.text.trim();
      if (_stock.text.trim().isNotEmpty) {
        body['manage_stock'] = true;
        body['stock_quantity'] = int.tryParse(_stock.text.trim()) ?? 0;
      }

      // create product first
      final res = await auth.api.dio.post('products', data: body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(res.data?['message']?.toString() ?? 'خطا در ذخیره');
      }

      final productId = res.data is Map ? res.data['id'] : null;

      // upload image if selected (best-effort)
      if (_image != null && productId != null) {
        try {
          final form = FormData.fromMap({
            'file': await MultipartFile.fromFile(_image!.path, filename: _image!.name),
          });
          // try media then attach
          final media = await auth.api.dio.post(
            '../wp/v2/media',
            data: form,
            options: Options(contentType: 'multipart/form-data', headers: {
              'Content-Disposition': 'attachment; filename="${_image!.name}"',
            }),
          );
          final mediaId = media.data is Map ? media.data['id'] : null;
          if (mediaId != null) {
            await auth.api.dio.put('products/$productId', data: {
              'images': [{'id': mediaId}],
            });
          }
        } catch (_) {
          // image optional
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محصول اضافه شد')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        title: const Text('افزودن محصول', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('وضعیت محصول'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _chip('publish', 'منتشر شده', const Color(0xFF10B981)),
            _chip('draft', 'پیش‌نویس', Colors.orange),
            _chip('pending', 'در انتظار', Colors.white54),
          ]),
          const SizedBox(height: 16),
          _label('تصویر شاخص'),
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('گالری', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('دوربین', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          _label('نام محصول'),
          const SizedBox(height: 8),
          _field(_name, 'مثلاً روتختی طرح ملودی'),
          const SizedBox(height: 16),
          _label('توضیحات'),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'توضیحات محصول...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF252640),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('ذخیره محصول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: Colors.white54, fontSize: 12));

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF252640),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
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
