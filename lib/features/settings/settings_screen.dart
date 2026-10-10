import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifOrder = true;
  bool _notifStatus = true;
  bool _showPhone = true;
  bool _showAddress = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _notifOrder = p.getBool('fy_notif_order') ?? true;
      _notifStatus = p.getBool('fy_notif_status') ?? true;
      _showPhone = p.getBool('fy_show_phone') ?? true;
      _showAddress = p.getBool('fy_show_address') ?? true;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final user = auth.user?['display_name']?.toString() ?? '';

    if (_loading) return const Center(child: MiniLoader());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassHeader(
            title: 'تنظیمات',
            subtitle: '$siteName\n$user',
            actions: [
              IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeonCard(
              borderColor: AppColors.purple.withOpacity(0.3),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.visibility_outlined, color: AppColors.purpleGlow, size: 18),
                  SizedBox(width: 8),
                  Text('نمایش سفارش', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                _sw('نمایش موبایل مشتری', Icons.phone_android, _showPhone, (v) { setState(() => _showPhone = v); _save('fy_show_phone', v); }),
                _sw('نمایش آدرس', Icons.location_on_outlined, _showAddress, (v) { setState(() => _showAddress = v); _save('fy_show_address', v); }),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeonCard(
              borderColor: AppColors.blue.withOpacity(0.3),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.notifications_outlined, color: AppColors.blue, size: 18),
                  SizedBox(width: 8),
                  Text('اعلان‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                _sw('سفارش جدید', Icons.inventory_2_outlined, _notifOrder, (v) { setState(() => _notifOrder = v); _save('fy_notif_order', v); }),
                _sw('تغییر وضعیت سفارش', Icons.sync, _notifStatus, (v) { setState(() => _notifStatus = v); _save('fy_notif_status', v); }),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeonCard(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                    content: const Text('نسخه ۱.۴\ninfo@apadanasleep.ir', style: TextStyle(color: AppColors.textDim)),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
                  ),
                );
              },
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.textDim, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('درباره فروشگاه‌یار', style: TextStyle(color: Colors.white))),
                Text('۱.۴', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
                Icon(Icons.chevron_left, color: AppColors.textMute),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('خروج', style: TextStyle(color: Colors.white)),
                    content: const Text('از حساب خارج می‌شوید؟ توکن ذخیره می‌ماند.', style: TextStyle(color: AppColors.textDim)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج', style: TextStyle(color: AppColors.red))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AuthService>().logout(clearToken: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('خروج از حساب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.logout, size: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sw(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.textDim, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
      value: value,
      activeColor: AppColors.purple,
      onChanged: onChanged,
    );
  }
}
