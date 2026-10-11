import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'low_stock_screen.dart';
import 'customers_screen.dart';
import 'accounting_screen.dart';
import 'tickets_screen.dart';
import 'reviews_screen.dart';
import 'tasks_screen.dart';
import '../settings/plugins_screen.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.inventory_2_rounded, 'یادآوری موجودی محصول', 'هشدار کاهش موجودی کالاها', AppColors.purple, const LowStockScreen()),
      _Item(Icons.rate_review_rounded, 'نظرات محصولات', 'مدیریت نظرات ووکامرس', const Color(0xFF2EE6A6), const ReviewsScreen()),
      _Item(Icons.support_agent_rounded, 'تیکت و پشتیبانی', 'اتصال به افزونه تیکت سایت', const Color(0xFFE879F9), const TicketsScreen()),
      _Item(Icons.people_alt_rounded, 'مدیریت مشتریان', 'اطلاعات، سوابق و سفارشات', AppColors.orange, const CustomersScreen()),
      _Item(Icons.account_balance_wallet_rounded, 'حسابداری فروشگاه', 'گزارشات مالی و تراکنش‌ها', AppColors.cyan, const AccountingScreen()),
      _Item(Icons.checklist_rtl_rounded, 'کارهای من', 'دفترچه یادداشت و لیست کارها', AppColors.blue, const TasksScreen()),
      _Item(Icons.extension, 'افزونه‌های سایت', 'فعال و غیرفعال کردن افزونه‌ها', AppColors.purple, const PluginsScreen()),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const GlassHeader(title: 'ماژول‌ها', subtitle: 'ابزارهای کاربردی فروشگاه شما'),
          const SizedBox(height: 12),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: NeonCard(
                  borderColor: it.color.withOpacity(0.35),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => it.page)),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: it.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(it.icon, color: it.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(it.sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                      ]),
                    ),
                    const Icon(Icons.chevron_left, color: AppColors.textMute),
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
