import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/core/notification_feed.dart';
import 'package:splitpay/core/notification_prefs.dart';
import 'package:splitpay/core/notification_store.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/bill_detail_screen.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/screens/group_details_screen.dart';
import 'package:splitpay/screens/notifications/widgets/notification_card.dart';
import 'package:splitpay/screens/notifications/widgets/notification_empty.dart';
import 'package:splitpay/screens/notifications/widgets/notification_filter_bar.dart';
import 'package:splitpay/screens/notifications/widgets/notification_prefs_card.dart';
import 'package:splitpay/screens/notifications/widgets/notification_section_header.dart';
import 'package:splitpay/screens/notifications/widgets/notification_skeleton.dart';
import 'package:splitpay/screens/notifications/widgets/notification_status_row.dart';
import 'package:splitpay/screens/notifications/widgets/notification_swipe_delete.dart';
import 'package:splitpay/screens/notifications/widgets/notification_top_bar.dart';
import 'package:splitpay/screens/shared_group_details_screen.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Feed built from bills, wallet transactions and groups, kept in a local
/// file (core/notification_store.dart). Swipe a card right to delete it,
/// top-bar bin clears all. Opening it from the home bell marks notifications
/// as read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int _seenAt = notificationLastSeenNotifier.value;
  NotificationFilter _filter = NotificationFilter.all;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isUnread(AppNotification n) =>
      n.kind != NotifKind.security && n.time.millisecondsSinceEpoch > _seenAt;

  bool _matches(AppNotification n) {
    switch (_filter) {
      case NotificationFilter.all:
        return true;
      case NotificationFilter.unread:
        return _isUnread(n);
      case NotificationFilter.payments:
        return n.kind == NotifKind.paymentRequest ||
            n.kind == NotifKind.paymentReceived ||
            n.kind == NotifKind.paymentSent;
      case NotificationFilter.expenses:
        return n.kind == NotifKind.expenseAdded ||
            n.kind == NotifKind.simplified;
      case NotificationFilter.reminders:
        return n.kind == NotifKind.groupReminder;
    }
  }

  Future<void> _confirmClear(List<AppNotification> items) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This removes every notification from this device. '
          'New activity will still show up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear all', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await NotificationStore.instance.clearIds(items.map((n) => n.id));
    if (mounted) showAppToast(context, 'All notifications cleared');
  }

  // ---------- navigation ----------

  void _openGroup(Group g) {
    final mine = g.ownerId == _myUid;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mine
            ? GroupDetailsScreen(group: g)
            : SharedGroupDetailsScreen(group: g),
      ),
    );
  }

  void _openFriend(AppNotification n) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FriendDetailsScreen(friend: n.friend!)),
  );

  void _openBreakdown(AppNotification n) {
    final bill = n.bill;
    if (bill == null) return;
    // BillDetailScreen is uid-based: group + shared bills only.
    final uidBased =
        bill.participantUids.isNotEmpty &&
        (bill.groupId != null || bill.ownerId != _myUid);
    if (uidBased) {
      final v = billVisual(bill.title);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(
            bill: bill,
            icon: v.icon,
            iconBg: v.bg,
            iconColor: v.color,
          ),
        ),
      );
    } else if (n.friend != null) {
      _openFriend(n);
    }
  }

  /// Settle flows (UPI, cash, partial) live on the friend + group pages.
  /// Group bills settle from the group, 1:1 bills from the friend.
  void _settle(AppNotification n) {
    if (n.group != null) {
      _openGroup(n.group!);
    } else if (n.friend != null) {
      _openFriend(n);
    } else {
      showAppToast(context, 'Add this person as a friend to settle up');
    }
  }

  VoidCallback? _tapFor(AppNotification n) {
    switch (n.kind) {
      case NotifKind.paymentRequest:
      case NotifKind.expenseAdded:
        return n.bill == null ? null : () => _openBreakdown(n);
      case NotifKind.groupReminder:
      case NotifKind.simplified:
        final g = n.group;
        return g == null ? null : () => _openGroup(g);
      default:
        return null;
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
          child: NotificationFeedScope(
            builder: (context, items, loading) => Column(
              children: [
                NotificationTopBar(
                  myUid: _myUid,
                ),
                Expanded(child: _body(items, loading)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<AppNotification>> _sections(List<AppNotification> shown) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final out = <String, List<AppNotification>>{
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER': [],
    };
    for (final n in shown) {
      final d = DateTime(n.time.year, n.time.month, n.time.day);
      if (!d.isBefore(today)) {
        out['TODAY']!.add(n);
      } else if (!d.isBefore(yesterday)) {
        out['YESTERDAY']!.add(n);
      } else {
        out['EARLIER']!.add(n);
      }
    }
    return out;
  }

  Widget _card(AppNotification n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NotificationSwipeDelete(
        id: n.id,
        onDelete: () => NotificationStore.instance.delete(n.id),
        child: NotificationCard(
          n: n,
          unread: _isUnread(n),
          onTap: _tapFor(n),
          onSettle: () => _settle(n),
          onBreakdown: () => _openBreakdown(n),
          onOpenGroup: _openGroup,
        ),
      ),
    );
  }

  Widget _body(List<AppNotification> all, bool loading) {
    final real = all.where((n) => n.kind != NotifKind.security).toList();
    final unreadCount = real.where(_isUnread).length;
    final pending = real.where((n) => n.isPendingAction).length;
    final shown = all.where((n) {
      if (n.kind == NotifKind.security) {
        return _filter == NotificationFilter.all;
      }
      return _matches(n);
    }).toList();
    final sections = _sections(shown);
    final noMatch =
        shown.where((n) => n.kind != NotifKind.security).isEmpty &&
        _filter != NotificationFilter.all;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        NotificationStatusRow(pending: pending),
        const SizedBox(height: 14),
        NotificationActionsBar(
          hasItems: all.isNotEmpty,
          onClearAll: () => _confirmClear(all),
        ),
        NotificationFilterBar(
          selected: _filter,
          onSelect: (f) => setState(() => _filter = f),
          total: real.length,
          unread: unreadCount,
        ),
        const SizedBox(height: 18),
        if (loading && real.isEmpty)
          ...List.generate(3, (_) => const NotificationSkeleton())
        else if (noMatch)
          const NotificationEmpty()
        else if (real.isEmpty) ...[
          const NotificationEmpty(),
          const SizedBox(height: 12),
          ...sections['EARLIER']!.map(_card),
        ] else
          for (final e in sections.entries)
            if (e.value.isNotEmpty) ...[
              NotificationSectionHeader(
                label: e.key,
                unread: e.value.where(_isUnread).length,
              ),
              const SizedBox(height: 10),
              for (final n in e.value) _card(n),
              const SizedBox(height: 8),
            ],
        const SizedBox(height: 8),
        const NotificationPrefsCard(),
      ],
    );
  }
}
