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
import '../modules/customers_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  /// 0 پیشخوان | 1 سفارشات | 2 محصولات | 3 ماژول‌ها | 4 بیشتر
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
      const _MoreTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
              backgroundColor: Color(0xFF152048),
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
          width: MediaQuery.of(context).size.width * 0.82,
          child: const SettingsScreen(asDrawer: true),
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1230),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF1E2A55)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ترتیب بصری RTL: ماژول‌ها | محصولات | پیشخوان | سفارشات | بیشتر
                _nav(3, Icons.grid_view_rounded, 'ماژول‌ها'),
                _nav(2, Icons.inventory_2_outlined, 'محصولات'),
                _nav(0, Icons.home_rounded, 'پیشخوان'),
                _nav(1, Icons.shopping_cart_outlined, 'سفارشات'),
                _nav(4, Icons.more_horiz_rounded, 'بیشتر'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final active = index == i;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (i == 4) {
            // بیشتر = باز کردن دراور تنظیمات
            _scaffoldKey.currentState?.openDrawer();
            return;
          }
          setState(() => index = i);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: active
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7047F5), Color(0xFF2868FF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? Colors.white : AppColors.textMute, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMute,
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// تب بیشتر — میانبرهای سریع مثل مرجع
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const GlassHeader(
            title: 'بیشتر',
            subtitle: 'میانبرها و تنظیمات',
            leadingIcon: Icons.apps_rounded,
            leadingColor: AppColors.blue,
          ),
          const SizedBox(height: 12),
          _item(context, Icons.people_alt_rounded, 'مشتریان', 'مدیریت مشتریان', AppColors.purple, const CustomersScreen()),
          _item(context, Icons.phone_in_talk_rounded, 'تماس‌ها', 'تماس سریع', AppColors.cyan, const ContactsScreen()),
          _item(context, Icons.settings_outlined, 'تنظیمات', 'پروفایل و تنظیمات فروشگاه', AppColors.blue, null, openDrawer: true),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, String sub, Color c, Widget? page, {bool openDrawer = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: NeonCard(
        onTap: () {
          if (openDrawer) {
            AppNav.openSettingsDrawer();
            return;
          }
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
        child: Row(children: [
          SoftIconBox(icon: icon, color: c, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ]),
          ),
          const Icon(Icons.chevron_left, color: AppColors.textMute),
        ]),
      ),
    );
  }
}
