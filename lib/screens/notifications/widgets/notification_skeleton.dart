import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
