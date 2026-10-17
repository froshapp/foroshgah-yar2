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
  bool busy = false;

  Future<void> _activate() async {
    setState(() => busy = true);
    final fcm = FcmService();
    await fcm.setEnabled(true);
    await fcm.syncToken(context.read<AuthService>());
    if (mounted) {
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اعلان فعال شد'),
        backgroundColor: Color(0xFF065F46),
      ));
    }
  }

  Future<void> _deactivate() async {
    setState(() => busy = true);
    await FcmService().setEnabled(false);
    if (mounted) {
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اعلان غیرفعال شد'),
        backgroundColor: Color(0xFF374151),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fcm = FcmService();
    final on = fcm.enabled;
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
                borderColor: on ? AppColors.purple.withOpacity(0.4) : null,
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? const Color(0xFF10B981) : AppColors.textMute,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(on ? 'فعال' : 'غیرفعال', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        on ? fcm.statusText : 'اعلان سفارش خاموش است',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                    ]),
                  ),
                  Switch(
                    value: on,
                    activeColor: AppColors.purple,
                    onChanged: busy
                        ? null
                        : (v) async {
                            if (v) {
                              await _activate();
                            } else {
                              await _deactivate();
                            }
                          },
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              NeonCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _row('وضعیت', on ? 'فعال' : 'غیرفعال'),
                  _row('روش', on ? (fcm.gmsAvailable ? 'پوش گوگل + صف سرور' : 'صف سرور (هواوی و همه گوشی‌ها)') : '—'),
                  const SizedBox(height: 12),
                  if (on)
                    OutlinedButton.icon(
                      onPressed: busy ? null : _activate,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('ثبت مجدد این گوشی'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppColors.purple.withOpacity(0.5)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: busy ? null : _activate,
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('فعال‌سازی اعلان'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'با روشن بودن، سفارش جدید روی گوشی نمایش داده می‌شود. روی هواوی بدون سرویس گوگل هم کار می‌کند.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.45),
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
