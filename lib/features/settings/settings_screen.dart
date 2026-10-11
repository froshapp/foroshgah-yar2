import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';
import 'plugins_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassHeader(
            title: 'تنظیمات',
            subtitle: (auth.site?['name']?.toString().isNotEmpty == true)
                ? auth.site!['name'].toString()
                : (auth.user?['display_name']?.toString() ?? 'فروشگاه‌یار'),
          ),
          const SizedBox(height: 12),
          
            _item(Icons.extension, 'افزونه‌های سایت', 'فعال و غیرفعال کردن افزونه‌ها', AppColors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PluginsScreen()));
            }),
_item(Icons.palette_outlined, 'رنگ وضعیت سفارشات', 'شخصی‌سازی رنگ‌ها', AppColors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatusColorsPage()));
          }),
          _item(Icons.inventory_2_outlined, 'آستانه موجودی کم', 'اعلان وقتی موجودی به این عدد برسد', AppColors.cyan, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StockThresholdPage()));
          }),
          _item(Icons.campaign_outlined, 'اطلاعیه‌ها', 'ارسال و مدیریت اعلان عمومی', AppColors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsPage()));
          }),
          _item(Icons.notifications_active_outlined, 'اعلان‌های اپ', 'زنگ و هشدار داخل اپ', AppColors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AppNotifyPage()));
          }),
          _item(Icons.info_outline, 'درباره فروشگاه‌یار', 'نسخه ۱.۵', AppColors.textDim, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                content: const Text('نسخه ۱.۵\ninfo@apadanasleep.ir', style: TextStyle(color: AppColors.textDim)),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
              ),
            );
          }),
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
              ),
              child: const Text('خروج از حساب', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String sub, Color c, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: NeonCard(
        onTap: onTap,
        borderColor: c.withOpacity(0.25),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_left, color: AppColors.textMute),
        ]),
      ),
    );
  }
}

class StatusColorsPage extends StatefulWidget {
  const StatusColorsPage({super.key});
  @override
  State<StatusColorsPage> createState() => _StatusColorsPageState();
}

class _StatusColorsPageState extends State<StatusColorsPage> {
  final keys = ['pending', 'processing', 'completed', 'cancelled'];
  final labels = {
    'pending': 'در انتظار پرداخت',
    'processing': 'در حال انجام',
    'completed': 'تکمیل شده',
    'cancelled': 'لغو / مرجوع',
  };
  final defaults = {
    'pending': 0xFFF59E0B,
    'processing': 0xFF3B82F6,
    'completed': 0xFF10B981,
    'cancelled': 0xFFEF4444,
  };
  Map<String, int> colors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final m = <String, int>{};
    for (final k in keys) {
      m[k] = p.getInt('status_color_$k') ?? defaults[k]!;
    }
    setState(() => colors = m);
  }

  Future<void> _save(String k, int val) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('status_color_$k', val);
    setState(() => colors[k] = val);
  }

  static const palette = [
    0xFFF59E0B, 0xFF3B82F6, 0xFF10B981, 0xFFEF4444,
    0xFF8B5CF6, 0xFF06B6D4, 0xFFEC4899, 0xFF84CC16,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('رنگ وضعیت سفارشات', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: keys.map((k) {
          final c = Color(colors[k] ?? defaults[k]!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeonCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(labels[k]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: palette.map((hex) {
                  final selected = colors[k] == hex;
                  return GestureDetector(
                    onTap: () => _save(k, hex),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(hex),
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                }).toList()),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StockThresholdPage extends StatefulWidget {
  const StockThresholdPage({super.key});
  @override
  State<StockThresholdPage> createState() => _StockThresholdPageState();
}

class _StockThresholdPageState extends State<StockThresholdPage> {
  final c = TextEditingController(text: '5');
  bool notify = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    c.text = (p.getInt('stock_threshold') ?? 5).toString();
    notify = p.getBool('stock_notify') ?? true;
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('stock_threshold', int.tryParse(c.text) ?? 5);
    await p.setBool('stock_notify', notify);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('آستانه موجودی کم', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          NeonCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('اگر موجودی محصول به این عدد یا کمتر برسد، در بخش یادآوری نمایش داده می‌شود.', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'تعداد آستانه',
                  labelStyle: const TextStyle(color: AppColors.textDim),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('نمایش هشدار در اپ', style: TextStyle(color: Colors.white, fontSize: 13)),
                value: notify,
                activeColor: AppColors.purple,
                onChanged: (v) => setState(() => notify = v),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('ذخیره'),
          ),
        ]),
      ),
    );
  }
}

class AppNotifyPage extends StatefulWidget {
  const AppNotifyPage({super.key});
  @override
  State<AppNotifyPage> createState() => _AppNotifyPageState();
}

class _AppNotifyPageState extends State<AppNotifyPage> {
  bool orderN = true;
  bool stockN = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        orderN = p.getBool('notify_orders') ?? true;
        stockN = p.getBool('notify_stock') ?? true;
      });
    });
  }

  Future<void> _set(String k, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('اعلان‌های اپ', style: TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: NeonCard(
          child: Column(children: [
            SwitchListTile(
              title: const Text('اعلان سفارش جدید', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: orderN,
              activeColor: AppColors.purple,
              onChanged: (v) { setState(() => orderN = v); _set('notify_orders', v); },
            ),
            SwitchListTile(
              title: const Text('اعلان موجودی کم', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: stockN,
              activeColor: AppColors.purple,
              onChanged: (v) { setState(() => stockN = v); _set('notify_stock', v); },
            ),
          ]),
        ),
      ),
    );
  }
}

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});
  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  bool loading = true;
  List items = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await context.read<AuthService>().api.dio.get('announcements');
      if (res.data is Map && res.data['items'] is List) {
        items = res.data['items'] as List;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final start = TextEditingController();
    final end = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('اطلاعیه جدید', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'عنوان', hintStyle: TextStyle(color: AppColors.textMute))),
            TextField(controller: body, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: const InputDecoration(hintText: 'متن', hintStyle: TextStyle(color: AppColors.textMute))),
            TextField(controller: start, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'شروع (1404/07/19 یا 2026-10-11)', hintStyle: TextStyle(color: AppColors.textMute))),
            TextField(controller: end, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'پایان (اختیاری)', hintStyle: TextStyle(color: AppColors.textMute))),
            const SizedBox(height: 6),
            const Text('نمایش در: اپ، پروفایل کاربر سایت', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok == true) {
      try {
        String norm(String s) {
          s = s.trim().replaceAll('/', '-');
          final p = s.split('-');
          if (p.length == 3 && (int.tryParse(p[0]) ?? 0) > 1500 && (int.tryParse(p[0]) ?? 0) < 1600) {
            // تقریبی: ذخیره همان رشته؛ فیلتر سمت سرور با Y-m-d میلادی بهتر است
            return s;
          }
          return s;
        }
        final res = await context.read<AuthService>().api.dio.post('announcements', data: {
          'title': title.text.trim(),
          'body': body.text.trim(),
          'places': ['app', 'profile', 'site'],
          'active': true,
          'start': norm(start.text),
          'end': norm(end.text),
        });
        if (res.data is Map && res.data['success'] == true) {
          if (mounted) {
            showOk(context, 'ذخیره شد');
          }
          await _load();
        }
      } catch (e) {
        if (mounted) {
          showErr(context, 'خطا');
        }
      }
    }
  }

  Future<void> _toggle(Map m) async {
    try {
      await context.read<AuthService>().api.dio.post('announcements/${m['id']}/action', data: {'action': 'toggle'});
      await _load();
    } catch (e) {
      if (mounted) showErr(context, 'خطا');
    }
  }

  Future<void> _delete(Map m) async {
    try {
      await context.read<AuthService>().api.dio.post('announcements/${m['id']}/action', data: {'action': 'delete'});
      await _load();
    } catch (e) {
      if (mounted) showErr(context, 'خطا');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          GlassHeader(
            title: 'اطلاعیه‌ها',
            subtitle: 'نمایش در اپ و پروفایل',
            actions: [IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: _create)],
          ),
          Expanded(
            child: loading
                ? const Center(child: MiniLoader())
                : error != null
                    ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                    : items.isEmpty
                        ? const Center(child: Text('اطلاعیه‌ای نیست — با + اضافه کنید', style: TextStyle(color: AppColors.textDim)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final m = Map<String, dynamic>.from(items[i] as Map);
                              final active = m['active'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NeonCard(
                                  borderColor: active ? const Color(0xFF6EE7B7).withOpacity(0.35) : null,
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(m['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                      Switch(value: active, activeColor: const Color(0xFF6EE7B7), onChanged: (_) => _toggle(m)),
                                      IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20), onPressed: () => _delete(m)),
                                    ]),
                                    if ((m['body']?.toString() ?? '').isNotEmpty)
                                      Text(m['body'].toString(), style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'از ${m['start']?.toString().isNotEmpty == true ? m['start'] : 'همیشه'} تا ${m['end']?.toString().isNotEmpty == true ? m['end'] : 'نامحدود'}',
                                      style: const TextStyle(color: AppColors.textMute, fontSize: 10),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }
}
