import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/screens/add_bill/widgets/bare_input.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';

/// Big amount input + quick-add chips.
class AddBillAmountCard extends StatelessWidget {
  const AddBillAmountCard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onQuickAdd,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<int> onQuickAdd;

  static const _quick = [100, 500, 1000];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'TOTAL AMOUNT',
                style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppCurrency.symbol,
                style: AppText.displayLgMobile.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textAlign: TextAlign.center,
                  style: AppText.displayLgMobile.copyWith(
                    fontSize: 40,
                    color: AppColors.textPrimary,
                  ).tabular,
                  decoration: bareInput(
                    '0',
                    hintStyle: AppText.displayLgMobile.copyWith(
                      fontSize: 40,
                      color: AppColors.divider,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 230,
            height: 3,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final n in _quick) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onQuickAdd(n),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '+${formatMoney(n.toDouble())}',
                      style: AppText.labelMd.copyWith(
                        color: AppColors.textPrimary,
                      ).tabular,
                    ),
                  ),
                ),
                if (n != _quick.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
