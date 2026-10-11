import 'package:flutter/material.dart';

/// ناوبری سراسری
class AppNav {
  static void Function(int)? goToTab;
  static GlobalKey<ScaffoldState>? scaffoldKey;

  static void settings() {
    openSettingsDrawer();
  }

  static void openSettingsDrawer() {
    final s = scaffoldKey?.currentState;
    if (s != null) {
      s.openEndDrawer();
      return;
    }
    goToTab?.call(4);
  }

  static void closeDrawer() {
    scaffoldKey?.currentState?.closeEndDrawer();
  }
}
