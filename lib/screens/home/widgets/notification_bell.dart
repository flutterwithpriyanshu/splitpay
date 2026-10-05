import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/core/notification_feed.dart';
import 'package:splitpay/core/notification_prefs.dart';
import 'package:splitpay/screens/notifications_screen.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Bell with an unread count. Opening the feed marks all notifications read.
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
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await NotificationPrefs.load(uid);
                  await NotificationPrefs.markAllRead();
                }
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
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
                        top: 2,
                        right: 1,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
