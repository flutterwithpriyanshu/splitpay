import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationChip extends StatelessWidget {
  const NotificationChip(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppText.labelMd.copyWith(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
