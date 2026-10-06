import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Caps title (+ optional icon) left, count text right.
class FriendSectionHeader extends StatelessWidget {
  const FriendSectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    this.icon,
  });

  final String title;
  final String trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: AppText.labelSm.copyWith(
                color: icon != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            trailing,
            style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
