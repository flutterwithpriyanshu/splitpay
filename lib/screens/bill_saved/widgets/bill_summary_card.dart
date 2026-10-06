import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/core/bill_category_label.dart';
import 'package:splitpay/core/bill_saved_data.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/screens/bill_saved/widgets/split_member_row.dart';
import 'package:splitpay/screens/bill_saved/widgets/upi_status_tile.dart';
import 'package:splitpay/services/upi_link_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// White card: category, title, total, split breakdown, UPI status.
class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({super.key, required this.data, required this.state});

  final BillSavedData data;
  final ValueListenable<UpiShareState> state;

  @override
  Widget build(BuildContext context) {
    final visual = billVisual(data.title);
    final sub = AppText.bodySm.copyWith(color: AppColors.textSecondary);
    final caps = AppText.labelSm.copyWith(color: AppColors.textSecondary);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(data.categoryIcon ?? visual.icon, size: 13, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              data.categoryLabel?.toUpperCase() ??
                                  billCategoryLabel(data.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.labelSm.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: sub,
                        children: [
                          const TextSpan(text: 'Paid by '),
                          TextSpan(
                            text: data.paidByName,
                            style: sub.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(text: ' \u2022 ${formatDate(data.date)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 4),
                  Text('TOTAL BILL', style: caps),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(data.amount),
                    style: AppText.headlineLg.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ).tabular,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SPLIT BREAKDOWN', style: caps),
              Text(
                '${data.people} people (You + ${data.rows.length})',
                style: AppText.labelSm.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in data.rows) ...[
            SplitMemberRow(row: r, paidByMe: data.paidByMe),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          ValueListenableBuilder<UpiShareState>(
            valueListenable: state,
            builder: (_, s, __) => UpiStatusTile(
              state: s,
              count: data.rows.where((r) => r.linkedUid != null).length,
            ),
          ),
        ],
      ),
    );
  }
}
