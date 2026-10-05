import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationEmpty extends StatelessWidget {
  const NotificationEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up",
            style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'New bills, payments and reminders show up here.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
