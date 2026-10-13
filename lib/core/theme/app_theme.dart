import '../nav.dart';
import 'package:flutter/material.dart';

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
  final VoidCallback? onRefresh; // نگه‌داشته شده برای سازگاری — نمایش داده نمی‌شود
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
            colors: [Color(0xFF4C2BC9), Color(0xFF2A1780), Color(0xFF150B3A)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.purple.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // سمت راست در RTL: آیکون فروشگاه / ماژول
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)],
                  ),
                  child: Icon(leadingIcon ?? Icons.storefront_rounded, color: Colors.white, size: 22),
                ),
              ),
            if (showStoreIcon) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: const TextStyle(color: Color(0xFFB8C0E0), fontSize: 11)),
                ],
              ),
            ),
            if (actions != null) ...actions!,
            if (showBell)
              _hIcon(Icons.notifications_none_rounded, () {
                AppNav.openNotifications?.call(context);
              }),
            if (showBell) const SizedBox(width: 6),
            if (storeOpensSettings)
              _hIcon(Icons.settings_outlined, () => AppNav.openSettingsDrawer()),
          ],
        ),
      ),
    );
  }

  Widget _hIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}


