import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../products/add_product_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void goTo(int i) => setState(() => index = i);

  Future<void> openAddProduct() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (ok == true && mounted) {
      setState(() => index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه‌یار';

    final pages = [
      DashboardScreen(onNavigate: goTo, onAddProduct: openAddProduct),
      const OrdersScreen(),
      const ProductsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1B2E),
      drawer: _SettingsDrawer(
        siteName: siteName,
        userName: auth.user?['display_name']?.toString() ?? '',
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF252640),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nav(0, Icons.home_rounded, 'داشبورد'),
                _nav(1, Icons.receipt_long_rounded, 'سفارشات'),
                _nav(2, Icons.inventory_2_rounded, 'محصولات'),
                _nav(-1, Icons.settings_rounded, 'تنظیمات', onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label, {VoidCallback? onTap}) {
    final active = index == i;
    return InkWell(
      onTap: onTap ?? () => setState(() => index = i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF6C63FF) : Colors.white38, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: active ? const Color(0xFF6C63FF) : Colors.white38,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

/// منوی تنظیمات (مثل ویرا) — فقط تنظیمات، بدون افزودن محصول
class _SettingsDrawer extends StatelessWidget {
  final String siteName;
  final String userName;
  const _SettingsDrawer({required this.siteName, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1B2E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF252640)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تنظیمات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(siteName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  if (userName.isNotEmpty)
                    Text('کاربر: $userName', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _item(Icons.receipt_long_outlined, 'نمایش سفارش', 'به‌زودی'),
            _item(Icons.tune, 'وضعیت سفارش', 'به‌زودی'),
            _item(Icons.notifications_none, 'نوتیفیکیشن', 'به‌زودی'),
            _item(Icons.description_outlined, 'فاکتور', 'به‌زودی'),
            _item(Icons.local_shipping_outlined, 'برچسب حمل و نقل', 'به‌زودی'),
            _item(Icons.phone_outlined, 'تماس', 'به‌زودی'),
            const Divider(color: Colors.white12, height: 24),
            _item(Icons.info_outline, 'درباره اپ', 'نسخه ۱.۲', onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF252640),
                  title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                  content: const Text('نسخه ۱.۲\nمدیریت فروشگاه ووکامرس', style: TextStyle(color: Colors.white70)),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthService>().logout(clearToken: false);
                },
                icon: const Icon(Icons.logout),
                label: const Text('خروج از حساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 11)),
      trailing: const Icon(Icons.chevron_left, color: Colors.white24, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
