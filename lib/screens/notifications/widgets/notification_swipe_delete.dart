import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Swipe right → delete. Red tint with a round delete button behind.
class NotificationSwipeDelete extends StatelessWidget {
  const NotificationSwipeDelete({
    super.key,
    required this.id,
    required this.onDelete,
    required this.child,
  });

  final String id;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('notif_$id'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.35},
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      child: child,
    );
  }
}
