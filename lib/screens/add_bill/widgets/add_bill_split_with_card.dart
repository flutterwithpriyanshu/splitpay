import 'package:flutter/material.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/screens/add_bill/widgets/person_avatar_chip.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// "Split with": Add new, friends (tap = toggle), You. See all = wrap.
class AddBillSplitWithCard extends StatelessWidget {
  const AddBillSplitWithCard({
    super.key,
    required this.friends,
    required this.selectedIds,
    required this.onToggle,
    required this.emptyText,
    this.onAddNew,
    this.onSeeAll,
  });

  final List<Friend> friends;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final String emptyText;

  /// Null = hidden (inside a group members are fixed).
  final VoidCallback? onAddNew;

  /// Opens full picker (`SelectFriendsScreen`).
  final VoidCallback? onSeeAll;

  Widget _circle(Widget child) => Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      shape: BoxShape.circle,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (onAddNew != null)
        PersonAvatarChip(
          label: 'Add new',
          onTap: onAddNew,
          avatar: _circle(
            Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
          ),
        ),
      for (final f in friends)
        PersonAvatarChip(
          label: f.name.split(' ').first,
          selected: selectedIds.contains(f.id),
          dim: !selectedIds.contains(f.id),
          onTap: () => onToggle(f.id),
          avatar: LocalAvatar(
            localKey: f.id,
            isProfile: false,
            fallbackUrl: f.avatarUrl.isEmpty ? null : f.avatarUrl,
            radius: 26,
          ),
        ),
      PersonAvatarChip(
        label: 'You',
        selected: true,
        avatar: _circle(
          Text(
            'ME',
            style: AppText.labelMd.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split with',
                      style: AppText.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${selectedIds.length + 1} people selected',
                      style: AppText.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSeeAll != null && friends.isNotEmpty)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See all',
                    style: AppText.labelMd.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                emptyText,
                style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => chips[i],
            ),
          ),
        ],
      ),
    );
  }
}
