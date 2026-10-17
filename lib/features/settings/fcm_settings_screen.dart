import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/app_theme.dart';

class FcmSettingsScreen extends StatefulWidget {
  const FcmSettingsScreen({super.key});
  @override
  State<FcmSettingsScreen> createState() => _FcmSettingsScreenState();
}

class _FcmSettingsScreenState extends State<FcmSettingsScreen> {
  final keyCtrl = TextEditingController();
  bool loading = true;
  bool saving = false;
  bool syncing = false;
  bool hasKey = false;
  int tokenCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _friendlyError(String? e) {
    if (e == null || e.isEmpty) return '';
    final s = e.toLowerCase();
    if (s.contains('missing_instanceid') || s.contains('instanceid')) {
      return 'سرویس گوگل پلی روی این گوشی در دسترس نیست یا نیاز به به‌روزرسانی دارد.';
    }
    if (s.contains('firebaseoptions') || s.contains('values.xml')) {
      return 'پیکربندی فایربیس ناقص است. اپ را از بیلد جدید نصب کنید.';
    }
    if (s.contains('غیرفعال')) return e;
    if (s.contains('network') || s.contains('socket')) {
      return 'اتصال اینترنت برقرار نیست.';
    }
    return 'راه‌اندازی اعلان با مشکل مواجه شد. سرویس گوگل پلی و اینترنت را بررسی کنید.';
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await context.read<AuthService>().api.dio.get('fcm-settings');
      if (res.data is Map) {
        hasKey = res.data['has_server_key'] == true;
        tokenCount = int.tryParse('${res.data['token_count'] ?? 0}') ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final key = keyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کلید سرور را وارد کنید')));
      return;
    }
    setState(() => saving = true);
    try {
      await context.read<AuthService>().api.dio.post('fcm-settings', data: {'server_key': key});
      keyCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('کلید ذخیره شد'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ذخیره کلید ناموفق بود'),
          backgroundColor: Color(0xFF7F1D1D),
        ));
      }
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _syncDevice() async {
    setState(() => syncing = true);
    final fcm = FcmService();
    if (!fcm.enabled) {
      await fcm.setEnabled(true);
    }
    if (!fcm.ready) {
      await fcm.init();
    }
    final ok = await fcm.syncToken(context.read<AuthService>());
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'این گوشی برای دریافت اعلان ثبت شد'
            : _friendlyError(fcm.lastError).isNotEmpty
                ? _friendlyError(fcm.lastError)
                : 'ثبت انجام نشد. گوگل پلی سرویس را بررسی کنید'),
        backgroundColor: ok ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
      ));
      setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fcm = FcmService();
    final err = _friendlyError(fcm.lastError);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'اعلان پوش',
          subtitle: 'دریافت اعلان سفارش روی گوشی',
          leadingIcon: Icons.notifications_active_rounded,
          leadingColor: AppColors.blue,
          showSettingsGear: false,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    NeonCard(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('فعال‌سازی اعلان پوش', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          fcm.enabled ? 'روشن — سفارش جدید به گوشی می‌آید' : 'خاموش',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                        value: fcm.enabled,
                        activeColor: AppColors.purple,
                        onChanged: (v) async {
                          await fcm.setEnabled(v);
                          setState(() {});
                          if (v) await _syncDevice();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _row('وضعیت', fcm.ready ? 'آماده' : 'غیرفعال'),
                        _row('کلید سرور', hasKey ? 'تنظیم شده' : 'تنظیم نشده'),
                        _row('دستگاه‌های ثبت‌شده', '$tokenCount'),
                        if (err.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(err, style: const TextStyle(color: AppColors.red, fontSize: 12, height: 1.4)),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: syncing ? null : _syncDevice,
                          icon: const Icon(Icons.phonelink_setup, size: 18),
                          label: Text(syncing ? '...' : 'ثبت این گوشی'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    NeonCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Text('کلید سرور فایربیس', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text(
                          'از کنسول فایربیس → تنظیمات پروژه → Cloud Messaging کپی کنید',
                          style: TextStyle(color: AppColors.textDim, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: keyCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Server Key',
                            hintStyle: const TextStyle(color: AppColors.textMute),
                            filled: true,
                            fillColor: const Color(0xFF0B1230),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(saving ? '...' : 'ذخیره کلید سرور'),
                        ),
                      ]),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(k, style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}
