import '../nav.dart';
import 'package:flutter/material.dart';
import '../../features/home/notifications_screen.dart' show openNotificationsPanel;

/// پالت تیره نرم — سبک claymorphism (نه نئون)
class AppColors {
  static const bg = Color(0xFF0E0F1C);
  static const surface = Color(0xFF17192B);
  static const card = Color(0xFF1C1E33);
  static const cardBorder = Color(0xFF2A2D4A);
  static const purple = Color(0xFF7B6CFF);
  static const purpleGlow = Color(0xFF9B8CFF);
  static const pink = Color(0xFFE879A9);
  static const cyan = Color(0xFF3DDBB0);
  static const orange = Color(0xFFFFA45B);
  static const blue = Color(0xFF5B8DEF);
  static const red = Color(0xFFFF5C7A);
  static const green = Color(0xFF34D399);
  static const text = Colors.white;
  static const textDim = Color(0xFFA8AABC);
  static const textMute = Color(0xFF6E7189);
}

/// کارت clay — سایه نرم بالا/پایین، بدون درخشش نئون
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
    this.radius = 22,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = borderColor ?? AppColors.cardBorder;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withOpacity(0.35), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.card, Colors.white, 0.04)!,
            AppColors.card,
            Color.lerp(AppColors.card, Colors.black, 0.12)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        boxShadow: elevated
            ? [
                // سایه پایین (عمق clay)
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                // هایلایت نرم بالا
                BoxShadow(
                  color: Colors.white.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
        borderRadius: BorderRadius.circular(radius),
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

/// هدر clay — زنگوله چپ | عنوان وسط | فروشگاه راست
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

    Widget storeBtn() {
      return GestureDetector(
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
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(leadingIcon ?? Icons.storefront_rounded, color: Colors.white, size: 22),
              if (storeOpensSettings && leadingIcon == null)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1040),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 9),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPad > 0 ? topPad + 6 : 10, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C35),
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A2D55),
              Color(0xFF1A1C35),
              Color(0xFF141628),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // چپ: زنگوله + رفرش
              if (showBell)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  onPressed: () => openNotificationsPanel(context),
                ),
              if (onRefresh != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                  onPressed: onRefresh,
                ),
              if (actions != null) ...actions!,
              // وسط: عنوان
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // راست: فروشگاه
              if (showStoreIcon) storeBtn(),
            ],
          ),
        ),
      ),
    );
  }
}

String toShamsiStr(dynamic raw) {
  if (raw == null) return '';
  return raw.toString().trim();
}
