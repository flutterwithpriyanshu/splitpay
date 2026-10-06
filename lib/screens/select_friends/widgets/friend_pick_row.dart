import 'package:flutter/material.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/select_friends/widgets/friend_pick_avatar.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Checkbox circle, avatar, name, phone, balance pill.
class FriendPickRow extends StatelessWidget {
  const FriendPickRow({
    super.key,
    required this.friend,
    required this.selected,
    required this.balance,
    required this.onTap,
  });

  final Friend friend;
  final bool selected;
  final double balance;
  final VoidCallback onTap;

  static String _phone(String? raw) {
    final d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length == 10) return '+91 ${d.substring(0, 5)} ${d.substring(5)}';
    return raw ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.control),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            FriendPickAvatar(friend: friend, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _phone(friend.phoneNumber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ).tabular,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AmountPill(amount: balance),
          ],
        ),
      ),
    );
  }
}
