import '../../core/utils/shamsi_picker.dart'; // formatJalali, pickShamsiDate, formatAnyDate
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/nav.dart';
import '../modules/customers_screen.dart';
import '../../core/utils/snack.dart';
import 'plugins_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool asDrawer;
  const SettingsScreen({super.key, this.asDrawer = false});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final siteName = auth.site?['name']?.toString() ?? 'فروشگاه';
    final email = auth.user?['email']?.toString() ?? auth.user?['display_name']?.toString() ?? '';

    if (widget.asDrawer) {
      final displayName = auth.user?['display_name']?.toString() ?? 'مدیر فروشگاه';
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMute, size: 22),
                    onPressed: () => AppNav.closeDrawer(),
                  ),
                ],
              ),
            ),
            // کارت پروفایل مدیر — مثل موکاپ
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFF121E42),
                  border: Border.all(color: const Color(0xFF2A3A6A)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(displayName, textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(email.isNotEmpty ? email : siteName, textAlign: TextAlign.right,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                children: [
                  _navItem(Icons.person_outline_rounded, 'پروفایل', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                  }),
                  _navItem(Icons.tune_rounded, 'تنظیمات عمومی', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceSettingsPage()));
                  }),
                  _navItem(Icons.palette_outlined, 'رنگ وضعیت', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatusColorsPage()));
                  }),
                  _navItem(Icons.campaign_outlined, 'اطلاعیه‌ها', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsPage()));
                  }),
                  _navItem(Icons.lock_outline_rounded, 'امنیت', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()));
                  }),
                  _navItem(Icons.support_agent_rounded, 'پشتیبانی', () {
                    AppNav.closeDrawer();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
                  }),
                  const SizedBox(height: 8),
                  _navItem(Icons.logout_rounded, 'خروج', () async {
                    AppNav.closeDrawer();
                    await auth.logout();
                  }, danger: true),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // حالت صفحه تنظیمات کامل
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassHeader(
            title: 'تنظیمات',
            subtitle: siteName,
            showBell: false,
            showSettingsGear: false,
            leadingIcon: Icons.settings_rounded,
            leadingColor: AppColors.blue,
          ),
          const SizedBox(height: 12),
          _item(Icons.person_outline_rounded, 'پروفایل کاربری', 'نام مدیر، ایمیل، نقش و فروشگاه', AppColors.purpleGlow, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }),
          _item(Icons.palette_outlined, 'رنگ وضعیت سفارشات', 'شخصی‌سازی رنگ‌ها', AppColors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatusColorsPage()));
          }),
          _item(Icons.receipt_long_outlined, 'تنظیمات فاکتور', 'آدرس، تماس، اینستاگرام، واتساپ، لوگو', AppColors.cyan, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceSettingsPage()));
          }),
          _item(Icons.campaign_outlined, 'اطلاعیه‌ها', 'ارسال و مدیریت اعلان عمومی', AppColors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsPage()));
          }),
          _item(Icons.notifications_active_outlined, 'اعلان‌های اپ', 'زنگ و هشدار داخل اپ', AppColors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AppNotifyPage()));
          }),
          _item(Icons.info_outline, 'درباره فروشگاه‌یار', 'نسخه ۱.۷', AppColors.textDim, () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white)),
                content: const Text('نسخه ۱.۷\ninfo@apadanasleep.ir', style: TextStyle(color: AppColors.textDim)),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
              ),
            );
          }),
          const SizedBox(height: 16),
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

  Widget _navItem(IconData icon, String title, VoidCallback onTap, {bool selected = false, bool danger = false}) {
    final c = danger ? const Color(0xFFEF4444) : (selected ? AppColors.purpleGlow : AppColors.textDim);
    final tc = danger ? const Color(0xFFEF4444) : (selected ? Colors.white : const Color(0xFFD1D5F0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.purple.withOpacity(0.22) : const Color(0xFF0E1633),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2A55)),
            ),
            child: Row(children: [
              const Icon(Icons.chevron_left_rounded, color: AppColors.textMute, size: 20),
              const Spacer(),
              Text(title, style: TextStyle(color: tc, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 12),
              Icon(icon, color: c, size: 22),
            ]),
          ),
        ),
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
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('رنگ وضعیت سفارشات', style: TextStyle(fontSize: 16))),
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
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    var th = prefs.getInt('stock_threshold') ?? 5;
    notify = prefs.getBool('stock_notify') ?? true;
    try {
      final res = await context.read<AuthService>().api.dio.get('settings/threshold');
      if (res.data is Map) {
        final v = int.tryParse('${res.data['threshold'] ?? th}');
        if (v != null) th = v;
        if (res.data['enabled'] != null) notify = res.data['enabled'] == true;
      }
    } catch (_) {}
    c.text = '$th';
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final th = int.tryParse(c.text.trim()) ?? 5;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stock_threshold', th);
    await prefs.setBool('stock_notify', notify);
    try {
      await context.read<AuthService>().api.dio.post('settings/threshold', data: {
        'threshold': th,
        'enabled': notify,
      });
      if (mounted) {
        showOk(context, 'ذخیره شد');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErr(context, e.toString());
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          title: 'آستانه موجودی کم',
          subtitle: 'تنظیم اعلان کمبود موجودی',
          leadingIcon: Icons.inventory_2_rounded,
          leadingColor: AppColors.cyan,
          storeOpensSettings: false,
          showBell: false,
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    NeonCard(
                      borderColor: AppColors.cyan.withOpacity(0.35),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text(
                          'اگر موجودی محصول به این عدد یا کمتر برسد، در یادآوری و اعلان‌های اپ نمایش داده می‌شود.',
                          style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.45),
                        ),
                        const SizedBox(height: 14),
                        const Text('تعداد آستانه', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: c,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'مثلاً 5',
                            hintStyle: const TextStyle(color: AppColors.textMute),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('فعال بودن اعلان کمبود', style: TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: const Text('در زنگوله و صفحه یادآوری', style: TextStyle(color: AppColors.textMute, fontSize: 11)),
                          value: notify,
                          activeColor: AppColors.purple,
                          onChanged: (v) => setState(() => notify = v),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: saving ? const MiniLoader(size: 22) : const Text('ذخیره آستانه', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
        ),
      ]),
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
      body: Column(children: [
        const GlassHeader(
          showSettingsGear: false,
          showBell: false,
          title: 'تنظیمات اعلان‌ها',
          subtitle: 'زنگ و هشدار داخل اپ',
          leadingIcon: Icons.notifications_active_rounded,
          leadingColor: AppColors.blue,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NeonCard(
            child: Column(children: [
              SwitchListTile(
                title: const Text('اعلان سفارش جدید', style: TextStyle(color: Colors.white, fontSize: 13)),
                value: orderN,
                activeColor: AppColors.purple,
                onChanged: (v) { setState(() => orderN = v); _set('notify_orders', v); },
              ),
              const Divider(color: Color(0xFF1E2A55), height: 1),
              SwitchListTile(
                title: const Text('اعلان موجودی کم', style: TextStyle(color: Colors.white, fontSize: 13)),
                value: stockN,
                activeColor: AppColors.purple,
                onChanged: (v) { setState(() => stockN = v); _set('notify_stock', v); },
              ),
            ]),
          ),
        ),
      ]),
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

  String _normJalali(String s) {
    s = s.trim().replaceAll('-', '/');
    final p = s.split('/');
    if (p.length == 3) {
      final y = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 1;
      final d = int.tryParse(p[2]) ?? 1;
      if (y > 1300 && y < 1600) {
        final g = Jalali(y, m, d).toDateTime();
        return '${g.year.toString().padLeft(4, '0')}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')} 00:00:00';
      }
    }
    return s.trim();
  }

  Future<void> _create() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final startC = TextEditingController();
    final endC = TextEditingController();
    String place = 'app';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pick(TextEditingController c) async {
              final j = await pickShamsiDate(ctx);
              if (j != null) {
                c.text = formatJalali(j);
                setLocal(() {});
              }
            }
            InputDecoration dec(String h, {Widget? suffix}) => InputDecoration(
              hintText: h,
              hintStyle: const TextStyle(color: AppColors.textMute, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0B1230),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: suffix,
            );
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMute, borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 14),
                  const Text('اطلاعیه جدید', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(controller: title, style: const TextStyle(color: Colors.white), decoration: dec('عنوان اطلاعیه')),
                  const SizedBox(height: 10),
                  TextField(controller: body, style: const TextStyle(color: Colors.white), maxLines: 4, decoration: dec('متن پیام')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: startC, readOnly: true, onTap: () => pick(startC), style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: dec('شروع', suffix: const Icon(Icons.event, color: AppColors.textMute, size: 18)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endC, readOnly: true, onTap: () => pick(endC), style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: dec('پایان', suffix: const Icon(Icons.event, color: AppColors.textMute, size: 18)))),
                  ]),
                  const SizedBox(height: 12),
                  const Text('محل نمایش', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    ChoiceChip(label: const Text('اپ'), selected: place == 'app', onSelected: (_) => setLocal(() => place = 'app'),
                      selectedColor: AppColors.purple.withOpacity(0.3), labelStyle: TextStyle(color: place == 'app' ? Colors.white : AppColors.textDim)),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('سایت'), selected: place == 'site', onSelected: (_) => setLocal(() => place = 'site'),
                      selectedColor: AppColors.purple.withOpacity(0.3), labelStyle: TextStyle(color: place == 'site' ? Colors.white : AppColors.textDim)),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('هر دو'), selected: place == 'both', onSelected: (_) => setLocal(() => place = 'both'),
                      selectedColor: AppColors.purple.withOpacity(0.3), labelStyle: TextStyle(color: place == 'both' ? Colors.white : AppColors.textDim)),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple, foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ثبت اطلاعیه'),
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف', style: TextStyle(color: AppColors.textMute))),
                ]),
              ),
            );
          },
        );
      },
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      try {
        await context.read<AuthService>().api.dio.post('announcements', data: {
          'title': title.text.trim(),
          'body': body.text.trim(),
          'start': startC.text.trim().isEmpty ? null : _normJalali(startC.text.trim()),
          'end': endC.text.trim().isEmpty ? null : _normJalali(endC.text.trim()),
          'place': place,
          'active': true,
        });
        if (mounted) showOk(context, 'ثبت شد');
        await _load();
      } catch (e) {
        if (mounted) showErr(context, '$e');
      }
    }
    title.dispose(); body.dispose(); startC.dispose(); endC.dispose();
  }

  Future<void> _toggle(Map m) async {
    final id = m['id'];
    final active = m['active'] != false;
    try {
      final res = await context.read<AuthService>().api.dio.post('announcements/action', data: {
        'action': active ? 'deactivate' : 'activate',
        'id': id,
      });
      if (res.data is Map && res.data['items'] is List) {
        setState(() => items = res.data['items'] as List);
      } else {
        await _load();
      }
    } catch (_) {
      await _load();
    }
  }

  Future<void> _delete(Map m) async {
    final id = m['id'];
    try {
      final res = await context.read<AuthService>().api.dio.post('announcements/action', data: {
        'action': 'delete',
        'id': id,
      });
      if (res.data is Map && res.data['items'] is List) {
        setState(() => items = res.data['items'] as List);
      } else {
        await _load();
      }
      if (mounted) showOk(context, 'حذف شد');
    } catch (_) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(
          showSettingsGear: false,
          title: 'اطلاعیه‌ها',
          subtitle: 'اعلان‌های مهم فروشگاه',
          leadingIcon: Icons.campaign_rounded,
          leadingColor: AppColors.purple,
          onRefresh: _load,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: _create,
            ),
          ],
        ),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : error != null
                  ? Center(child: Text(error!, style: const TextStyle(color: AppColors.red)))
                  : items.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('اطلاعیه‌ای نیست', style: TextStyle(color: AppColors.textDim)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _create,
                              icon: const Icon(Icons.add),
                              label: const Text('افزودن اطلاعیه'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
                            ),
                          ]),
                        )
                      : RefreshIndicator(
                          color: AppColors.purple,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final m = Map<String, dynamic>.from(items[i] as Map);
                              final active = m['active'] != false;
                              final title = m['title']?.toString() ?? '';
                              final body = m['body']?.toString() ?? '';
                              final startRaw = m['start']?.toString() ?? m['created']?.toString() ?? '';
                              final start = startRaw.isEmpty ? '' : formatAnyDate(startRaw);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeonCard(
                                  borderColor: active ? AppColors.purple : null,
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    SoftIconBox(
                                      icon: Icons.campaign_rounded,
                                      color: active ? AppColors.purple : AppColors.textMute,
                                      size: 44,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(title, style: TextStyle(
                                          color: active ? Colors.white : AppColors.textMute,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        )),
                                        if (body.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                        ],
                                        if (start.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(start, style: const TextStyle(color: AppColors.textMute, fontSize: 10)),
                                        ],
                                      ]),
                                    ),
                                    Column(children: [
                                      Switch(
                                        value: active,
                                        activeColor: AppColors.purple,
                                        onChanged: (_) => _toggle(m),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                                        onPressed: () => _delete(m),
                                      ),
                                    ]),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

class InvoiceSettingsPage extends StatefulWidget {
  const InvoiceSettingsPage({super.key});
  @override
  State<InvoiceSettingsPage> createState() => _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends State<InvoiceSettingsPage> {
  final name = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final insta = TextEditingController();
  final whats = TextEditingController();
  final logo = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose(); address.dispose(); phone.dispose(); insta.dispose(); whats.dispose(); logo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthService>().api.dio.get('settings/invoice');
      if (res.data is Map) {
        final d = res.data as Map;
        name.text = d['store_name']?.toString() ?? '';
        address.text = d['address']?.toString() ?? '';
        phone.text = d['phone']?.toString() ?? '';
        insta.text = d['instagram']?.toString() ?? '';
        whats.text = d['whatsapp']?.toString() ?? '';
        logo.text = d['logo_url']?.toString() ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await context.read<AuthService>().api.dio.post('settings/invoice', data: {
        'store_name': name.text.trim(),
        'address': address.text.trim(),
        'phone': phone.text.trim(),
        'instagram': insta.text.trim(),
        'whatsapp': whats.text.trim(),
        'logo_url': logo.text.trim(),
      });
      if (mounted) showOk(context, 'ذخیره شد');
    } catch (_) {
      if (mounted) showErr(context, 'خطا');
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        GlassHeader(title: 'تنظیمات فاکتور', subtitle: 'اطلاعات چاپ فاکتور', storeOpensSettings: false),
        Expanded(
          child: loading
              ? const Center(child: MiniLoader())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _f(name, 'نام فروشگاه'),
                    _f(address, 'آدرس فروشگاه', lines: 2),
                    _f(phone, 'شماره تماس'),
                    _f(insta, 'اینستاگرام'),
                    _f(whats, 'واتساپ'),
                    _f(logo, 'آدرس تصویر لوگو (URL)'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving ? const MiniLoader(size: 20) : const Text('ذخیره'),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _f(TextEditingController c, String hint, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonCard(
        child: TextField(
          controller: c,
          maxLines: lines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMute),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}



Future<void> _editProfile(BuildContext context) async {
  final auth = context.read<AuthService>();
  final user = auth.user ?? {};
  final nameCtrl = TextEditingController(text: user['display_name']?.toString() ?? '');
  final emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('ویرایش پروفایل', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'نام نمایشی',
            labelStyle: TextStyle(color: AppColors.textDim),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E2A55))),
          ),
        ),
        TextField(
          controller: emailCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'ایمیل',
            labelStyle: TextStyle(color: AppColors.textDim),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E2A55))),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره', style: TextStyle(color: AppColors.purpleGlow))),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final res = await auth.api.dio.post('profile', data: {
      'display_name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
    });
    if (res.data is Map && res.data['success'] == true) {
      final u = res.data['user'];
      if (u is Map) {
        await auth.updateUserLocal(Map<String, dynamic>.from(u));
      }
      if (context.mounted) showOk(context, 'پروفایل ذخیره شد');
    } else {
      if (context.mounted) showErr(context, 'ذخیره نشد — از پنل وردپرس هم می‌توانید ویرایش کنید');
    }
  } catch (e) {
    if (context.mounted) showErr(context, 'خطا: $e');
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user ?? {};
    final site = auth.site ?? {};
    final name = user['display_name']?.toString() ?? 'مدیر';
    final email = user['email']?.toString() ?? '—';
    final roles = user['roles'];
    String roleStr = 'مدیر اصلی';
    if (roles is List && roles.isNotEmpty) {
      final r = roles.first.toString().toLowerCase();
      if (r.contains('admin')) roleStr = 'مدیر اصلی';
      else roleStr = roles.map((e) => e.toString()).join('، ');
    }
    final siteName = site['name']?.toString() ?? '';
    final siteUrl = site['url']?.toString() ?? '';
    final letter = name.isNotEmpty ? name.substring(0, 1) : 'م';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'پروفایل',
          subtitle: 'اطلاعات حساب کاربری شما',
          leadingIcon: Icons.storefront_rounded,
          leadingColor: AppColors.purple,
          showSettingsGear: false,
          showBell: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
            children: [
              // کارت پروفایل مثل موکاپ
              NeonCard(
                borderColor: AppColors.purple,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                child: Column(children: [
                  Builder(builder: (_) {
                    final avatar = user['avatar']?.toString() ?? '';
                    final lower = avatar.toLowerCase();
                    final isDefault = lower.contains('gravatar.com') && (lower.contains('d=mm') || lower.contains('d=mp') || lower.contains('d=blank'));
                    final showImg = avatar.startsWith('http') && avatar.isNotEmpty && !isDefault;
                    final isSvg = lower.contains('.svg');
                    Widget child;
                    if (showImg && isSvg) {
                      child = SvgPicture.network(avatar, width: 88, height: 88, fit: BoxFit.cover,
                        placeholderBuilder: (_) => Text(letter, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)));
                    } else if (showImg) {
                      child = Image.network(avatar, width: 88, height: 88, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(letter, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)));
                    } else {
                      child = Text(letter, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold));
                    }
                    return Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7047F5), Color(0xFF2868FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    );
                  }),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7047F5), Color(0xFF2868FF)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(roleStr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              _menu(context, Icons.person_outline_rounded, 'ویرایش پروفایل', AppColors.purple, () {
                _editProfile(context);
              }),
              _menu(context, Icons.lock_outline_rounded, 'تغییر رمز عبور', AppColors.blue, () async {
                final cur = TextEditingController();
                final neu = TextEditingController();
                final neu2 = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('تغییر رمز عبور', style: TextStyle(color: Colors.white)),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(controller: cur, obscureText: true, style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'رمز فعلی', labelStyle: TextStyle(color: AppColors.textDim))),
                      TextField(controller: neu, obscureText: true, style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'رمز جدید', labelStyle: TextStyle(color: AppColors.textDim))),
                      TextField(controller: neu2, obscureText: true, style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'تکرار رمز جدید', labelStyle: TextStyle(color: AppColors.textDim))),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره', style: TextStyle(color: AppColors.purpleGlow))),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                if (neu.text != neu2.text) {
                  showErr(context, 'رمز جدید و تکرار یکسان نیست');
                  return;
                }
                if (neu.text.length < 6) {
                  showErr(context, 'رمز حداقل ۶ کاراکتر');
                  return;
                }
                try {
                  final res = await context.read<AuthService>().api.dio.post('profile/password', data: {
                    'current_password': cur.text,
                    'new_password': neu.text,
                  });
                  if (res.data is Map && res.data['success'] == true) {
                    showOk(context, 'رمز تغییر کرد');
                  } else {
                    showErr(context, res.data is Map ? (res.data['message']?.toString() ?? 'خطا') : 'خطا');
                  }
                } catch (e) {
                  showErr(context, 'خطا: $e');
                }
              }),
              _menu(context, Icons.storefront_outlined, 'اطلاعات فروشگاه', AppColors.cyan, () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('اطلاعات فروشگاه', style: TextStyle(color: Colors.white)),
                    content: Text('$siteName\n$siteUrl', style: const TextStyle(color: AppColors.textDim)),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه'))],
                  ),
                );
              }),
              _menu(context, Icons.notifications_none_rounded, 'تنظیمات اعلان‌ها', AppColors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AppNotifyPage()));
              }),
              const SizedBox(height: 8),
              _menu(context, Icons.logout_rounded, 'خروج از حساب', AppColors.red, () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('خروج', style: TextStyle(color: Colors.white)),
                    content: const Text('از حساب خارج می‌شوید؟', style: TextStyle(color: AppColors.textDim)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج', style: TextStyle(color: AppColors.red))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AuthService>().logout(clearToken: false);
                }
              }),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _menu(BuildContext context, IconData icon, String title, Color c, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
          const Icon(Icons.chevron_left, color: AppColors.textMute),
        ]),
      ),
    );
  }
}

/// صفحه امنیت — توکن و نشست
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final email = auth.user?['email']?.toString() ?? '—';
    final role = (auth.user?['roles'] is List && (auth.user!['roles'] as List).isNotEmpty)
        ? (auth.user!['roles'] as List).first.toString()
        : 'administrator';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'امنیت',
          subtitle: 'نشست و دسترسی مدیر',
          showSettingsGear: false,
          leadingIcon: Icons.lock_outline_rounded,
          leadingColor: Color(0xFFF59E0B),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            children: [
              NeonCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('وضعیت اتصال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  _secRow(Icons.verified_user_rounded, 'توکن', 'فعال تا زمان خروج دستی'),
                  const SizedBox(height: 8),
                  _secRow(Icons.email_outlined, 'حساب', email),
                  const SizedBox(height: 8),
                  _secRow(Icons.badge_outlined, 'نقش', role),
                  const SizedBox(height: 8),
                  _secRow(Icons.storefront_outlined, 'فروشگاه', auth.site?['name']?.toString() ?? '—'),
                ]),
              ),
              const SizedBox(height: 14),
              NeonCard(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'توکن اتصال روی گوشی ذخیره می‌شود و تا وقتی خودتان «خروج» نزنید منقضی نمی‌شود. برای قطع دسترسی از همه دستگاه‌ها، از پیشخوان وردپرس نقش/رمز را تغییر دهید.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.6),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('خروج از حساب؟', style: TextStyle(color: Colors.white)),
                        content: const Text('توکن حذف می‌شود و باید دوباره وارد شوید.', style: TextStyle(color: AppColors.textDim)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج', style: TextStyle(color: AppColors.red))),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<AuthService>().logout();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('خروج از حساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1D1D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _secRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: AppColors.purpleGlow, size: 18),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 13))),
    ]);
  }
}

/// صفحه پشتیبانی
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const GlassHeader(
          title: 'پشتیبانی',
          subtitle: 'راهنما و ارتباط',
          showSettingsGear: false,
          leadingIcon: Icons.support_agent_rounded,
          leadingColor: Color(0xFF39C6D9),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            children: [
              NeonCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('فروشگاه‌یار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('نسخه اپ: ۲.۰ · افزونه: ۱.۹.۷', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                  const SizedBox(height: 14),
                  _supRow(Icons.email_outlined, 'ایمیل', 'info@apadanasleep.ir'),
                  const SizedBox(height: 8),
                  _supRow(Icons.language_rounded, 'سایت', 'apadanasleep.ir'),
                ]),
              ),
              const SizedBox(height: 14),
              NeonCard(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'برای تیکت و پشتیبانی مشتریان فروشگاه، از بخش «تیکت» در ماژول‌ها استفاده کنید. تیکت‌ها به افزونه تیکت نصب‌شده روی سایت (مثل مهرنوش) وصل می‌شوند.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.65),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _supRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF39C6D9), size: 18),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ]);
  }
}
