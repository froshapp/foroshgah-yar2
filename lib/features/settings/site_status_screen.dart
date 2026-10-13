import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class SiteStatusScreen extends StatefulWidget {
  const SiteStatusScreen({super.key});
  @override
  State<SiteStatusScreen> createState() => _SiteStatusScreenState();
}

class _SiteStatusScreenState extends State<SiteStatusScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    final auth = context.read<AuthService>();
    try {
      Map<String, dynamic> merged = {};
      try {
        final a = await auth.api.dio.get('site-info');
        if (a.data is Map) merged.addAll(Map<String, dynamic>.from(a.data as Map));
      } catch (_) {}
      try {
        final b = await auth.api.dio.get('site-status');
        if (b.data is Map) merged.addAll(Map<String, dynamic>.from(b.data as Map));
      } catch (_) {}
      data = merged;
    } catch (e) {
      error = 'خطا در دریافت وضعیت سایت';
    }
    if (mounted) setState(() => loading = false);
  }

  String _v(String k, [String alt = '—']) {
    final v = data[k];
    if (v == null || v.toString().isEmpty) return alt;
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('نام سایت', _v('name')),
      ('آدرس', _v('url', _v('site_url'))),
      ('ایمیل مدیر', _v('admin_email')),
      ('زبان', _v('language', _v('locale'))),
      ('افزونه فروشگاه‌یار', '${_v('plugin_name', 'فروشگاه‌یار')} ${_v('plugin_version')}'),
      ('قالب', _v('theme')),
      ('وردپرس', _v('wp_version', _v('wordpress'))),
      ('ووکامرس', _v('wc_version', _v('woocommerce'))),
      ('PHP', _v('php_version', _v('php'))),
      ('سفارش امروز', _v('orders_today')),
      ('محصولات', _v('products_count')),
      ('کاربران', _v('users_count')),
      ('SSL', data['ssl'] == true ? 'فعال' : 'غیرفعال'),
      ('منطقه زمانی', _v('timezone')),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            GlassHeader(title: 'وضعیت سایت', subtitle: 'اطلاعات وردپرس و فروشگاه', showBell: false),
            if (loading)
              const Expanded(child: Center(child: MiniLoader()))
            else if (error != null)
              Expanded(child: Center(child: Text(error!, style: const TextStyle(color: AppColors.red))))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.purple,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return NeonCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(r.$1, style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
                            Flexible(child: Text(r.$2, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
