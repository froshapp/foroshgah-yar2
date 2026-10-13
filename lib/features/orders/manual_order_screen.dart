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
  int step = 0; // 0 = products, 1 = checkout
  bool loadingProducts = true;
  bool submitting = false;
  List products = [];
  List categories = [];
  int? catFilter; // null = all
  final Map<int, int> cart = {};
  final searchCtrl = TextEditingController();

  // billing
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final company = TextEditingController();
  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final postcode = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final note = TextEditingController();
  String shipMethod = 'پیک موتوری';
  String payMethod = 'پرداخت هنگام دریافت';
  final shipCost = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    firstName.dispose();
    lastName.dispose();
    company.dispose();
    address1.dispose();
    address2.dispose();
    city.dispose();
    state.dispose();
    postcode.dispose();
    phone.dispose();
    email.dispose();
    note.dispose();
    shipCost.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loadingProducts = true);
    final auth = context.read<AuthService>();
    try {
      final cres = await auth.api.dio.get('products/categories');
      if (cres.data is Map && cres.data['categories'] is List) {
        categories = List.from(cres.data['categories'] as List);
      }
    } catch (_) {}
    try {
      final res = await auth.api.dio.get('products', queryParameters: {
        'per_page': 50,
        'page': 1,
        'status': 'publish',
      });
      if (res.data is Map && res.data['products'] is List) {
        products = List.from(res.data['products'] as List);
      }
    } catch (_) {
      products = [];
    }
    if (mounted) setState(() => loadingProducts = false);
  }

  List get _filtered {
    final q = searchCtrl.text.trim();
    return products.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      if (catFilter != null) {
        final cats = m['categories'] ?? m['category_ids'];
        bool ok = false;
        if (cats is List) {
          for (final c in cats) {
            final id = c is Map ? c['id'] : c;
            if (int.tryParse('$id') == catFilter) ok = true;
          }
        }
        if (!ok) return false;
      }
      if (q.isEmpty) return true;
      return (m['name']?.toString() ?? '').contains(q) || (m['id']?.toString() ?? '').contains(q);
    }).toList();
  }

  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  String _fmt(dynamic v) {
    final n = double.tryParse('$v'.replaceAll(',', '')) ?? 0;
    final s = n.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _submit() async {
    if (cart.isEmpty) {
      showErr(context, 'سبد خالی است');
      return;
    }
    if (firstName.text.trim().isEmpty && phone.text.trim().isEmpty) {
      showErr(context, 'نام یا تلفن مشتری را وارد کنید');
      return;
    }
    setState(() => submitting = true);
    try {
      final items = cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
      final res = await context.read<AuthService>().api.dio.post('orders', data: {
        'items': items,
        'status': 'pending',
        'note': note.text.trim(),
        'billing': {
          'first_name': firstName.text.trim(),
          'last_name': lastName.text.trim(),
          'company': company.text.trim(),
          'address_1': address1.text.trim(),
          'address_2': address2.text.trim(),
          'city': city.text.trim(),
          'state': state.text.trim(),
          'postcode': postcode.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
        },
        'shipping_method': shipMethod,
        'payment_method': payMethod,
        'shipping_total': double.tryParse(shipCost.text.replaceAll(',', '')) ?? 0,
      });
      final code = res.statusCode ?? 0;
      if (code >= 400) {
        showErr(context, res.data is Map ? '${res.data['message'] ?? 'خطا'}' : 'ثبت نشد');
      } else {
        showOk(context, 'سفارش ثبت شد');
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      showErr(context, '$e');
    }
    if (mounted) setState(() => submitting = false);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMute, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0B1230),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2A55))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2A55))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: step == 0 ? 'ثبت سفارش' : 'اطلاعات ثبت سفارش',
          subtitle: step == 0 ? 'انتخاب محصولات' : 'اطلاعات صورت حساب',
          leadingIcon: Icons.add_shopping_cart_rounded,
          leadingColor: AppColors.blue,
          actions: [
            if (step == 0)
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: cartCount == 0
                      ? null
                      : () => setState(() => step = 1),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
          ],
        ),
        Expanded(child: step == 0 ? _productsStep() : _checkoutStep()),
      ]),
    );
  }

  Widget _productsStep() {
    final list = _filtered;
    return Column(children: [
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
                  hintText: 'جستجو در تمام محصولات',
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
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = Map<String, dynamic>.from(list[i] as Map);
                      final id = int.tryParse('${m['id']}') ?? 0;
                      final name = m['name']?.toString() ?? '';
                      final price = m['price'] ?? m['regular_price'] ?? 0;
                      final sale = m['sale_price'];
                      final stock = m['stock_quantity'];
                      final st = (m['stock_status'] ?? '').toString();
                      final img = m['image']?.toString() ?? '';
                      final qty = cart[id] ?? 0;
                      final out = st == 'outofstock' || (stock != null && int.tryParse('$stock') == 0);

                      return NeonCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img.isNotEmpty
                                  ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                                  : _ph(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('#$id', style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${_fmt(price)} تومان', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                          if (sale != null && sale.toString().isNotEmpty && sale.toString() != '0')
                            Text('${_fmt(sale)}', style: const TextStyle(color: AppColors.red, fontSize: 11, decoration: TextDecoration.lineThrough)),
                          Text(
                            out ? 'موجودی: ۰' : 'موجودی: ${stock ?? '—'}',
                            style: TextStyle(color: out ? AppColors.red : AppColors.textMute, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          if (qty == 0)
                            GestureDetector(
                              onTap: out ? null : () => setState(() => cart[id] = 1),
                              child: Container(
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: out ? AppColors.surface : AppColors.purple.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.add_shopping_cart_rounded, color: out ? AppColors.textMute : Colors.white, size: 18),
                              ),
                            )
                          else
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMute, size: 22),
                                onPressed: () => setState(() {
                                  if (qty <= 1) cart.remove(id);
                                  else cart[id] = qty - 1;
                                }),
                              ),
                              Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.purple, size: 22),
                                onPressed: () => setState(() => cart[id] = qty + 1),
                              ),
                            ]),
                        ]),
                      );
                    },
                  ),
      ),
      // category chips
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          children: [
            _catChip(null, 'تمام محصولات'),
            ...categories.take(20).map((c) {
              final m = Map<String, dynamic>.from(c as Map);
              return _catChip(int.tryParse('${m['id']}'), m['name']?.toString() ?? '');
            }),
          ],
        ),
      ),
      if (cartCount > 0)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: ElevatedButton(
              onPressed: () => setState(() => step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('ادامه ($cartCount قلم)', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]);
  }

  Widget _catChip(int? id, String label) {
    final sel = catFilter == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textDim, fontSize: 12)),
        selected: sel,
        onSelected: (_) => setState(() => catFilter = id),
        selectedColor: AppColors.purple,
        backgroundColor: const Color(0xFF0B1230),
        side: BorderSide(color: sel ? AppColors.purple : const Color(0xFF1E2A55)),
      ),
    );
  }

  Widget _checkoutStep() {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            const Text('اطلاعات صورت حساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: firstName, style: const TextStyle(color: Colors.white), decoration: _dec('نام'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: lastName, style: const TextStyle(color: Colors.white), decoration: _dec('نام خانوادگی'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: company, style: const TextStyle(color: Colors.white), decoration: _dec('شرکت')),
            const SizedBox(height: 10),
            TextField(controller: address1, style: const TextStyle(color: Colors.white), decoration: _dec('نام خیابان و پلاک خانه')),
            const SizedBox(height: 10),
            TextField(controller: address2, style: const TextStyle(color: Colors.white), decoration: _dec('آپارتمان، مجتمع، واحد و...')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: state, style: const TextStyle(color: Colors.white), decoration: _dec('استان'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: city, style: const TextStyle(color: Colors.white), decoration: _dec('شهر'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: postcode, style: const TextStyle(color: Colors.white), decoration: _dec('کد پستی'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: phone, style: const TextStyle(color: Colors.white), decoration: _dec('تلفن'), keyboardType: TextInputType.phone)),
            ]),
            const SizedBox(height: 10),
            TextField(controller: email, style: const TextStyle(color: Colors.white), decoration: _dec('ایمیل'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextField(controller: note, style: const TextStyle(color: Colors.white), decoration: _dec('یادداشت مشتری'), maxLines: 2),
            const SizedBox(height: 18),
            const Text('اطلاعات حمل و نقل و پرداخت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1230),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2A55)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: shipMethod,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'پیک موتوری', child: Text('پیک موتوری')),
                        DropdownMenuItem(value: 'پست پیشتاز', child: Text('پست پیشتاز')),
                        DropdownMenuItem(value: 'تیپاکس', child: Text('تیپاکس')),
                        DropdownMenuItem(value: 'تحویل حضوری', child: Text('تحویل حضوری')),
                      ],
                      onChanged: (v) => setState(() => shipMethod = v ?? shipMethod),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: shipCost, style: const TextStyle(color: Colors.white), decoration: _dec('مبلغ حمل'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2A55)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: payMethod,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'پرداخت هنگام دریافت', child: Text('پرداخت هنگام دریافت')),
                    DropdownMenuItem(value: 'کارت به کارت', child: Text('کارت به کارت')),
                    DropdownMenuItem(value: 'درگاه آنلاین', child: Text('درگاه آنلاین')),
                  ],
                  onChanged: (v) => setState(() => payMethod = v ?? payMethod),
                ),
              ),
            ),
          ],
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1E2A55)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('بازگشت'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: submitting
                    ? const MiniLoader(size: 22)
                    : const Text('ثبت سفارش', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _ph() => Container(
        color: AppColors.surface,
        child: const Icon(Icons.image_outlined, color: AppColors.textMute, size: 28),
      );
}
