import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationSectionHeader extends StatelessWidget {
  const NotificationSectionHeader({
    super.key,
    required this.label,
    required this.unread,
  });

  final String label;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppText.labelSm.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (unread > 0)
          Text(
            '$unread unread',
            style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}
