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
  Map data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final auth = context.read<AuthService>();
      Map merged = {};
      try {
        final res = await auth.api.dio.get('site-info');
        if (res.data is Map) merged.addAll(Map.from(res.data as Map));
      } catch (_) {}
      try {
        final res2 = await auth.api.dio.get('site-status');
        if (res2.data is Map) {
          final m = Map.from(res2.data as Map);
          // map alternate keys
          if (m['wordpress'] != null) merged['wp_version'] = m['wordpress'];
          if (m['php'] != null) merged['php_version'] = m['php'];
          if (m['woocommerce'] != null) merged['wc_version'] = m['woocommerce'];
          if (m['theme'] != null) merged['theme'] = m['theme'];
          if (m['active_plugins'] != null) merged['active_plugins_count'] = m['active_plugins'];
          if (m['orders_today'] != null) merged['orders_today'] = m['orders_today'];
          merged.addAll(m);
        }
      } catch (_) {}
      // fallback از auth.site
      final site = auth.site ?? {};
      merged.putIfAbsent('name', () => site['name'] ?? '');
      merged.putIfAbsent('url', () => site['url'] ?? '');
      merged.putIfAbsent('currency', () => site['currency'] ?? 'IRT');
      data = merged;
      if (data.isEmpty) error = 'اطلاعاتی دریافت نشد';
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 13))),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          showSettingsGear: false,
          title: 'وضعیت سایت',
          subtitle: 'اطلاعات فنی وردپرس و ووکامرس',
          leadingIcon: Icons.monitor_heart_outlined,
          leadingColor: AppColors.cyan,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : RefreshIndicator(
                      color: AppColors.purple,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        children: [
                          NeonCard(
                            child: Column(children: [
                              _row('نام سایت', '${data['name'] ?? '—'}'),
                              _row('آدرس', '${data['url'] ?? '—'}'),
                              _row('ایمیل مدیر', '${data['admin_email'] ?? '—'}'),
                              _row('واحد پول', '${data['currency_symbol'] ?? ''} ${data['currency'] ?? ''}'),
                              _row('منطقه زمانی', '${data['timezone'] ?? '—'}'),
                              _row('زبان', '${data['language'] ?? '—'}'),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          NeonCard(
                            child: Column(children: [
                              _row('وردپرس', '${data['wp_version'] ?? '—'}'),
                              _row('ووکامرس', '${data['wc_version'] ?? '—'}'),
                              _row('PHP', '${data['php_version'] ?? '—'}'),
                              _row('افزونه فروشگاه‌یار', '${data['plugin_version'] ?? '—'}'),
                              _row('قالب', '${data['theme'] ?? '—'}'),
                              _row('افزونه‌های فعال', '${data['active_plugins'] ?? '—'}'),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          NeonCard(
                            child: Column(children: [
                              _row('سفارش امروز', '${data['orders_today'] ?? 0}', valueColor: AppColors.purpleGlow),
                              _row('تعداد محصولات', '${data['products_count'] ?? 0}'),
                              _row('تعداد کاربران', '${data['users_count'] ?? 0}'),
                              _row('حافظه PHP', '${data['memory_limit'] ?? '—'}'),
                              if (data['disk_free_mb'] != null)
                                _row('فضای آزاد', '${data['disk_free_mb']} MB از ${data['disk_total_mb'] ?? '?'} MB'),
                              _row('SSL', data['ssl'] == true ? 'فعال' : 'غیرفعال',
                                  valueColor: data['ssl'] == true ? AppColors.green : AppColors.orange),
                              _row('حالت دیباگ', data['debug'] == true ? 'روشن' : 'خاموش',
                                  valueColor: data['debug'] == true ? AppColors.orange : AppColors.green),
                            ]),
                          ),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }
}
