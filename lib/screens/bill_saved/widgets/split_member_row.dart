import 'package:flutter/material.dart';
import 'package:splitpay/core/bill_saved_data.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// One person in the split breakdown. Amount pill green when I paid
/// (they owe me); plain amount when someone else paid.
class SplitMemberRow extends StatelessWidget {
  const SplitMemberRow({super.key, required this.row, required this.paidByMe});

  final BillSavedRow row;
  final bool paidByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  row.subtitle,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          paidByMe
              ? AmountPill(amount: row.amount)
              : Text(
                  formatMoney(row.amount),
                  style: AppText.labelLg.copyWith(
                    color: AppColors.textPrimary,
                  ).tabular,
                ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final id = row.friendId;
    if (id != null) {
      return LocalAvatar(
        localKey: id,
        isProfile: false,
        fallbackUrl: (row.avatarUrl ?? '').isEmpty ? null : row.avatarUrl,
        radius: 22,
      );
    }
    final initial = row.name.isEmpty ? '?' : row.name[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryTint,
      child: Text(
        initial,
        style: AppText.labelLg.copyWith(color: AppColors.primary),
      ),
    );
  }
}
