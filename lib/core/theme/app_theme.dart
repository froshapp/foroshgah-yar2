import '../nav.dart';
import 'package:flutter/material.dart';
import '../../features/home/notifications_screen.dart' show openNotificationsPanel;

/// Premium Dark Glassmorphism — مرجع
class AppColors {
  static const bg = Color(0xFF070B20);
  static const surface = Color(0xFF0F1430);
  static const card = Color(0xFF141A38);
  static const cardBorder = Color(0xFF252B4A);
  static const purple = Color(0xFF7C6CFF);
  static const purpleGlow = Color(0xFF9B8CFF);
  static const pink = Color(0xFFE879A9);
  static const cyan = Color(0xFF2DD4BF);
  static const orange = Color(0xFFFBBF24);
  static const blue = Color(0xFF5B8DEF);
  static const red = Color(0xFFF43F5E);
  static const green = Color(0xFF34D399);
  static const text = Color(0xFFF1F5F9);
  static const textDim = Color(0xFFA5B0C8);
  static const textMute = Color(0xFF6B7594);
}

/// کارت عمیق — بدون حاشیه نئون، عمق نرم
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
    final accent = borderColor;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2145),
            Color(0xFF121832),
            Color(0xFF0E1328),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: accent != null ? accent.withOpacity(0.28) : const Color(0xFF2A3158),
          width: 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
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
      child: const CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.purple),
    );
  }
}

/// آیکون داخل باکس گرد نرم ۳بعدی
class SoftIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const SoftIconBox({super.key, required this.icon, required this.color, this.size = 42});
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
          colors: [
            color.withOpacity(0.85),
            color.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

/// هدر لایه‌ای با منحنی گرادیان — مثل مرجع
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
        child: SoftIconBox(
          icon: leadingIcon ?? Icons.storefront_rounded,
          color: color,
          size: 44,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPad > 0 ? topPad + 4 : 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1F6E),
                Color(0xFF1A2A6B),
                Color(0xFF0F1840),
              ],
            ),
          ),
          child: Stack(
            children: [
              // لایه منحنی بنفش
              Positioned(
                left: -30,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // محتوا
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
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
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty)
                                Text(
                                  subtitle!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (showStoreIcon) storeBtn(),
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
