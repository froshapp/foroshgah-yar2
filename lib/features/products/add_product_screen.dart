import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _sku = TextEditingController();
  String _status = 'publish';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _sku.dispose();
    super.dispose();
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
      };
      if (_sku.text.trim().isNotEmpty) body['sku'] = _sku.text.trim();
      if (_stock.text.trim().isNotEmpty) {
        body['manage_stock'] = true;
        body['stock_quantity'] = int.tryParse(_stock.text.trim()) ?? 0;
      }

      final res = await auth.api.dio.post('products', data: body);
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
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
          Row(
            children: [
              _statusChip('publish', 'منتشر شده', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _statusChip('draft', 'پیش‌نویس', Colors.orange),
              const SizedBox(width: 8),
              _statusChip('pending', 'در انتظار', Colors.white54),
            ],
          ),
          const SizedBox(height: 20),
          _label('نام محصول'),
          const SizedBox(height: 8),
          _field(_name, 'مثلاً روتختی طرح ملودی'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('قیمت (تومان)'),
                const SizedBox(height: 8),
                _field(_price, '0', number: true),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('موجودی'),
                const SizedBox(height: 8),
                _field(_stock, 'اختیاری', number: true),
              ])),
            ],
          ),
          const SizedBox(height: 16),
          _label('شناسه / SKU'),
          const SizedBox(height: 8),
          _field(_sku, 'اختیاری'),
          const SizedBox(height: 32),
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

  Widget _statusChip(String value, String label, Color color) {
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
