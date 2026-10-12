import '../nav.dart';
import 'package:flutter/material.dart';
import '../../features/home/notifications_screen.dart' show openNotificationsPanel;

class AppColors {
  static const bg = Color(0xFF0B0B1A);
  static const surface = Color(0xFF141428);
  static const card = Color(0xFF1A1A32);
  static const cardBorder = Color(0xFF2A2A4A);
  static const purple = Color(0xFF7B5CFF);
  static const purpleGlow = Color(0xFF9B7BFF);
  static const pink = Color(0xFFF472B6);
  static const cyan = Color(0xFF2EE6A6);
  static const orange = Color(0xFFFF9F43);
  static const blue = Color(0xFF4C8DFF);
  static const red = Color(0xFFFF4D6D);
  static const green = Color(0xFF10B981);
  static const text = Colors.white;
  static const textDim = Color(0xFF9A9AB5);
  static const textMute = Color(0xFF6B6B8A);
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppColors.cardBorder;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? AppColors.purple).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

class MiniLoader extends StatelessWidget {
  final double size;
  const MiniLoader({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.purple,
      ),
    );
  }
}

class GlassHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showStoreIcon;
  final bool storeOpensSettings;
  final VoidCallback? onStoreTap;
  final VoidCallback? onRefresh;
  final bool showBell;
  final IconData? leadingIcon;
  final Color? leadingColor;
  const GlassHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showStoreIcon = true,
    this.storeOpensSettings = true,
    this.onStoreTap,
    this.onRefresh,
    this.showBell = true,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final color = leadingColor ?? AppColors.purple;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPad > 0 ? topPad + 4 : 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B1F8E), Color(0xFF1E1248), Color(0xFF120A2E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.purple.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 5)),
          ],
        ),
        // جهت ثابت تا در RTL جابه‌جا نشود — مطابق مرجع
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // فروشگاه / آیکون ماژول — سمت چپ
              if (showStoreIcon)
                GestureDetector(
                  onTap: () {
                    if (onStoreTap != null) {
                      onStoreTap!();
                      return;
                    }
                    if (storeOpensSettings) AppNav.openSettingsDrawer();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(leadingIcon ?? Icons.storefront_rounded, color: Colors.white, size: 20),
                        if (storeOpensSettings && leadingIcon == null)
                          Positioned(
                            right: 3,
                            bottom: 3,
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1040),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.white24, width: 0.5),
                              ),
                              child: const Icon(Icons.settings, color: Colors.white, size: 9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (showStoreIcon) const SizedBox(width: 10),
              // عنوان
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // اکشن‌های سفارشی
              if (actions != null) ...actions!,
              if (onRefresh != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                  onPressed: onRefresh,
                ),
              // زنگوله — همیشه سمت راست ثابت
              if (showBell)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  onPressed: () => openNotificationsPanel(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
