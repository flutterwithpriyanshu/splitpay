import 'package:flutter/material.dart';
import 'package:splitpay/core/custom_category.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class CategoryAccentPicker extends StatelessWidget {
  const CategoryAccentPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accent Tone',
                    style: AppText.headlineSm.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Highlights split charts, ledger summaries & alerts',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoryTones[selected].name,
                style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < categoryTones.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryTones[i].color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == selected
                              ? categoryTones[i].color.withValues(alpha: 0.35)
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: i == selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
