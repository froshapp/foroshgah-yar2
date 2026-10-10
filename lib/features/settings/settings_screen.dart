import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';

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

    if (_loading) {
      return const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6C63FF))));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: const Color(0xFF252640),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('تنظیمات', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(siteName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (user.isNotEmpty) Text('کاربر: $user', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('نمایش سفارش', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          SwitchListTile(
            title: const Text('نمایش موبایل مشتری', style: TextStyle(color: Colors.white)),
            value: _showPhone,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (v) {
              setState(() => _showPhone = v);
              _save('fy_show_phone', v);
            },
          ),
          SwitchListTile(
            title: const Text('نمایش آدرس', style: TextStyle(color: Colors.white)),
            value: _showAddress,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (v) {
              setState(() => _showAddress = v);
              _save('fy_show_address', v);
            },
          ),
          const Divider(color: Colors.white12),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('اعلان‌ها', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          SwitchListTile(
            title: const Text('سفارش جدید', style: TextStyle(color: Colors.white)),
            value: _notifOrder,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (v) {
              setState(() => _notifOrder = v);
              _save('fy_notif_order', v);
            },
          ),
          SwitchListTile(
            title: const Text('تغییر وضعیت سفارش', style: TextStyle(color: Colors.white)),
            value: _notifStatus,
            activeColor: const Color(0xFF6C63FF),
            onChanged: (v) {
              setState(() => _notifStatus = v);
              _save('fy_notif_status', v);
            },
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: const Text('درباره فروشگاه‌یار', style: TextStyle(color: Colors.white)),
            subtitle: const Text('نسخه ۱.۳', style: TextStyle(color: Colors.white38)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF252640),
                  title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                  content: const Text('نسخه ۱.۳\nمدیریت فروشگاه ووکامرس', style: TextStyle(color: Colors.white70)),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF252640),
                    title: const Text('خروج', style: TextStyle(color: Colors.white)),
                    content: const Text('از حساب خارج می‌شوید؟\nتوکن ذخیره می‌ماند.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج', style: TextStyle(color: Colors.redAccent))),
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
    );
  }
}
