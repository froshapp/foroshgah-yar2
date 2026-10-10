import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../products/add_product_screen.dart';
import '../settings/settings_screen.dart';
import '../contacts/contacts_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  Future<void> openAddProduct() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (ok == true && mounted) setState(() => index = 2);
  }

  Future<void> openContacts() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onNavigate: goTo,
        onAddProduct: openAddProduct,
        onContacts: openContacts,
      ),
      const OrdersScreen(),
      const ProductsScreen(),
      const SettingsScreen(),
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
                _nav(3, Icons.settings_rounded, 'تنظیمات'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final active = index == i;
    return InkWell(
      onTap: () => setState(() => index = i),
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
