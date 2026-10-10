import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../modules/modules_screen.dart';
import '../settings/settings_screen.dart';
import '../products/add_product_screen.dart';
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
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
    if (ok == true && mounted) setState(() => index = 2);
  }

  Future<void> openContacts() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigate: goTo, onAddProduct: openAddProduct, onContacts: openContacts),
      const OrdersScreen(),
      const ProductsScreen(),
      const ModulesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(0, Icons.home_rounded, 'خانه'),
              _nav(1, Icons.receipt_long_rounded, 'سفارشات'),
              _nav(2, Icons.inventory_2_rounded, 'محصولات'),
              _nav(3, Icons.grid_view_rounded, 'ماژول‌ها'),
              _nav(4, Icons.settings_rounded, 'تنظیمات'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final active = index == i;
    return InkWell(
      onTap: () => setState(() => index = i),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.purpleGlow : AppColors.textMute, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: active ? AppColors.purpleGlow : AppColors.textMute, fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            if (active)
              Container(margin: const EdgeInsets.only(top: 3), width: 14, height: 2, decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }
}
