import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';

enum NotifKind {
  paymentRequest,
  paymentReceived,
  paymentSent,
  expenseAdded,
  groupReminder,
  simplified,
  security,
}

/// One row in the notification feed. Built client-side from data the app
/// already streams, then kept in a local file by `NotificationStore`.
/// "Unread" = newer than [notificationLastSeenNotifier].
class AppNotification {
  final String id;
  final NotifKind kind;
  final DateTime time;

  /// Other person's name (requester, payer, creator ...).
  final String? actor;
  final String? billTitle;
  final String? groupName;

  /// Main amount (requested, received, sent, owed ...).
  final double amount;

  /// Total bill amount (expenseAdded).
  final double billAmount;

  /// My share of the bill (expenseAdded).
  final double share;
  final String? ref;
  final String? note;
  final bool urgent;

  /// Live objects. Only set on freshly built items, never saved to file.
  final Bill? bill;
  final Friend? friend;
  final Group? group;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.time,
    this.actor,
    this.billTitle,
    this.groupName,
    this.amount = 0,
    this.billAmount = 0,
    this.share = 0,
    this.ref,
    this.note,
    this.urgent = false,
    this.bill,
    this.friend,
    this.group,
  });

  bool get isPendingAction =>
      kind == NotifKind.paymentRequest ||
      (kind == NotifKind.groupReminder && amount > 0.009);

  /// Copy safe to save: no live bill / friend / group objects.
  AppNotification withoutLive() => AppNotification(
    id: id,
    kind: kind,
    time: time,
    actor: actor,
    billTitle: billTitle,
    groupName: groupName,
    amount: amount,
    billAmount: billAmount,
    share: share,
    ref: ref,
    note: note,
    urgent: urgent,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'k': kind.name,
    't': time.millisecondsSinceEpoch,
    if (actor != null) 'ac': actor,
    if (billTitle != null) 'bt': billTitle,
    if (groupName != null) 'gn': groupName,
    if (amount != 0) 'a': amount,
    if (billAmount != 0) 'ba': billAmount,
    if (share != 0) 's': share,
    if (ref != null) 'r': ref,
    if (note != null) 'n': note,
    if (urgent) 'u': true,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    kind: NotifKind.values.firstWhere(
      (k) => k.name == j['k'],
      orElse: () => NotifKind.expenseAdded,
    ),
    time: DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()),
    actor: j['ac'] as String?,
    billTitle: j['bt'] as String?,
    groupName: j['gn'] as String?,
    amount: (j['a'] as num?)?.toDouble() ?? 0,
    billAmount: (j['ba'] as num?)?.toDouble() ?? 0,
    share: (j['s'] as num?)?.toDouble() ?? 0,
    ref: j['r'] as String?,
    note: j['n'] as String?,
    urgent: j['u'] == true,
  );
}
