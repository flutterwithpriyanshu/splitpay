import 'package:flutter/material.dart';
import 'package:splitpay/services/upi_link_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Status strip under the split list. Reflects real state of the
/// "Share UPI Link" action (idle / sending / sent).
class UpiStatusTile extends StatelessWidget {
  const UpiStatusTile({super.key, required this.state, required this.count});

  final UpiShareState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final sent = state == UpiShareState.sent;
    final title = sent ? 'UPI link sent' : 'UPI link ready';
    final body = switch (state) {
      UpiShareState.idle => 'Tap Share UPI Link to notify $count '
          '${count == 1 ? 'person' : 'people'}',
      UpiShareState.sending => 'Sending notifications...',
      UpiShareState.sent => 'Notification sent to your friends',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sent ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (sent)
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 22,
            ),
        ],
      ),
    );
  }
}
