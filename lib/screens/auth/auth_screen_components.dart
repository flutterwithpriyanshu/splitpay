import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

/// Segmented step pill: 1. Phone / 2. Security / 3. Verify OTP.
class AuthTabs extends StatelessWidget {
  const AuthTabs({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['1. Phone', '2. Security', '3. Verify OTP'];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == step;
          final done = i < step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 40,
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: active ? AppShadows.card : null,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        labels[i],
                        style: AppText.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Primary gradient button with trailing icon.
class AuthButton extends StatelessWidget {
  const AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final radius = BorderRadius.circular(AppRadius.control);
    return Opacity(
      opacity: (onTap == null && !loading) ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: radius,
            boxShadow: AppShadows.fab,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.labelLg.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(icon, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google "G" drawn with arcs (no asset needed).
class GoogleGPainter extends CustomPainter {
  const GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double r(double deg) => deg * math.pi / 180;

    canvas.drawArc(rect, r(200), r(115), false, p(const Color(0xFFEA4335)));
    canvas.drawArc(rect, r(135), r(65), false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, r(45), r(90), false, p(const Color(0xFF34A853)));
    canvas.drawArc(rect, r(-5), r(50), false, p(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTRB(
        s / 2,
        s / 2 - stroke / 2,
        s - stroke * 0.05,
        s / 2 + stroke / 2,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Inline notice shown under the Send OTP button while a cooldown runs.
class CooldownNotice extends StatelessWidget {
  const CooldownNotice({
    required this.tooMany,
    required this.timeLeft,
    super.key,
  });

  final bool tooMany;
  final String timeLeft;

  @override
  Widget build(BuildContext context) {
    final color = tooMany ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tooMany ? Icons.shield_outlined : Icons.timer_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tooMany
                  ? 'Too many attempts from this device. Try again in '
                        '$timeLeft, or continue with Google below.'
                  : 'You can request a new OTP in $timeLeft.',
              style: AppText.bodySm.copyWith(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
