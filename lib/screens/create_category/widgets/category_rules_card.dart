import 'package:flutter/material.dart';
import 'package:splitpay/core/app_currency.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class CategoryRulesCard extends StatelessWidget {
  const CategoryRulesCard({
    super.key,
    required this.split,
    required this.onSplit,
    required this.groups,
    required this.groupId,
    required this.onGroup,
    required this.capEnabled,
    required this.onCapEnabled,
    required this.capController,
  });
  final String split;
  final ValueChanged<String> onSplit;
  final List<Group> groups;
  final String? groupId;
  final ValueChanged<String?> onGroup;
  final bool capEnabled;
  final ValueChanged<bool> onCapEnabled;
  final TextEditingController capController;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String v) => Expanded(
      child: GestureDetector(
        onTap: () => onSplit(v),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: split == v ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: Text(
            label,
            style: AppText.labelMd.copyWith(
              color: split == v ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Automation Rules',
                style: AppText.headlineSm.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Default Split Method',
            style: AppText.labelMd.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                seg('Equally', 'equal'),
                seg('By Shares', 'shares'),
                seg('Percentage', 'percentage'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Assign To Specific Group',
            style: AppText.labelMd.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: groups.any((g) => g.id == groupId) ? groupId : null,
                hint: const Text('All groups'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All groups'),
                  ),
                  ...groups.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(
                        '${g.name} (${g.allMemberUids.length} members)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onGroup,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Expense Cap',
                            style: AppText.labelMd.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Alert when this category exceeds limit',
                            style: AppText.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: capEnabled,
                      onChanged: onCapEnabled,
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      activeTrackColor: AppColors.success,
                    ),
                  ],
                ),
                if (capEnabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Target Cap:',
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: capController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: AppText.currencyMd.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surface,
                            prefixText: '${AppCurrency.symbol} ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successTint,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '/ month',
                          style: AppText.labelSm.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
