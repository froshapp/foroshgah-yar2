/// ناوبری سراسری تب‌های MainShell
class AppNav {
  static void Function(int)? goToTab;
  static void settings() => goToTab?.call(4);
}
