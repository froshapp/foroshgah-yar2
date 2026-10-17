import 'package:flutter/material.dart';
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
  bool saving = false;
  bool showAdvanced = false;
  bool hasKey = false;
  int deviceCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('fcm-settings');
      if (res.data is Map) {
        hasKey = res.data['has_server_key'] == true;
        deviceCount = int.tryParse('${res.data['device_count'] ?? res.data['token_count'] ?? 0}') ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _saveKey() async {
    final key = keyCtrl.text.trim();
    if (key.isEmpty) return;
    setState(() => saving = true);
    try {
      await context.read<AuthService>().api.dio.post('fcm-settings', data: {'server_key': key});
      keyCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ذخیره شد'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ذخیره نشد'),
          backgroundColor: Color(0xFF7F1D1D),
        ));
      }
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _activate() async {
    final fcm = FcmService();
    await fcm.setEnabled(true);
    await fcm.syncToken(context.read<AuthService>());
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اعلان فعال شد'),
        backgroundColor: Color(0xFF065F46),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fcm = FcmService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'اعلان پوش',
          subtitle: 'دریافت سفارش جدید روی گوشی',
          leadingIcon: Icons.notifications_active_rounded,
          leadingColor: AppColors.blue,
          showSettingsGear: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              NeonCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال‌سازی اعلان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    fcm.enabled ? fcm.statusText : 'خاموش',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                  value: fcm.enabled,
                  activeColor: AppColors.purple,
                  onChanged: (v) async {
                    if (v) {
                      await _activate();
                    } else {
                      await fcm.setEnabled(false);
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              NeonCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _row('وضعیت', fcm.enabled ? 'فعال' : 'غیرفعال'),
                  _row('روش', fcm.gmsAvailable ? 'پوش گوگل + صف سرور' : 'صف سرور (هواوی و همه گوشی‌ها)'),
                  if (deviceCount > 0) _row('دستگاه‌های ثبت‌شده', '$deviceCount'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _activate,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('فعال‌سازی روی این گوشی'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'با روشن بودن، سفارش جدید به‌صورت خودکار روی گوشی نمایش داده می‌شود. روی هواوی بدون سرویس گوگل هم کار می‌کند.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.45),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => showAdvanced = !showAdvanced),
                child: Text(
                  showAdvanced ? 'بستن تنظیمات پیشرفته' : 'تنظیمات پیشرفته',
                  style: const TextStyle(color: AppColors.textDim),
                ),
              ),
              if (showAdvanced)
                NeonCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('کلید سرور فایربیس (اختیاری)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'فقط برای گوشی‌های دارای گوگل. برای هواوی لازم نیست.',
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
                      onPressed: saving ? null : _saveKey,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
                      child: Text(saving ? '...' : 'ذخیره'),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
          Flexible(child: Text(v, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
}
