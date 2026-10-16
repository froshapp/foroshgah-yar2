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
  String? msg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; msg = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('fcm-settings');
      if (res.data is Map) {
        hasKey = res.data['has_server_key'] == true;
        tokenCount = int.tryParse('${res.data['token_count'] ?? 0}') ?? 0;
      }
    } catch (e) {
      msg = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final key = keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => msg = 'کلید سرور را وارد کنید');
      return;
    }
    setState(() { saving = true; msg = null; });
    try {
      await context.read<AuthService>().api.dio.post('fcm-settings', data: {'server_key': key});
      keyCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('کلید FCM ذخیره شد'),
          backgroundColor: Color(0xFF065F46),
        ));
      }
    } catch (e) {
      msg = '$e';
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _syncDevice() async {
    setState(() => syncing = true);
    final fcm = FcmService();
    if (!fcm.ready) {
      await fcm.init();
    }
    final ok = await fcm.syncToken(context.read<AuthService>());
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'توکن این گوشی ثبت شد' : 'ثبت نشد — google-services.json واقعی لازم است'),
        backgroundColor: ok ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
      ));
      setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fcm = FcmService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'اعلان پوش (FCM)',
          subtitle: 'Firebase Cloud Messaging',
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('وضعیت سرور', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
                        const SizedBox(height: 8),
                        _row('کلید سرور', hasKey ? 'تنظیم شده ✓' : 'تنظیم نشده'),
                        _row('دستگاه‌های ثبت‌شده', '$tokenCount'),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    NeonCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('وضعیت این گوشی', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
                        const SizedBox(height: 8),
                        _row('Firebase', fcm.ready ? 'آماده ✓' : 'غیرفعال'),
                        if (fcm.token != null && fcm.token!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text('توکن دستگاه', style: TextStyle(color: AppColors.textMute, fontSize: 11)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                              child: Text(
                                '${fcm.token!.substring(0, fcm.token!.length > 28 ? 28 : fcm.token!.length)}…',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: AppColors.purpleGlow),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: fcm.token!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('توکن کپی شد')),
                                );
                              },
                            ),
                          ]),
                        ],
                        if (fcm.lastError != null) ...[
                          const SizedBox(height: 6),
                          Text('خطا: ${fcm.lastError}', style: const TextStyle(color: AppColors.red, fontSize: 11)),
                        ],
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: syncing ? null : _syncDevice,
                          icon: const Icon(Icons.phonelink_setup, size: 18),
                          label: Text(syncing ? '...' : 'ثبت این گوشی برای اعلان'),
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
                        const Text('Server Key فایربیس', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text(
                          'Firebase Console → Project settings → Cloud Messaging → Server key',
                          style: TextStyle(color: AppColors.textDim, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: keyCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'AAAA... Server Key',
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
                        if (msg != null) ...[
                          const SizedBox(height: 8),
                          Text(msg!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 12),
                    const NeonCard(
                      child: Text(
                        'برای کار واقعی:\n'
                        '۱) در Firebase یک اپ Android با پکیج ir.apadanasleep.foroshgah_yar بساز\n'
                        '۲) google-services.json را در android_templates بگذار و APK بساز\n'
                        '۳) Server Key را اینجا ذخیره کن\n'
                        '۴) دکمه «ثبت این گوشی» را بزن\n'
                        '۵) یک سفارش تستی ثبت کن — باید اعلان بیاید',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.55),
                      ),
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
