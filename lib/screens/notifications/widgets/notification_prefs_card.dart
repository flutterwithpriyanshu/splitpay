import 'package:flutter/material.dart';
import 'package:splitpay/screens/settings_screen.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

class NotificationPrefsCard extends StatelessWidget {
  const NotificationPrefsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Preferences',
                  style: AppText.labelLg.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Customize push alerts & reminders',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
