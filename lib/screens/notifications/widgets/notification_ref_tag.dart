import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Monospace transaction ref, e.g. #TXN-A1B2C3.
class NotificationRefTag extends StatelessWidget {
  const NotificationRefTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
