import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Check badge + confetti + title. Keep const-like: never rebuilt by the
/// screen (flutter_animate would restart).
class SavedHero extends StatelessWidget {
  const SavedHero({super.key, required this.isUpdate});

  final bool isUpdate;

  static const _mint = Color(0xFF6BF5C6);
  static const _deep = Color(0xFF0B6B4F);

  // dx, dy (fraction of box), size, color, pill?
  static const _confetti = <(double, double, double, Color, bool)>[
    (0.16, 0.06, 18, _mint, false),
    (0.84, 0.14, 12, _mint, false),
    (0.70, 0.17, 10, Color(0xFF5B3DF5), false),
    (0.07, 0.34, 14, Color(0xFFFF8FA3), true),
    (0.30, 0.78, 10, Color(0xFFD6D0FF), false),
    (0.80, 0.80, 16, _deep, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              alignment: Alignment.center,
              children: [
                for (final (dx, dy, size, color, pill) in _confetti)
                  Positioned(
                    left: c.maxWidth * dx,
                    top: 190 * dy,
                    child: Transform.rotate(
                      angle: pill ? 0.7 : 0,
                      child: Container(
                        width: size,
                        height: pill ? size * 0.5 : size,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: _mint.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _deep,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
              ],
            ),
          ),
        ),
        Text(
          isUpdate ? 'Bill updated!' : 'Bill saved!',
          style: AppText.headlineMd.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            isUpdate
                ? 'Your changes are saved and balances have been updated.'
                : 'Your bill has been added successfully and balances have been updated.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
