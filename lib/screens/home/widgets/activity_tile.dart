import 'package:flutter/material.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/screens/home/widgets/quick_split.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// One row in Recent Activity. [amount] is signed from the user's side:
/// positive = money coming to you, negative = you owe.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.settled,
    required this.visual,
    required this.hidden,
    required this.settledLabel,
    required this.pendingLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool settled;
  final BillVisual visual;
  final bool hidden;
  final String settledLabel;
  final String pendingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final positive = amount >= 0;
    final amountColor = positive ? positiveText() : negativeText();
    final amountText = hidden
        ? '\u2022\u2022\u2022\u2022'
        : '${positive ? '+' : '-'}${formatMoney(amount)}';

    final Color pillBg;
    final Color pillFg;
    final IconData pillIcon;
    if (!settled) {
      pillBg = AppColors.warningTint;
      pillFg = AppColors.palette.isDark
          ? AppColors.warning
          : const Color(0xFF9A5B00);
      pillIcon = Icons.schedule_rounded;
    } else if (positive) {
      pillBg = AppColors.successTint;
      pillFg = positiveText();
      pillIcon = Icons.check_circle_outline_rounded;
    } else {
      pillBg = AppColors.surfaceRaised;
      pillFg = AppColors.textSecondary;
      pillIcon = Icons.check_rounded;
    }

    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: visual.bg,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headlineSm.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      style: AppText.headlineMd
                          .copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w800,
                          )
                          .tabular,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pillIcon, size: 14, color: pillFg),
                          const SizedBox(width: 4),
                          Text(
                            settled ? settledLabel : pendingLabel,
                            style: AppText.labelMd.copyWith(color: pillFg),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
