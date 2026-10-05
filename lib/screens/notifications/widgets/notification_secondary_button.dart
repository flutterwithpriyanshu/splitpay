import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationSecondaryButton extends StatelessWidget {
  const NotificationSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(AppRadius.control);
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.labelMd.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
