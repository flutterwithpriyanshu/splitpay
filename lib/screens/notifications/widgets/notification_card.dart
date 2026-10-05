import 'package:flutter/material.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/core/notification_feed.dart';
import 'package:splitpay/core/time_ago.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/screens/home/widgets/quick_split.dart'
    show positiveText, negativeText;
import 'package:splitpay/screens/notifications/widgets/notification_chip.dart';
import 'package:splitpay/screens/notifications/widgets/notification_meta.dart';
import 'package:splitpay/screens/notifications/widgets/notification_secondary_button.dart';
import 'package:splitpay/screens/notifications/widgets/notification_text_spans.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// One notification card. Pure UI: taps go out through callbacks.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.n,
    required this.unread,
    required this.onTap,
    required this.onSettle,
    required this.onBreakdown,
    required this.onOpenGroup,
  });

  final AppNotification n;
  final bool unread;
  final VoidCallback? onTap;
  final VoidCallback onSettle;
  final VoidCallback onBreakdown;
  final void Function(Group) onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final posC = positiveText();
    final negC = negativeText();
    final body = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textSecondary,
      fontFamily: AppText.bodyLg.fontFamily,
    );

    IconData icon;
    Color iconColor;
    Color iconBg;
    String title;
    Widget? chip;
    var chipBelow = false;
    InlineSpan text;
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
          chip = NotificationChip('Urgent', bg: AppColors.dangerTint, fg: negC);
        }
        text = TextSpan(
          style: body,
          children: [
            nameSpan(n.actor ?? 'Someone'),
            const TextSpan(text: ' requested '),
            moneySpan(formatMoney(n.amount), negC),
            if ((n.billTitle ?? '').isNotEmpty) ...[
              const TextSpan(text: ' for '),
              quotedSpan(n.billTitle!),
            ],
            if (n.groupName != null) ...[
              const TextSpan(text: ' in '),
              groupSpan(n.groupName!),
            ],
            const TextSpan(text: '.'),
          ],
        );
        meta.add(NotificationMeta(Icons.schedule_rounded, timeAgo(n.time)));
        if (n.urgent) {
          meta.add(
            NotificationMeta(Icons.event_rounded, 'Due Today', color: negC),
          );
        }
        actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientButton(
              label: 'Settle via UPI (${formatMoney(n.amount)})',
              icon: Icons.bolt_rounded,
              onPressed: onSettle,
            ),
            if (n.bill != null) ...[
              const SizedBox(height: 10),
              NotificationSecondaryButton(
                label: 'View Split Breakdown',
                icon: Icons.receipt_long_outlined,
                onTap: onBreakdown,
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
        chipBelow = true;
        chip = NotificationChip(
          'Paid & Reconciled',
          bg: AppColors.successTint,
          fg: posC,
          icon: Icons.done_all_rounded,
        );
        text = TextSpan(
          style: body,
          children: [
            nameSpan(n.actor ?? 'Someone'),
            const TextSpan(text: ' paid you '),
            moneySpan('+${formatMoney(n.amount)}', posC),
            if (n.note != null) TextSpan(text: ' \u2014 ${n.note}'),
            const TextSpan(text: '.'),
          ],
        );
        meta.add(NotificationMeta(Icons.schedule_rounded, timeAgo(n.time)));
        break;

      case NotifKind.paymentSent:
        icon = Icons.north_east_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primaryTint;
        title = 'Payment Sent';
        chipBelow = true;
        chip = NotificationChip(
          'Paid',
          bg: AppColors.primaryTint,
          fg: AppColors.primary,
          icon: Icons.check_rounded,
        );
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'You paid '),
            nameSpan(n.actor ?? 'Someone'),
            const TextSpan(text: ' '),
            moneySpan(formatMoney(n.amount), AppColors.textPrimary),
            if (n.note != null) TextSpan(text: ' \u2014 ${n.note}'),
            const TextSpan(text: '.'),
          ],
        );
        meta.add(NotificationMeta(Icons.schedule_rounded, timeAgo(n.time)));
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
            nameSpan(n.actor ?? 'Someone'),
            const TextSpan(text: ' added '),
            quotedSpan(n.billTitle ?? ''),
            TextSpan(text: ' (${formatMoney(n.billAmount)}) '),
            if (n.groupName != null) ...[
              const TextSpan(text: 'to '),
              groupSpan(n.groupName!),
            ] else
              const TextSpan(text: 'with you'),
            const TextSpan(text: '.'),
          ],
        );
        if (n.share > 0.009) {
          meta.add(
            NotificationChip(
              'Your share: ${formatMoney(n.share)}',
              bg: AppColors.dangerTint,
              fg: negC,
            ),
          );
        }
        meta.add(NotificationMeta(Icons.schedule_rounded, timeAgo(n.time)));
        if (n.bill != null) {
          link = InkWell(
            onTap: onBreakdown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Review Split Breakdown',
                    style: AppText.labelMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
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
          chip = NotificationChip(
            'Due Today',
            bg: AppColors.dangerTint,
            fg: negC,
          );
        }
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'Settle-up day for '),
            groupSpan(n.groupName ?? 'your group'),
            TextSpan(text: ' was $settleDay. '),
            if (owe) ...[
              const TextSpan(text: 'You owe '),
              moneySpan(formatMoney(n.amount), negC),
            ] else ...[
              const TextSpan(text: 'You are owed '),
              moneySpan(formatMoney(n.share), posC),
            ],
            const TextSpan(text: ' in this group.'),
          ],
        );
        meta.add(NotificationMeta(Icons.schedule_rounded, timeAgo(n.time)));
        final g = n.group;
        if (owe && g != null) {
          trailingMeta = InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: () => onOpenGroup(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Pay ${formatMoney(n.amount)}',
                    style: AppText.labelMd
                        .copyWith(color: Colors.white, fontSize: 13)
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
        chip = NotificationChip(
          'Simplified',
          bg: AppColors.successTint,
          fg: posC,
        );
        text = TextSpan(
          style: body,
          children: [
            const TextSpan(text: 'Debts in '),
            groupSpan(n.groupName ?? 'your group'),
            const TextSpan(
              text: ' are auto-simplified into the fewest possible payments.',
            ),
          ],
        );
        meta.add(NotificationMeta(Icons.history_rounded, timeAgo(n.time)));
        break;

      case NotifKind.security:
        icon = Icons.shield_outlined;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceRaised;
        title = 'Security & Device Protected';
        chip = Icon(
          Icons.verified_outlined,
          size: 17,
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

    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _leading(icon, iconBg, iconColor, showAvatar),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (chip != null && !chipBelow) ...[
                                const SizedBox(width: 8),
                                chip,
                              ],
                              if (unread) ...[
                                const Spacer(),
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (chip != null && chipBelow) ...[
                            const SizedBox(height: 6),
                            Align(alignment: Alignment.centerLeft, child: chip),
                          ],
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
    );
  }

  Widget _leading(IconData icon, Color bg, Color fg, bool showAvatar) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: fg, size: 24),
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
    );
  }
}
