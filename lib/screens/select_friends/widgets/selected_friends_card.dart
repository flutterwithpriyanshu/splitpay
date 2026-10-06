import 'package:flutter/material.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/person_avatar_chip.dart';
import 'package:splitpay/screens/select_friends/widgets/friend_pick_avatar.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// "Selected (4 of 10)" + Clear all + avatar strip (You first).
class SelectedFriendsCard extends StatelessWidget {
  const SelectedFriendsCard({
    super.key,
    required this.selected,
    required this.total,
    required this.onRemove,
    required this.onClear,
  });

  final List<Friend> selected;
  final int total;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected (${selected.length} of $total)',
                  style: AppText.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Clear all',
                    style: AppText.labelMd.copyWith(color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                PersonAvatarChip(
                  label: 'You',
                  avatar: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          'You',
                          style: AppText.labelMd.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final f in selected)
                  PersonAvatarChip(
                    label: f.name.split(' ').first,
                    onTap: () => onRemove(f.id),
                    avatar: FriendPickAvatar(friend: f, radius: 26),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
