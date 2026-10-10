import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigate: goTo),
      const OrdersScreen(),
      const ProductsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
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
                _nav(-1, Icons.logout_rounded, 'خروج', onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF252640),
                      title: const Text('خروج', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'از پنل خارج می‌شوید؟\nتوکن ذخیره می‌ماند و لازم نیست دوباره وارد کنید.',
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('خروج', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    // توکن پاک نمی‌شود
                    await context.read<AuthService>().logout(clearToken: false);
                  }
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
