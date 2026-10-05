import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';
import 'package:splitpay/widgets/local_avatar.dart';

class NotificationTopBar extends StatelessWidget {
  const NotificationTopBar({super.key, required this.myUid});

  final String myUid;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.only(left: 4, right: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          const AppLogo(size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.headlineSm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          LocalAvatar(localKey: myUid, isProfile: true, radius: 16),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class NotificationActionsBar extends StatelessWidget {
  const NotificationActionsBar({
    super.key,
    required this.hasItems,
    required this.onClearAll,
  });

  final bool hasItems;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasItems)
          TextButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Delete all'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
      ],
    );
  }
}
