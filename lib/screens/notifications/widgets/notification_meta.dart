import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Small icon + text line (time, due date).
class NotificationMeta extends StatelessWidget {
  const NotificationMeta(this.icon, this.text, {super.key, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 5),
        Text(text, style: AppText.bodySm.copyWith(color: c, fontSize: 12)),
      ],
    );
  }
}
