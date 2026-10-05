import 'package:flutter/material.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/local_avatar.dart';

class QuickFriend {
  final Friend friend;

  /// Positive = they owe you. Negative = you owe them.
  final double balance;
  const QuickFriend(this.friend, this.balance);
}

Color positiveText() =>
    AppColors.palette.isDark ? AppColors.success : const Color(0xFF0F7A55);

Color negativeText() =>
    AppColors.palette.isDark ? AppColors.error : const Color(0xFF9B1239);

class QuickSplitStrip extends StatelessWidget {
  const QuickSplitStrip({
    super.key,
    required this.friends,
    required this.loading,
    required this.hidden,
    required this.onAdd,
    required this.onFriendTap,
    required this.onViewAll,
  });

  final List<QuickFriend> friends;
  final bool loading;
  final bool hidden;
  final VoidCallback onAdd;
  final void Function(Friend) onFriendTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Split',
              style: AppText.headlineSm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (friends.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${friends.length}',
                  style: AppText.labelSm
                      .copyWith(color: AppColors.textSecondary)
                      .tabular,
                ),
              ),
            const Spacer(),
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: AppText.labelMd.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: loading
              ? _skeleton()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: friends.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) return _AddNew(onTap: onAdd);
                    final q = friends[i - 1];
                    return _FriendItem(
                      item: q,
                      hidden: hidden,
                      onTap: () => onFriendTap(q.friend),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _skeleton() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNew extends StatelessWidget {
  const _AddNew({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add new',
              style: AppText.bodySm.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendItem extends StatelessWidget {
  const _FriendItem({
    required this.item,
    required this.hidden,
    required this.onTap,
  });

  final QuickFriend item;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = item.balance;
    final settled = b.abs() < 0.005;
    final Color badgeBg;
    final Color badgeFg;
    final IconData badgeIcon;
    final Color pillBg;
    final Color pillFg;
    if (settled) {
      badgeBg = AppColors.surfaceRaised;
      badgeFg = AppColors.textSecondary;
      badgeIcon = Icons.check_rounded;
      pillBg = AppColors.surfaceRaised;
      pillFg = AppColors.textSecondary;
    } else if (b > 0) {
      badgeBg = AppColors.successTint;
      badgeFg = positiveText();
      badgeIcon = Icons.south_west_rounded;
      pillBg = AppColors.successTint;
      pillFg = positiveText();
    } else {
      badgeBg = AppColors.dangerTint;
      badgeFg = negativeText();
      badgeIcon = Icons.north_east_rounded;
      pillBg = AppColors.dangerTint;
      pillFg = negativeText();
    }
    final pillText = settled
        ? 'Settled'
        : hidden
        ? '\u2022\u2022\u2022\u2022'
        : formatSignedMoney(b);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: settled
                            ? AppColors.divider
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: LocalAvatar(
                      localKey: item.friend.id,
                      isProfile: false,
                      fallbackUrl: item.friend.avatarUrl,
                      radius: 25,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2.5,
                        ),
                      ),
                      child: Icon(badgeIcon, size: 11, color: badgeFg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.friend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                pillText,
                maxLines: 1,
                style: AppText.labelSm
                    .copyWith(color: pillFg, fontSize: 12)
                    .tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
