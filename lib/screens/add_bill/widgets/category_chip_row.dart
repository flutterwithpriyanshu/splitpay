import 'package:flutter/material.dart';
import 'package:splitpay/core/add_bill_category.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// "SELECT CATEGORY" + horizontal chips. Tap selected chip = unselect.
class AddBillCategoryRow extends StatelessWidget {
  const AddBillCategoryRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AddBillCategory? selected;
  final ValueChanged<AddBillCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT CATEGORY',
          style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kAddBillCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = kAddBillCategories[i];
              final on = selected == c;
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => onSelect(on ? null : c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: on ? AppColors.primary : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    children: [
                      Icon(c.icon, size: 16, color: on ? Colors.white : c.color),
                      const SizedBox(width: 6),
                      Text(
                        c.label,
                        style: AppText.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
