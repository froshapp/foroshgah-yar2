import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/nav.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBack;

  void goTo(int i) => setState(() => index = i);

  @override
  void initState() {
    super.initState();
    AppNav.goToTab = goTo;
    AppNav.scaffoldKey = _scaffoldKey;
  }

  @override
  void dispose() {
    if (AppNav.goToTab == goTo) AppNav.goToTab = null;
    if (AppNav.scaffoldKey == _scaffoldKey) AppNav.scaffoldKey = null;
    super.dispose();
  }

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
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // اول مسیرهای push شده (جزئیات سفارش، مشتری، ...) را ببند
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          nav.pop();
          return;
        }
        if (index != 0) {
          setState(() => index = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
          _lastBack = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('برای خروج دوباره دکمه بازگشت را بزنید'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF2A2A4A),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: Drawer(
        backgroundColor: AppColors.bg,
        width: MediaQuery.of(context).size.width * 0.88,
        child: const SettingsScreen(asDrawer: true),
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1430),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF252B4A)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6)),
          ],
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: active
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [AppColors.purple.withOpacity(0.35), AppColors.blue.withOpacity(0.2)],
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : AppColors.textMute, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textMute, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
            if (active)
              Container(margin: const EdgeInsets.only(top: 3), width: 16, height: 3, decoration: BoxDecoration(color: AppColors.purpleGlow, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }
}
