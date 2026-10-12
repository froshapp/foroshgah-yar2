import '../nav.dart';
import 'package:flutter/material.dart';
import '../../features/home/notifications_screen.dart' show openNotificationsPanel;

class AppColors {
  static const bg = Color(0xFF070B20);
  static const surface = Color(0xFF0B1230);
  static const card = Color(0xFF101B3C);
  static const cardBorder = Color(0xFF1E2A55);
  static const indigo = Color(0xFF18265A);
  static const purple = Color(0xFF7047F5);
  static const purpleGlow = Color(0xFF8B6CFF);
  static const blue = Color(0xFF2868FF);
  static const cyan = Color(0xFF39C6D9);
  static const pink = Color(0xFFE879A9);
  static const orange = Color(0xFFF5A524);
  static const red = Color(0xFFE11D48);
  static const green = Color(0xFF10B981);
  static const text = Color(0xFFF4F6FF);
  static const textDim = Color(0xFF9AA9CC);
  static const textMute = Color(0xFF6B7A9E);
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.radius = 18,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152048), Color(0xFF101B3C), Color(0xFF0C1530)],
        ),
        border: Border.all(
          color: borderColor?.withOpacity(0.35) ?? const Color(0xFF243056),
          width: 1,
        ),
        boxShadow: elevated
            ? [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: content),
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
      child: const CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.purple),
    );
  }
}

class SoftIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const SoftIconBox({super.key, required this.icon, required this.color, this.size = 44});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.72)],
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}

/// هدر مرجع: فقط چرخ‌دنده منو باز می‌کند — آیکون فروشگاه تزئینی است
class GlassHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showStoreIcon;
  final bool showSettingsGear;
  final bool storeOpensSettings; // سازگاری — نادیده گرفته می‌شود
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
    this.showSettingsGear = true,
    this.storeOpensSettings = false,
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
      padding: EdgeInsets.fromLTRB(14, topPad > 0 ? topPad + 2 : 6, 14, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 78,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3B1FA8), Color(0xFF1E3A8A), Color(0xFF0F1B4D)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                top: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF7047F5).withOpacity(0.55),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF2868FF).withOpacity(0.4),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.06), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      // چپ: فقط چرخ‌دنده = منو | زنگوله | رفرش
                      if (showSettingsGear)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                          onPressed: () => AppNav.openSettingsDrawer(),
                        ),
                      if (showBell)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          onPressed: () => openNotificationsPanel(context),
                        ),
                      if (onRefresh != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 18),
                          onPressed: onRefresh,
                        ),
                      if (actions != null) ...actions!,
                      // وسط عنوان
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty)
                                Text(
                                  subtitle!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                      // راست: آیکون صفحه — تزئینی (منو باز نمی‌کند)
                      if (showStoreIcon)
                        SoftIconBox(
                          icon: leadingIcon ?? Icons.storefront_rounded,
                          color: color,
                          size: 46,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
