import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showOk(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 13)),
    backgroundColor: const Color(0xFF34D399),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

void showErr(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 13)),
    backgroundColor: AppColors.red,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
