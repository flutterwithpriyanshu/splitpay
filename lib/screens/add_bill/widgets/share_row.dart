import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/screens/add_bill/widgets/bare_input.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// One person row: avatar, name, % share, amount box.
/// [controller] null = read-only [value] (equal mode).
class AddBillShareRow extends StatelessWidget {
  const AddBillShareRow({
    super.key,
    required this.leading,
    required this.name,
    required this.subtitle,
    this.controller,
    this.value = '',
    this.hint = '0',
    this.needsShare = false,
    this.onChanged,
  });

  final Widget leading;
  final String name;
  final String subtitle;
  final TextEditingController? controller;
  final String value;
  final String hint;
  final bool needsShare;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final amountStyle = AppText.labelLg.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: needsShare ? AppColors.error : AppColors.textPrimary,
    ).tabular;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: needsShare ? AppColors.primaryTint : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: needsShare
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (needsShare) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Needs share',
                          style: AppText.labelSm.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ).tabular,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 108,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.inner),
            ),
            child: Row(
              children: [
                Text(AppCurrency.symbol, style: amountStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: controller == null
                      ? Text(value, style: amountStyle)
                      : TextField(
                          controller: controller,
                          onChanged: (_) => onChanged?.call(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          style: amountStyle,
                          decoration: bareInput(
                            hint,
                            hintStyle: amountStyle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
