import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'low_stock_screen.dart';
import 'reviews_screen.dart';
import 'tickets_screen.dart';
import 'customers_screen.dart';
import 'accounting_screen.dart';
import 'tasks_screen.dart';
import '../settings/plugins_screen.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.notifications_active_rounded, 'یادآوری موجودی محصول', 'هشدار درباره کاهش موجودی محصولات', AppColors.blue, const LowStockScreen()),
      _Item(Icons.chat_bubble_outline_rounded, 'پرسش‌وپاسخ نظرات مشتریان', 'مدیریت سوالات و نظرات مشتریان', AppColors.cyan, const ReviewsScreen()),
      _Item(Icons.headset_mic_rounded, 'تیکت و پشتیبانی', 'پشتیبانی و پاسخ به تیکت‌ها', AppColors.purple, const TicketsScreen()),
      _Item(Icons.people_alt_rounded, 'مدیریت مشتریان', 'مدیریت اطلاعات مشتریان', AppColors.blue, const CustomersScreen()),
      _Item(Icons.history_rounded, 'سوابق مشتریان', 'مشاهده سوابق خرید و تعاملات', AppColors.orange, const CustomersScreen()),
      _Item(Icons.account_balance_wallet_rounded, 'حسابداری فروشگاه', 'گزارش مالی و تراکنش‌ها', const Color(0xFF5B8DEF), const AccountingScreen()),
      _Item(Icons.checklist_rtl_rounded, 'کارهای من', 'دفترچه یادداشت و لیست کارها', AppColors.green, const TasksScreen()),
      _Item(Icons.extension_rounded, 'افزونه‌های سایت', 'فعال و غیرفعال کردن افزونه‌ها', AppColors.purpleGlow, const PluginsScreen()),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const GlassHeader(
            title: 'ماژول‌ها',
            subtitle: 'ابزارهای کاربردی فروشگاه',
            leadingIcon: Icons.apps_rounded,
            leadingColor: AppColors.purple,
          ),
          const SizedBox(height: 14),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: NeonCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => it.page)),
                  child: Row(children: [
                    SoftIconBox(icon: it.icon, color: it.color, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(it.sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                      ]),
                    ),
                    Icon(Icons.chevron_left, color: AppColors.textMute.withOpacity(0.7)),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final Widget page;
  _Item(this.icon, this.title, this.sub, this.color, this.page);
}
