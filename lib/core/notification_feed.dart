import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/core/app_notification.dart';
import 'package:splitpay/core/notification_store.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/model/transaction.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/services/transaction_service.dart';

export 'package:splitpay/core/app_notification.dart';

/// Last time a group's settle-up day (10:00) happened, this month or last.
DateTime _lastSettleOccurrence(int day, DateTime now) {
  DateTime cand(int y, int m) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day > last ? last : day, 10);
  }

  var c = cand(now.year, now.month);
  if (c.isAfter(now)) {
    final pm = now.month == 1 ? 12 : now.month - 1;
    final py = now.month == 1 ? now.year - 1 : now.year;
    c = cand(py, pm);
  }
  return c;
}

List<AppNotification> buildNotifications({
  required String myUid,
  required List<Bill> ownBills,
  required List<Bill> sharedBills,
  required List<WalletTransaction> transactions,
  required List<Friend> friends,
  required List<Group> ownGroups,
  required List<Group> sharedGroups,
  required DateTime now,
}) {
  final out = <AppNotification>[];
  final byLinked = <String, Friend>{
    for (final f in friends)
      if (f.isLinked) f.linkedUid!: f,
  };
  final byId = <String, Friend>{for (final f in friends) f.id: f};
  final groups = <String, Group>{
    for (final g in [...ownGroups, ...sharedGroups]) g.id: g,
  };
  final todayStart = DateTime(now.year, now.month, now.day);

  // Net per group, same sum the home totals use.
  final groupNet = <String, double>{};
  final groupLatest = <String, DateTime>{};
  final groupBillCount = <String, int>{};
  for (final b in [...ownBills, ...sharedBills]) {
    final gid = b.groupId;
    if (gid == null) continue;
    groupNet[gid] = (groupNet[gid] ?? 0) + b.balanceForUid(myUid);
    final t = b.createdAt ?? b.date;
    final prev = groupLatest[gid];
    if (prev == null || t.isAfter(prev)) groupLatest[gid] = t;
    groupBillCount[gid] = (groupBillCount[gid] ?? 0) + 1;
  }

  bool settleDayIsToday(Group? g) =>
      g != null && g.settleUpDay != null && g.settleUpDay == now.day;

  // ---- Bills someone else created that include me ----
  for (final b in sharedBills) {
    final payerUid = b.paidByUid ?? b.ownerId;
    final creator = byLinked[b.ownerId];
    final payer = byLinked[payerUid];
    final group = b.groupId != null ? groups[b.groupId] : null;
    final t = b.createdAt ?? b.date;

    out.add(
      AppNotification(
        id: 'exp_${b.id}',
        kind: NotifKind.expenseAdded,
        time: t,
        actor: creator?.name ?? 'Someone',
        billTitle: b.title,
        groupName: group?.name,
        billAmount: b.amount,
        share: b.sharesByUid[myUid] ?? 0,
        bill: b,
        friend: creator,
        group: group,
      ),
    );

    final remaining = b.remainingForUid(myUid);
    final iOwe =
        payerUid != myUid &&
        remaining > 0.009 &&
        !b.settledUids.contains(myUid);
    if (iOwe) {
      out.add(
        AppNotification(
          id: 'req_${b.id}',
          kind: NotifKind.paymentRequest,
          // +1s so the request sits above its expense row.
          time: t.add(const Duration(seconds: 1)),
          actor: payer?.name ?? creator?.name ?? 'Someone',
          billTitle: b.title,
          groupName: group?.name,
          amount: remaining,
          urgent: settleDayIsToday(group),
          bill: b,
          friend: payer ?? creator,
          group: group,
        ),
      );
    }
  }

  // ---- My own 1:1 bills a friend paid, I still owe ----
  for (final b in ownBills) {
    if (b.groupId != null || b.paidBy == 'me') continue;
    final remaining = b.remainingMyShare;
    if (remaining <= 0.009) continue;
    final f = byId[b.paidBy];
    out.add(
      AppNotification(
        id: 'req_${b.id}',
        kind: NotifKind.paymentRequest,
        time: b.createdAt ?? b.date,
        actor: f?.name ?? 'Someone',
        billTitle: b.title,
        amount: remaining,
        bill: b,
        friend: f,
      ),
    );
  }

  // ---- Wallet transactions ----
  for (final tx in transactions) {
    if (!tx.isCompleted) continue;
    final received = tx.type == TransactionType.received;
    out.add(
      AppNotification(
        id: 'tx_${tx.id}',
        kind: received ? NotifKind.paymentReceived : NotifKind.paymentSent,
        time: tx.date,
        actor: tx.personName.isEmpty ? 'Someone' : tx.personName,
        amount: tx.amount,
        note: (tx.note ?? '').trim().isEmpty ? null : tx.note!.trim(),
        ref: tx.id.length >= 6
            ? '#TXN-${tx.id.substring(0, 6).toUpperCase()}'
            : null,
      ),
    );
  }

  // ---- Group settle-up day reminders + auto-netting ----
  for (final g in groups.values) {
    final net = groupNet[g.id] ?? 0;
    final day = g.settleUpDay;
    if (day != null && net.abs() > 0.01) {
      final when = _lastSettleOccurrence(day, now);
      if (now.difference(when).inDays <= 31) {
        out.add(
          AppNotification(
            id: 'grp_${g.id}',
            kind: NotifKind.groupReminder,
            time: when,
            groupName: g.name,
            amount: net < 0 ? -net : 0,
            share: net > 0 ? net : 0,
            urgent: net < 0 && settleDayIsToday(g),
            group: g,
          ),
        );
      }
    }

    final count = groupBillCount[g.id] ?? 0;
    if (g.simplifyDebts && count >= 2 && g.memberFriendIds.length + 1 >= 3) {
      out.add(
        AppNotification(
          id: 'net_${g.id}',
          kind: NotifKind.simplified,
          time: groupLatest[g.id] ?? g.createdAt,
          groupName: g.name,
          group: g,
        ),
      );
    }
  }

  // Newest first. Drop stale non-action rows, cap length.
  final cutoff = todayStart.subtract(const Duration(days: 45));
  out.removeWhere(
    (n) =>
        !n.isPendingAction &&
        n.kind != NotifKind.security &&
        n.time.isBefore(cutoff),
  );
  out.sort((a, b) => b.time.compareTo(a.time));
  final capped = out.length > 60 ? out.sublist(0, 60) : out;

  // Static trust note, always last, never unread.
  return [
    ...capped,
    AppNotification(
      id: 'security',
      kind: NotifKind.security,
      time: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];
}

/// Subscribes to every stream the feed needs once, builds the feed on each
/// update. [loading] is true until the first snapshot of each stream.
class NotificationFeedScope extends StatefulWidget {
  const NotificationFeedScope({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    List<AppNotification> items,
    bool loading,
  )
  builder;

  @override
  State<NotificationFeedScope> createState() => _NotificationFeedScopeState();
}

class _NotificationFeedScopeState extends State<NotificationFeedScope> {
  late final Stream<List<Friend>> _friends = FriendService.streamFriends();
  late final Stream<List<Bill>> _own = BillService.streamBills();
  late final Stream<List<Bill>> _shared = BillService.streamSharedBills();
  late final Stream<List<WalletTransaction>> _tx =
      TransactionService.streamTransactions();
  late final Stream<List<Group>> _ownGroups = GroupService.streamGroups();
  late final Stream<List<Group>> _sharedGroups =
      GroupService.streamSharedGroups();

  @override
  void initState() {
    super.initState();
    NotificationStore.instance.load(
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }

  bool _waiting(AsyncSnapshot<Object?> s) =>
      s.connectionState == ConnectionState.waiting;

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<Friend>>(
      stream: _friends,
      builder: (context, fs) {
        return StreamBuilder<List<Bill>>(
          stream: _own,
          builder: (context, os) {
            return StreamBuilder<List<Bill>>(
              stream: _shared,
              builder: (context, ss) {
                return StreamBuilder<List<WalletTransaction>>(
                  stream: _tx,
                  builder: (context, ts) {
                    return StreamBuilder<List<Group>>(
                      stream: _ownGroups,
                      builder: (context, og) {
                        return StreamBuilder<List<Group>>(
                          stream: _sharedGroups,
                          builder: (context, sg) {
                            final loading =
                                os.connectionState == ConnectionState.waiting ||
                                ss.connectionState == ConnectionState.waiting;
                            final derived = buildNotifications(
                              myUid: myUid,
                              ownBills: os.data ?? const <Bill>[],
                              sharedBills: ss.data ?? const <Bill>[],
                              transactions:
                                  ts.data ?? const <WalletTransaction>[],
                              friends: fs.data ?? const <Friend>[],
                              ownGroups: og.data ?? const <Group>[],
                              sharedGroups: sg.data ?? const <Group>[],
                              now: DateTime.now(),
                            );
                            final ready = ![
                              fs,
                              os,
                              ss,
                              ts,
                              og,
                              sg,
                            ].any(_waiting);
                            final store = NotificationStore.instance;
                            return ListenableBuilder(
                              listenable: store,
                              builder: (context, _) {
                                final shown = store.visible(
                                  derived,
                                  ready: ready,
                                );
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => store.sync(derived, ready: ready),
                                );
                                return widget.builder(
                                  context,
                                  shown,
                                  loading || !store.loaded,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
