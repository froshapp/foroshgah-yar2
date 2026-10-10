import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final user = auth.user?['display_name']?.toString() ?? '';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: const Color(0xFF252640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تنظیمات', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(siteName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                if (user.isNotEmpty)
                  Text('کاربر: $user', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _item(Icons.receipt_long, 'نمایش سفارش', 'تنظیم فیلدهای لیست سفارش', () => _soon(context)),
                _item(Icons.tune, 'وضعیت سفارش', 'برچسب و رنگ وضعیت‌ها', () => _soon(context)),
                _item(Icons.notifications_outlined, 'نوتیفیکیشن', 'هشدار سفارش جدید', () => _soon(context)),
                _item(Icons.description_outlined, 'فاکتور', 'تنظیمات چاپ فاکتور', () => _soon(context)),
                _item(Icons.local_shipping_outlined, 'برچسب حمل و نقل', 'تنظیم برچسب پستی', () => _soon(context)),
                _item(Icons.phone_outlined, 'تماس', 'تنظیمات تماس و واتساپ', () => _soon(context)),
                const Divider(color: Colors.white12, height: 24),
                _item(Icons.info_outline, 'درباره اپ', 'نسخه ۱.۳', () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF252640),
                      title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                      content: const Text('نسخه ۱.۳\nمدیریت فروشگاه ووکامرس', style: TextStyle(color: Colors.white70)),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF252640),
                          title: const Text('خروج', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'از حساب خارج می‌شوید؟\nتوکن ذخیره می‌ماند.',
                            style: TextStyle(color: Colors.white70),
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
                      if (ok == true && context.mounted) {
                        await context.read<AuthService>().logout(clearToken: false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('خروج از حساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('این بخش به‌زودی فعال می‌شود'), duration: Duration(seconds: 2)),
    );
  }

  Widget _item(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: const Icon(Icons.chevron_left, color: Colors.white24),
      onTap: onTap,
    );
  }
}
