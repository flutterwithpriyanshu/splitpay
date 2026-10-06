import 'package:flutter/material.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Red strip: "₹200 left to assign" / "over assigned" + SPLIT EVENLY.
class AddBillShareBanner extends StatelessWidget {
  const AddBillShareBanner({
    super.key,
    required this.left,
    required this.onSplitEvenly,
  });

  /// >0 left, <0 over.
  final double left;
  final VoidCallback onSplitEvenly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatMoney(left.abs())} '
              '${left > 0 ? 'left to assign' : 'over assigned'}',
              style: AppText.labelMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ).tabular,
            ),
          ),
          TextButton(
            onPressed: onSplitEvenly,
            child: Text(
              'SPLIT EVENLY',
              style: AppText.labelSm.copyWith(
                color: AppColors.error,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
