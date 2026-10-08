import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/store_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<StoreService>();
    final siteName = auth.site?['name']?.toString() ??
        store.currentStore?.name ??
        'فروشگاه';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252640),
        title: Text(siteName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'سلام ${auth.user?['display_name'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              store.currentStore?.url ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 28),
            _card(
              icon: Icons.shopping_bag_outlined,
              title: 'سفارشات',
              subtitle: 'مدیریت و تغییر وضعیت سفارش‌ها',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('بخش سفارشات در نسخه بعد فعال می‌شود')),
                );
              },
            ),
            const SizedBox(height: 12),
            _card(
              icon: Icons.inventory_2_outlined,
              title: 'محصولات',
              subtitle: 'افزودن و ویرایش محصولات',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('بخش محصولات در نسخه بعد فعال می‌شود')),
                );
              },
            ),
            const SizedBox(height: 12),
            _card(
              icon: Icons.bar_chart_rounded,
              title: 'داشبورد',
              subtitle: 'آمار فروش و گزارش‌ها',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('داشبورد در نسخه بعد فعال می‌شود')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF252640),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
