import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

enum NotificationFilter { all, unread, payments, expenses, reminders }

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.total,
    required this.unread,
  });

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onSelect;
  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _chip('All', NotificationFilter.all, count: total),
          _chip(
            'Unread',
            NotificationFilter.unread,
            count: unread,
            dot: true,
          ),
          _chip(
            'Payments',
            NotificationFilter.payments,
            icon: Icons.account_balance_wallet_outlined,
          ),
          _chip(
            'Expenses',
            NotificationFilter.expenses,
            icon: Icons.receipt_long_outlined,
          ),
          _chip(
            'Reminders',
            NotificationFilter.reminders,
            icon: Icons.alarm_rounded,
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    NotificationFilter f, {
    IconData? icon,
    int? count,
    bool dot = false,
  }) {
    final on = selected == f;
    final fg = on ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onSelect(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: on ? AppColors.primary : AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: on ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: on ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppText.labelMd.copyWith(color: fg, fontSize: 13),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                on
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$count',
                          style: AppText.labelSm.copyWith(color: fg).tabular,
                        ),
                      )
                    : Text(
                        '$count',
                        style: AppText.labelMd
                            .copyWith(color: AppColors.textSecondary, fontSize: 12)
                            .tabular,
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
