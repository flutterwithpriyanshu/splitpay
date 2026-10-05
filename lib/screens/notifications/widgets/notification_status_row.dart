import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationStatusRow extends StatelessWidget {
  const NotificationStatusRow({super.key, required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            pending == 0
                ? 'No pending actions'
                : '$pending Pending ${pending == 1 ? 'Action' : 'Actions'}',
            style: AppText.labelMd.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'UPI Auto-Sync Live',
                style: AppText.labelSm.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
