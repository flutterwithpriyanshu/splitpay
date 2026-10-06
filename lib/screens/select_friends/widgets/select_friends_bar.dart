import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Bottom bar: count + Confirm (N).
class SelectFriendsBar extends StatelessWidget {
  const SelectFriendsBar({
    super.key,
    required this.count,
    required this.onConfirm,
  });

  final int count;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$count ${count == 1 ? 'friend' : 'friends'} selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Bill splits evenly by default',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GradientButton(
                label: 'Confirm ($count)',
                icon: Icons.arrow_forward_rounded,
                expand: false,
                onPressed: count == 0 ? null : onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
