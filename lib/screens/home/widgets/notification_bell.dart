import 'package:flutter/material.dart';
import 'package:splitpay/core/notification_feed.dart';
import 'package:splitpay/core/notification_prefs.dart';
import 'package:splitpay/screens/notifications_screen.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Bell with red dot when the feed has anything newer than the last time
/// the user opened it. Opening the feed then marks everything read.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationFeedScope(
      builder: (context, items, loading) {
        return ValueListenableBuilder<int>(
          valueListenable: notificationLastSeenNotifier,
          builder: (context, seen, _) {
            final unread = items
                .where(
                  (n) =>
                      n.kind != NotifKind.security &&
                      n.time.millisecondsSinceEpoch > seen,
                )
                .length;
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
                await NotificationPrefs.markAllRead();
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                      color: AppColors.textPrimary,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 9,
                        right: 11,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
