import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'low_stock_screen.dart';
import 'customers_screen.dart';
import 'customer_history_screen.dart';
import 'accounting_screen.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.inventory_2_rounded, 'یادآوری موجودی محصول', 'هشدار کاهش موجودی کالاها', AppColors.purple, const LowStockScreen()),
      _Item(Icons.people_alt_rounded, 'مدیریت مشتریان', 'اطلاعات و ارتباط با مشتریان', AppColors.orange, const CustomersScreen()),
      _Item(Icons.history_rounded, 'سوابق مشتریان', 'تاریخچه خرید و تعاملات', AppColors.blue, const CustomerHistoryScreen()),
      _Item(Icons.account_balance_wallet_rounded, 'حسابداری فروشگاه', 'گزارشات مالی و تراکنش‌ها', AppColors.cyan, const AccountingScreen()),
      _Item(Icons.chat_bubble_outline_rounded, 'پرسش و پاسخ', 'مدیریت سوالات و نظرات', const Color(0xFF2EE6A6), null),
      _Item(Icons.support_agent_rounded, 'تیکت و پشتیبانی', 'پاسخگویی به درخواست‌ها', const Color(0xFFE879F9), null),
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
                  onTap: () {
                    if (it.page != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => it.page!));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('این بخش به‌زودی فعال می‌شود')),
                      );
                    }
                  },
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
  final Widget? page;
  _Item(this.icon, this.title, this.sub, this.color, this.page);
}
