import 'package:flutter/material.dart';
import 'package:splitpay/core/split_math.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Equal | Custom segmented pill.
class SplitModeToggle extends StatelessWidget {
  const SplitModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SplitMethod value;
  final ValueChanged<SplitMethod> onChanged;

  Widget _seg(String label, SplitMethod m) {
    final on = value == m;
    return GestureDetector(
      onTap: () => onChanged(m),
      child: Container(
        height: 36,
        width: 82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          boxShadow: on ? AppShadows.card : null,
        ),
        child: Text(
          label,
          style: AppText.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            color: on ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('Equal', SplitMethod.equal),
          _seg('Custom', SplitMethod.custom),
        ],
      ),
    );
  }
}
