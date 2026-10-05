import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';
import 'package:splitpay/widgets/local_avatar.dart';

class NotificationTopBar extends StatelessWidget {
  const NotificationTopBar({
    super.key,
    required this.myUid,
    required this.hasItems,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final String myUid;
  final bool hasItems;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

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
          _icon(
            Icons.arrow_back_rounded,
            AppColors.textPrimary,
            'Back',
            () => Navigator.of(context).maybePop(),
          ),
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
          _icon(
            Icons.done_all_rounded,
            AppColors.primary,
            'Mark all as read',
            onMarkAllRead,
          ),
          if (hasItems)
            _icon(
              Icons.delete_sweep_outlined,
              AppColors.error,
              'Clear all',
              onClearAll,
            ),
          const SizedBox(width: 6),
          LocalAvatar(localKey: myUid, isProfile: true, radius: 16),
        ],
      ),
    );
  }

  Widget _icon(IconData i, Color c, String tip, VoidCallback onTap) {
    return IconButton(
      tooltip: tip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(i, color: c, size: 22),
    );
  }
}
