import '../nav.dart';
import 'package:flutter/material.dart';
import '../../features/home/notifications_screen.dart' show openNotificationsPanel;

class AppColors {
  // پس‌زمینه عمیق مثل مرجع
  static const bg = Color(0xFF0A0B1E);
  static const surface = Color(0xFF12132A);
  static const card = Color(0xFF16183A);
  static const cardBorder = Color(0xFF2E3060);
  static const purple = Color(0xFF7C5CFF);
  static const purpleGlow = Color(0xFFA78BFF);
  static const pink = Color(0xFFF472B6);
  static const cyan = Color(0xFF2EE6C5);
  static const orange = Color(0xFFFF9F43);
  static const blue = Color(0xFF4C8DFF);
  static const red = Color(0xFFFF4D6D);
  static const green = Color(0xFF22C55E);
  static const text = Colors.white;
  static const textDim = Color(0xFFA0A3C0);
  static const textMute = Color(0xFF6E7190);
}

/// کارت شیشه‌ای با درخشش رنگی — نزدیک به مرجع
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
    this.radius = 20,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final glow = borderColor ?? AppColors.purple;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card.withOpacity(0.95),
            const Color(0xFF12142E).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glow.withOpacity(0.45), width: 1.2),
        boxShadow: elevated
            ? [
                BoxShadow(color: glow.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
              ]
            : [
                BoxShadow(color: glow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3)),
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
      child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.purple),
    );
  }
}

/// هدر شیشه‌ای — زنگوله چپ | عنوان وسط | فروشگاه راست (مثل مرجع)
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
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 12)],
            border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                      border: Border.all(color: Colors.white24, width: 0.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A2BB8), Color(0xFF2A1570), Color(0xFF140A3A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.purple.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        // LTR: چپ = اول، راست = آخر
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // === چپ: زنگوله + رفرش ===
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
              // === وسط: عنوان RTL ===
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
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
              // === راست: فروشگاه ===
              if (showStoreIcon) storeBtn(),
            ],
          ),
        ),
      ),
    );
  }
}

/// تبدیل تاریخ میلادی به شمسی خوانا
String toShamsiStr(dynamic raw) {
  if (raw == null) return '';
  final s = raw.toString().trim();
  if (s.isEmpty) return '';
  // اگر از قبل شمسی است (شامل / و سال ۱۳ یا ۱۴)
  if (s.contains('/') && (s.startsWith('13') || s.startsWith('14'))) return s;
  try {
    DateTime? dt;
    if (s.contains('T') || s.contains(' ')) {
      dt = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    } else if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      dt = DateTime.tryParse(s.substring(0, 10));
    } else if (RegExp(r'^\d{4}/\d{2}/\d{2}').hasMatch(s)) {
      final p = s.split(RegExp(r'[/\s]'));
      dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }
    if (dt == null) return s;
    // Jalali via simple algorithm if package not imported here - use approximate via DateTime
    // Prefer shamsi_date in callers; here basic fallback
    return s; // callers should use formatJalali
  } catch (_) {
    return s;
  }
}
