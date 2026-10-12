import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_theme.dart';

/// انتخابگر تاریخ شمسی با سال/ماه/روز
Future<Jalali?> pickShamsiDate(BuildContext context, {Jalali? initial}) async {
  var j = initial ?? Jalali.now();
  int y = j.year;
  int m = j.month;
  int d = j.day.clamp(1, Jalali(y, m, 1).monthLength);

  final months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  return showDialog<Jalali>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        final maxD = Jalali(y, m, 1).monthLength;
        if (d > maxD) d = maxD;
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('انتخاب تاریخ شمسی', style: TextStyle(color: Colors.white, fontSize: 15)),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: y,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'سال', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [for (var i = Jalali.now().year - 2; i <= Jalali.now().year + 5; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) { if (v != null) setLocal(() { y = v; }); },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: m,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'ماه', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(months[i - 1]))],
                  onChanged: (v) { if (v != null) setLocal(() { m = v; }); },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: d.clamp(1, maxD),
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'روز', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [for (var i = 1; i <= maxD; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) { if (v != null) setLocal(() { d = v; }); },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, Jalali(y, m, d.clamp(1, Jalali(y, m, 1).monthLength))),
              child: const Text('تأیید', style: TextStyle(color: AppColors.purpleGlow)),
            ),
          ],
        );
      });
    },
  );
}

String formatJalali(Jalali j) =>
    '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';


String formatAnyDate(dynamic raw) {
  if (raw == null) return '';
  final s = raw.toString().trim();
  if (s.isEmpty) return '';
  if (s.contains('/') && (s.startsWith('13') || s.startsWith('14'))) return s;
  try {
    DateTime? dt = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (dt == null && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      dt = DateTime.tryParse(s.substring(0, 10));
    }
    if (dt == null) return s;
    final j = Jalali.fromDateTime(dt);
    final date = formatJalali(j);
    final hasTime = s.contains(':') || s.contains('T') || s.length > 12;
    if (!hasTime) return date;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$date  $hh:$mm';
  } catch (_) {
    return s;
  }
}
