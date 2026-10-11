import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showOk(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white)),
    backgroundColor: const Color(0xFF34D399),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(48, 0, 48, 80),
    duration: const Duration(seconds: 2),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

void showErr(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white)),
    backgroundColor: AppColors.red,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(48, 0, 48, 80),
    duration: const Duration(seconds: 3),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}
