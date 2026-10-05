import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/core/notification_feed.dart';
import 'package:splitpay/core/notification_prefs.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/bill_detail_screen.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/screens/group_details_screen.dart';
import 'package:splitpay/screens/home/widgets/quick_split.dart'
    show positiveText, negativeText;
import 'package:splitpay/screens/settings_screen.dart';
import 'package:splitpay/screens/shared_group_details_screen.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

enum _Filter { all, unread, payments, expenses, reminders }

/// Feed built from bills, wallet transactions and groups (see
/// core/notification_feed.dart). Opening the screen does not mark anything
/// read. Leaving it (via the home bell) or tapping the double-check does.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late int _seenAt = notificationLastSeenNotifier.value;
  _Filter _filter = _Filter.all;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isUnread(AppNotification n) =>
      n.kind != NotifKind.security && n.time.millisecondsSinceEpoch > _seenAt;

  bool _matches(AppNotification n) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.unread:
        return _isUnread(n);
      case _Filter.payments:
        return n.kind == NotifKind.paymentRequest ||
            n.kind == NotifKind.paymentReceived ||
            n.kind == NotifKind.paymentSent;
      case _Filter.expenses:
        return n.kind == NotifKind.expenseAdded ||
            n.kind == NotifKind.simplified;
      case _Filter.reminders:
        return n.kind == NotifKind.groupReminder;
    }
  }

  Future<void> _markAllRead() async {
    await NotificationPrefs.markAllRead();
    if (mounted) setState(() => _seenAt = notificationLastSeenNotifier.value);
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendDetailsScreen(friend: n.friend!),
        ),
      );
    }
  }

  /// Settle flows (UPI, cash, partial) live on the friend + group pages.
  /// Group bills settle from the group, 1:1 bills from the friend.
  void _settle(AppNotification n) {
    if (n.group != null) {
      _openGroup(n.group!);
    } else if (n.friend != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendDetailsScreen(friend: n.friend!),
        ),
      );
    } else {
      showAppToast(context, 'Add this person as a friend to settle up');
    }
  }

  void _onCardTap(AppNotification n) {
    switch (n.kind) {
      case NotifKind.paymentRequest:
      case NotifKind.expenseAdded:
        _openBreakdown(n);
        break;
      case NotifKind.groupReminder:
      case NotifKind.simplified:
        if (n.group != null) _openGroup(n.group!);
        break;
      default:
        break;
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
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: NotificationFeedScope(
                  builder: (context, items, loading) {
                    return _body(items, loading);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          const AppLogo(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.headlineMd.copyWith(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
            icon: Icon(Icons.done_all_rounded, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 2),
            child: LocalAvatar(localKey: _myUid, isProfile: true, radius: 18),
          ),
        ],
      ),
    );
  }

  Widget _body(List<AppNotification> all, bool loading) {
    final real = all.where((n) => n.kind != NotifKind.security).toList();
    final unreadCount = real.where(_isUnread).length;
    final pending = real.where((n) => n.isPendingAction).length;
    final shown = all.where((n) {
      if (n.kind == NotifKind.security) return _filter == _Filter.all;
      return _matches(n);
    }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sections = <String, List<AppNotification>>{
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER': [],
    };
    for (final n in shown) {
      final d = DateTime(n.time.year, n.time.month, n.time.day);
      if (!d.isBefore(today)) {
        sections['TODAY']!.add(n);
      } else if (!d.isBefore(yesterday)) {
        sections['YESTERDAY']!.add(n);
      } else {
        sections['EARLIER']!.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _statusRow(pending),
        const SizedBox(height: 14),
        _filters(real.length, unreadCount),
        const SizedBox(height: 18),
        if (loading && real.isEmpty)
          ..._skeleton()
        else if (shown.where((n) => n.kind != NotifKind.security).isEmpty &&
            _filter != _Filter.all)
          _empty()
        else if (real.isEmpty && !loading) ...[
          _empty(),
          const SizedBox(height: 12),
          ...sections['EARLIER']!.map((n) => _card(n)),
        ] else
          for (final entry in sections.entries)
            if (entry.value.isNotEmpty) ...[
              _sectionHeader(entry.key, entry.value.where(_isUnread).length),
              const SizedBox(height: 10),
              for (final n in entry.value) _card(n),
              const SizedBox(height: 8),
            ],
        const SizedBox(height: 8),
        _prefsCard(),
      ],
    );
  }

  Widget _statusRow(int pending) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: Icon(
            Icons.notifications_active_outlined,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            pending == 0
                ? 'No pending actions'
                : '$pending Pending ${pending == 1 ? 'Action' : 'Actions'}',
            style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Live sync',
                style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filters(int total, int unread) {
    Widget chip(String label, _Filter f, {IconData? icon, int? count}) {
      final selected = _filter == f;
      final fg = selected ? Colors.white : AppColors.textPrimary;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.divider.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppText.labelMd.copyWith(color: fg)),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$count',
                      style: AppText.labelMd.copyWith(color: fg).tabular,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          chip('All', _Filter.all, count: total),
          chip('Unread', _Filter.unread, count: unread),
          chip(
            'Payments',
            _Filter.payments,
            icon: Icons.account_balance_wallet_outlined,
          ),
          chip('Expenses', _Filter.expenses, icon: Icons.receipt_long_outlined),
          chip('Reminders', _Filter.reminders, icon: Icons.alarm_rounded),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int unread) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppText.labelSm.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (unread > 0)
          Text(
            '$unread unread',
            style: AppText.labelMd.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  List<Widget> _skeleton() {
    return List.generate(
      3,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 52,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up",
            style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'New bills, payments and reminders show up here.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _prefsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.inner),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 22,
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
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Manage push alerts in Settings',
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- cards ----------

  String _timeAgo(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final dayDiff = today.difference(day).inDays;

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (dayDiff == 0) return '${diff.inHours}h ago';
    if (dayDiff == 1) return 'Yesterday, ${_clock(t)}';
    if (dayDiff < 7) return '$dayDiff days ago';
    return formatDate(t);
  }

  String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  TextSpan _name(String t) => TextSpan(
    text: t,
    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
  );

  TextSpan _money(String t, Color c) => TextSpan(
    text: t,
    style: TextStyle(fontWeight: FontWeight.w800, color: c),
  );

  TextSpan _quoted(String t) => TextSpan(
    text: "'$t'",
    style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary),
  );

  TextSpan _group(String t) => TextSpan(
    text: t,
    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
  );

  Widget _chip(
    String text, {
    required Color bg,
    required Color fg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: AppText.labelMd.copyWith(color: fg, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 5),
        Text(text, style: AppText.bodySm.copyWith(color: c, fontSize: 13)),
      ],
    );
  }

  Widget _card(AppNotification n) {
    final unread = _isUnread(n);
    final posC = positiveText();
    final negC = negativeText();
    final body = TextStyle(
      fontSize: 15,
      height: 1.4,
      color: AppColors.textSecondary,
      fontFamily: AppText.bodyLg.fontFamily,
    );

    IconData icon;
    Color iconColor;
    Color iconBg;
    String title;
    Widget? chip;
    InlineSpan? text;
    final meta = <Widget>[];
    Widget? actions;
    Widget? trailingMeta;
    Widget? link;
    var showAvatar = false;

    switch (n.kind) {
      case NotifKind.paymentRequest:
        icon = Icons.south_west_rounded;
        iconColor = AppColors.error;
        iconBg = AppColors.dangerTint;
        title = 'Payment Request';
        showAvatar = true;
        if (n.urgent) {
          chip = _chip('Urgent', bg: AppColors.dangerTint, fg: negC);
        }
        text = TextSpan(
          style: body,
          children: [
            _name(n.actor ?? 'Someone'),
            const TextSpan(text: ' requested '),
            _money(formatMoney(n.amount), negC),
            if ((n.billTitle ?? '').isNotEmpty) ...[
              const TextSpan(text: ' for '),
              _quoted(n.billTitle!),
            ],
            if (n.groupName != null) ...[
              const TextSpan(text: ' in '),
              _group(n.groupName!),
            ],
            const TextSpan(text: '.'),
          ],
        );
        meta.add(_meta(Icons.schedule_rounded, _timeAgo(n.time)));
        if (n.urgent) {
          meta.add(_meta(Icons.event_rounded, 'Due Today', color: negC));
        }
        actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientButton(
              label: 'Settle via UPI (${formatMoney(n.amount)})',
              icon: Icons.bolt_rounded,
              onPressed: () => _settle(n),
            ),
            if (n.bill != null) ...[
              const SizedBox(height: 10),
              _secondaryButton(
                'View Split Breakdown',
                Icons.receipt_long_outlined,
                () => _openBreakdown(n),
              ),
            ],
          ],
        );
        break;

      case NotifKind.paymentReceived:
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.successTint;
        title = 'Payment Received';
        chip = _chip(
          'Paid & Reconciled',
          bg: AppColors.successTint,
          fg: posC,
          icon: Icons.done_all_rounded,
        );
        text = TextSpan(
          style: body,
          children: [
            _name(n.actor ?? 'Someone'),
            const TextSpan(text: ' paid you '),
            _money('+${formatMoney(n.amount)}', posC),
            if (n.note != null) TextSpan(text: ' \u2014 ${n.note}'),
            const TextSpan(text: '.'),
          ],
        );
        meta.add(_meta(Icons.schedule_rounded, _timeAgo(n.time)));
        if (n.ref != null) {
          meta.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                n.ref!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        break;

      case NotifKind.paymentSent:
        icon = Icons.north_east_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryTint;
        title = 'Payment Sent';
        chip = _chip(
          'Paid',
          bg: AppColors.primaryTint,
          fg: AppColors.primary,
          icon: Icons.check_rounded,
        );
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'You paid '),
            _name(n.actor ?? 'Someone'),
            const TextSpan(text: ' '),
            _money(formatMoney(n.amount), AppColors.textPrimary),
            if (n.note != null) TextSpan(text: ' \u2014 ${n.note}'),
            const TextSpan(text: '.'),
          ],
        );
        meta.add(_meta(Icons.schedule_rounded, _timeAgo(n.time)));
        if (n.ref != null) {
          meta.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                n.ref!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        break;

      case NotifKind.expenseAdded:
        icon = Icons.receipt_long_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryTint;
        title = 'New Expense Added';
        showAvatar = true;
        text = TextSpan(
          style: body,
          children: [
            _name(n.actor ?? 'Someone'),
            const TextSpan(text: ' added '),
            _quoted(n.billTitle ?? ''),
            TextSpan(text: ' (${formatMoney(n.billAmount)}) '),
            if (n.groupName != null) ...[
              const TextSpan(text: 'to '),
              _group(n.groupName!),
            ] else
              const TextSpan(text: 'with you'),
            const TextSpan(text: '.'),
          ],
        );
        if (n.share > 0.009) {
          meta.add(
            _chip(
              'Your share: ${formatMoney(n.share)}',
              bg: AppColors.dangerTint,
              fg: negC,
            ),
          );
        }
        meta.add(_meta(Icons.schedule_rounded, _timeAgo(n.time)));
        if (n.bill != null) {
          link = InkWell(
            onTap: () => _openBreakdown(n),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Review Split Breakdown',
                    style: AppText.labelMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          );
        }
        break;

      case NotifKind.groupReminder:
        icon = Icons.campaign_outlined;
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryTint;
        title = 'Group Settlement Call';
        final owe = n.amount > 0.009;
        final settleDay = '${dayPad(n.time)} ${monthAbbr(n.time)}';
        if (n.urgent) {
          chip = _chip('Due Today', bg: AppColors.dangerTint, fg: negC);
        }
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'Settle-up day for '),
            _group(n.groupName ?? 'your group'),
            TextSpan(text: ' was $settleDay. '),
            if (owe) ...[
              const TextSpan(text: 'You owe '),
              _money(formatMoney(n.amount), negC),
            ] else ...[
              const TextSpan(text: 'You are owed '),
              _money(formatMoney(n.share), posC),
            ],
            const TextSpan(text: ' in this group.'),
          ],
        );
        meta.add(_meta(Icons.schedule_rounded, _timeAgo(n.time)));
        if (owe && n.group != null) {
          trailingMeta = InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: () => _openGroup(n.group!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Pay ${formatMoney(n.amount)}',
                    style: AppText.labelMd
                        .copyWith(color: Colors.white, fontSize: 14)
                        .tabular,
                  ),
                ],
              ),
            ),
          );
        }
        break;

      case NotifKind.simplified:
        icon = Icons.auto_fix_high_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.successTint;
        title = 'Auto-Netting Complete';
        chip = _chip('Simplified', bg: AppColors.successTint, fg: posC);
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'Debts in '),
            _group(n.groupName ?? 'your group'),
            const TextSpan(
              text: ' are auto-simplified into the fewest possible payments.',
            ),
          ],
        );
        meta.add(_meta(Icons.history_rounded, _timeAgo(n.time)));
        break;

      case NotifKind.security:
        icon = Icons.shield_outlined;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceRaised;
        title = 'Security & Device Protected';
        chip = Icon(
          Icons.verified_outlined,
          size: 18,
          color: AppColors.success,
        );
        text = TextSpan(
          style: body,
          text:
              'SplitPay never asks for your UPI PIN or banking passwords. '
              'UPI payments open in your own UPI app.',
        );
        break;
    }

    final tappable =
        n.kind == NotifKind.paymentRequest ||
        n.kind == NotifKind.expenseAdded ||
        n.kind == NotifKind.groupReminder ||
        n.kind == NotifKind.simplified;

    final radius = BorderRadius.circular(AppRadius.card);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: tappable ? () => _onCardTap(n) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.control,
                                ),
                              ),
                              child: Icon(icon, color: iconColor, size: 26),
                            ),
                            if (showAvatar && n.friend != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: LocalAvatar(
                                    localKey: n.friend!.id,
                                    isProfile: false,
                                    fallbackUrl: n.friend!.avatarUrl,
                                    radius: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: AppText.headlineSm.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (chip != null) ...[
                                  const SizedBox(width: 8),
                                  chip,
                                ],
                                if (unread) ...[
                                  const Spacer(),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text.rich(text),
                            if (meta.isNotEmpty || trailingMeta != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: meta,
                                    ),
                                  ),
                                  if (trailingMeta != null) ...[
                                    const SizedBox(width: 8),
                                    trailingMeta,
                                  ],
                                ],
                              ),
                            ],
                            if (link != null) ...[
                              const SizedBox(height: 10),
                              link,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (actions != null) ...[const SizedBox(height: 14), actions],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.labelMd.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
