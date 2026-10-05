import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/screens/friend_details_screen.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';
import 'package:splitpay/screens/bill_detail_screen.dart';
import 'package:splitpay/screens/settings_screen.dart';
import 'package:splitpay/screens/add_bill_screen.dart';
import 'package:splitpay/screens/groups_screen.dart';
import 'package:splitpay/screens/main_shell.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/bill_category.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/core/notification_prefs.dart';
import 'package:splitpay/screens/home/widgets/home_header.dart';
import 'package:splitpay/screens/home/widgets/balance_card.dart';
import 'package:splitpay/screens/home/widgets/quick_split.dart';
import 'package:splitpay/screens/home/widgets/activity_tile.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/widgets/local_avatar.dart';

enum _ActivityFilter { all, pending, groups }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hidden = false;
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) NotificationPrefs.load(uid);
  }

  /// Friends behind the most recent bills (newest first), not the whole
  /// friend list. Own bills contribute their friendIds; shared bills
  /// (someone else's bill you're on) contribute the creator, found via
  /// the reciprocal linked-friend entry in your own friends collection.
  List<Friend> _recentBillFriends(
    List<_ActivityItem> allActivity,
    Map<String, Friend> friendById,
    Map<String, Friend> friendByLinkedUid, {
    int limit = 8,
  }) {
    final result = <Friend>[];
    final seen = <String>{};

    for (final item in allActivity) {
      final bill = item.bill;
      if (item.isOwn) {
        for (final fid in bill.friendIds) {
          final f = friendById[fid];
          if (f != null && seen.add(f.id)) result.add(f);
          if (result.length == limit) return result;
        }
      } else {
        final f = friendByLinkedUid[bill.ownerId];
        if (f != null && seen.add(f.id)) result.add(f);
        if (result.length == limit) return result;
      }
    }
    return result;
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  String _caption(String prefix, int friends, int groups, double amount) {
    if (amount < 0.009) return 'Nothing pending';
    final parts = <String>[];
    if (friends > 0)
      parts.add('$friends ${friends == 1 ? 'friend' : 'friends'}');
    if (groups > 0) parts.add('$groups ${groups == 1 ? 'group' : 'groups'}');
    if (parts.isEmpty) return '$prefix your bills';
    return '$prefix ${parts.join(', ')}';
  }

  /// Signed amount from my side. Group + shared bills use the uid maps,
  /// own 1:1 bills use the legacy friend fields.
  double _signedAmount(Bill b, String myUid, {required bool useUidMaps}) {
    if (useUidMaps && b.sharesByUid.isNotEmpty) {
      final payer = b.paidByUid ?? b.ownerId;
      if (payer == myUid) {
        double t = 0;
        b.sharesByUid.forEach((uid, s) {
          if (uid != myUid) t += s;
        });
        return t;
      }
      return -(b.sharesByUid[myUid] ?? 0);
    }
    if (b.paidBy == 'me') {
      double t = 0;
      for (final fid in b.friendIds) {
        t += b.shareForFriend(fid);
      }
      return t;
    }
    return -b.myShare;
  }

  String _shortDate(DateTime d) {
    final base = '${dayPad(d)} ${monthAbbr(d)}';
    return d.year == DateTime.now().year ? base : '$base ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Sign-out just fired — main.dart's StreamBuilder is about to swap
      // this whole screen out. Bail before touching a null uid.
      return const Scaffold(body: SizedBox.shrink());
    }
    final myUid = user.uid;
    final userName = user.displayName ?? 'there';
    final dark = AppColors.palette.isDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: AppFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AddBillScreen(onBillSaved: () => Navigator.of(context).pop()),
            ),
          );
        },
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: SafeArea(
          child: Column(
            children: [
              HomeTopBar(myUid: myUid, onProfileTap: _openProfile),
              Expanded(
                child: StreamBuilder<List<Friend>>(
                  stream: FriendService.streamFriends(),
                  builder: (context, friendSnapshot) {
                    final friends = friendSnapshot.data ?? [];
                    final friendsLoading =
                        friendSnapshot.connectionState ==
                        ConnectionState.waiting;

                    final friendNameById = {
                      for (final f in friends) f.id: f.name,
                    };
                    final nameByLinkedUid = {
                      for (final f in friends)
                        if (f.isLinked) f.linkedUid!: f.name,
                    };
                    final friendById = {for (final f in friends) f.id: f};
                    final friendByLinkedUid = {
                      for (final f in friends)
                        if (f.isLinked) f.linkedUid!: f,
                    };

                    return StreamBuilder<List<Bill>>(
                      stream: BillService.streamBills(),
                      builder: (context, ownSnapshot) {
                        final ownBills = ownSnapshot.data ?? [];
                        final ownLoading =
                            ownSnapshot.connectionState ==
                            ConnectionState.waiting;

                        return StreamBuilder<List<Bill>>(
                          stream: BillService.streamSharedBills(),
                          builder: (context, sharedSnapshot) {
                            final sharedBills = sharedSnapshot.data ?? [];
                            final sharedLoading =
                                sharedSnapshot.connectionState ==
                                ConnectionState.waiting;

                            return StreamBuilder<List<Group>>(
                              stream: GroupService.streamSharedGroups(),
                              builder: (context, sharedGroupSnapshot) {
                                final List<Group> sharedGroupsForNames =
                                    sharedGroupSnapshot.data ?? <Group>[];
                                final Map<String, String> groupNameById = {
                                  for (final g in sharedGroupsForNames)
                                    g.id: g.name,
                                };

                                final billsLoading =
                                    ownLoading || sharedLoading;

                                double youOwe = 0;
                                double youGet = 0;
                                // One net number per group (same sum group_
                                // details_screen computes) — added once, not
                                // per bill, so offsetting bills within a
                                // group don't leak partial amounts onto both
                                // Pay and Get.
                                final groupNet = <String, double>{};
                                // Per-friend 1:1 net for Quick Split. Same
                                // math friend_details_screen uses.
                                final friendBalance = <String, double>{};

                                for (final bill in ownBills) {
                                  if (bill.groupId != null) {
                                    groupNet[bill.groupId!] =
                                        (groupNet[bill.groupId!] ?? 0) +
                                        bill.balanceForUid(myUid);
                                    continue;
                                  }
                                  if (bill.paidBy == 'me') {
                                    for (final fid in bill.friendIds) {
                                      final f = friendById[fid];
                                      final remaining =
                                          (f != null && f.isLinked)
                                          ? bill.remainingForUid(f.linkedUid!)
                                          : bill.remainingForFriend(fid);
                                      youGet += remaining;
                                      friendBalance[fid] =
                                          (friendBalance[fid] ?? 0) + remaining;
                                    }
                                  } else {
                                    youOwe += bill.remainingMyShare;
                                    friendBalance[bill.paidBy] =
                                        (friendBalance[bill.paidBy] ?? 0) -
                                        bill.remainingMyShare;
                                  }
                                }

                                for (final bill in sharedBills) {
                                  if (bill.groupId != null) {
                                    groupNet[bill.groupId!] =
                                        (groupNet[bill.groupId!] ?? 0) +
                                        bill.balanceForUid(myUid);
                                    continue;
                                  }
                                  final balance = bill.balanceForUid(myUid);
                                  if (balance > 0) {
                                    youGet += balance;
                                  } else if (balance < 0) {
                                    youOwe += balance.abs();
                                  }
                                  final creator =
                                      friendByLinkedUid[bill.ownerId];
                                  if (creator != null) {
                                    friendBalance[creator.id] =
                                        (friendBalance[creator.id] ?? 0) +
                                        balance;
                                  }
                                }

                                for (final net in groupNet.values) {
                                  if (net > 0) {
                                    youGet += net;
                                  } else if (net < 0) {
                                    youOwe += net.abs();
                                  }
                                }

                                final oweFriends = friendBalance.values
                                    .where((v) => v < -0.009)
                                    .length;
                                final getFriends = friendBalance.values
                                    .where((v) => v > 0.009)
                                    .length;
                                final oweGroups = groupNet.values
                                    .where((v) => v < -0.009)
                                    .length;
                                final getGroups = groupNet.values
                                    .where((v) => v > 0.009)
                                    .length;

                                final allActivity =
                                    [
                                      ...ownBills.map(
                                        (b) =>
                                            _ActivityItem(bill: b, isOwn: true),
                                      ),
                                      ...sharedBills.map(
                                        (b) => _ActivityItem(
                                          bill: b,
                                          isOwn: false,
                                        ),
                                      ),
                                    ]..sort(
                                      (a, b) =>
                                          b.bill.date.compareTo(a.bill.date),
                                    );

                                final recentBillFriends = _recentBillFriends(
                                  allActivity,
                                  friendById,
                                  friendByLinkedUid,
                                );
                                final quickFriends = [
                                  for (final f in recentBillFriends)
                                    QuickFriend(f, friendBalance[f.id] ?? 0),
                                ];
                                final recentFriendsLoading =
                                    friendsLoading || billsLoading;

                                return RefreshIndicator(
                                  color: AppColors.primary,
                                  onRefresh: () async {
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                  },
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      120,
                                    ),
                                    children: [
                                      HomeGreeting(
                                        userName: userName,
                                        myUid: myUid,
                                        hidden: _hidden,
                                        onToggleHidden: () =>
                                            setState(() => _hidden = !_hidden),
                                        onProfileTap: _openProfile,
                                      ),
                                      const SizedBox(height: 20),
                                      HomeBalanceCard(
                                        youOwe: youOwe,
                                        youGet: youGet,
                                        oweCaption: _caption(
                                          'Across',
                                          oweFriends,
                                          oweGroups,
                                          youOwe,
                                        ),
                                        getCaption: _caption(
                                          'From',
                                          getFriends,
                                          getGroups,
                                          youGet,
                                        ),
                                        hidden: _hidden,
                                        onSettleUp: () => _showSettleUpSheet(
                                          quickFriends: [
                                            for (final f in friends)
                                              QuickFriend(
                                                f,
                                                friendBalance[f.id] ?? 0,
                                              ),
                                          ],
                                          hasGroupBalance: groupNet.values.any(
                                            (v) => v.abs() > 0.009,
                                          ),
                                        ),
                                        onAnalytics: () => _showAnalyticsSheet(
                                          allActivity: allActivity,
                                          youOwe: youOwe,
                                          youGet: youGet,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      QuickSplitStrip(
                                        friends: quickFriends,
                                        loading: recentFriendsLoading,
                                        hidden: _hidden,
                                        onAdd: () => mainTabNotifier.value = 1,
                                        onViewAll: () =>
                                            mainTabNotifier.value = 1,
                                        onFriendTap: (f) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FriendDetailsScreen(
                                                    friend: f,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 28),
                                      _buildRecentActivityHeader(),
                                      const SizedBox(height: 14),
                                      ..._activityBody(
                                        billsLoading: billsLoading,
                                        allActivity: allActivity,
                                        friendNameById: friendNameById,
                                        nameByLinkedUid: nameByLinkedUid,
                                        friendById: friendById,
                                        myUid: myUid,
                                        groupNameById: groupNameById,
                                      ),
                                      const SizedBox(height: 24),
                                      _newGroupPromo(),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Sheets ----------

  void _showSettleUpSheet({
    required List<QuickFriend> quickFriends,
    required bool hasGroupBalance,
  }) {
    final open = quickFriends.where((q) => q.balance.abs() > 0.009).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance)); // you owe first

    if (open.isEmpty) {
      if (hasGroupBalance) {
        showAppToast(context, 'Settle group balances from the Groups tab');
        mainTabNotifier.value = 2;
      } else {
        showAppToast(context, 'All settled up');
      }
      return;
    }

    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Settle up with',
            style: AppText.headlineSm.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a friend to pay or collect.',
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: open.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final q = open[i];
                final owe = q.balance < 0;
                final color = owe ? negativeText() : positiveText();
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FriendDetailsScreen(friend: q.friend),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      children: [
                        LocalAvatar(
                          localKey: q.friend.id,
                          isProfile: false,
                          fallbackUrl: q.friend.avatarUrl,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.friend.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.labelLg.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                owe ? 'You owe' : 'Owes you',
                                style: AppText.bodySm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(q.balance),
                          style: AppText.headlineSm
                              .copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              )
                              .tabular,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAnalyticsSheet({
    required List<_ActivityItem> allActivity,
    required double youOwe,
    required double youGet,
  }) {
    final now = DateTime.now();
    final thisMonth = allActivity
        .where(
          (a) => a.bill.date.year == now.year && a.bill.date.month == now.month,
        )
        .toList();
    final settledCount = allActivity
        .where((a) => a.bill.isFullySettled || a.bill.settledUids.isNotEmpty)
        .length;
    final total = youOwe + youGet;
    final oweFlex = total <= 0
        ? 1
        : (youOwe / total * 100).round().clamp(0, 100);
    final getFlex = total <= 0 ? 1 : 100 - oweFlex;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppText.labelLg
                .copyWith(color: AppColors.textPrimary)
                .tabular,
          ),
        ],
      ),
    );

    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Analytics',
            style: AppText.headlineSm.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            monthYear(now),
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: oweFlex == 0 ? 1 : oweFlex,
                    child: Container(
                      color: negativeText().withValues(alpha: 0.75),
                    ),
                  ),
                  Expanded(
                    flex: getFlex == 0 ? 1 : getFlex,
                    child: Container(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          row('You owe', formatMoney(youOwe)),
          row('You get back', formatMoney(youGet)),
          row(
            'Net',
            '${youGet - youOwe < 0 ? '-' : ''}${formatMoney(youGet - youOwe)}',
          ),
          Divider(color: AppColors.divider),
          row('Bills this month', '${thisMonth.length}'),
          row('Bills in total', '${allActivity.length}'),
          row('Bills with settled activity', '$settledCount'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------- Recent Activity ----------

  Widget _buildRecentActivityHeader() {
    Widget chip(String label, _ActivityFilter f) {
      final selected = _filter == f;
      return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected ? AppShadows.card : const [],
          ),
          child: Text(
            label,
            style: AppText.labelMd.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'recent_activity'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.headlineSm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              chip('All', _ActivityFilter.all),
              chip('pending'.tr(), _ActivityFilter.pending),
              chip('Groups', _ActivityFilter.groups),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSettled(
    _ActivityItem item,
    Map<String, Friend> friendById,
    String myUid,
  ) {
    final bill = item.bill;
    if (item.isOwn) {
      return bill.friendIds.isNotEmpty &&
          bill.friendIds.every((fid) {
            final f = friendById[fid];
            return (f != null && f.isLinked)
                ? bill.settledUids.contains(f.linkedUid)
                : bill.isSettledFor(fid);
          });
    }
    return bill.settledUids.contains(myUid);
  }

  List<Widget> _activityBody({
    required bool billsLoading,
    required List<_ActivityItem> allActivity,
    required Map<String, String> friendNameById,
    required Map<String, String> nameByLinkedUid,
    required Map<String, Friend> friendById,
    required String myUid,
    required Map<String, String> groupNameById,
  }) {
    if (billsLoading) return [_billsSkeleton()];
    if (allActivity.isEmpty) return [_buildEmptyBills()];

    final filtered = allActivity.where((item) {
      switch (_filter) {
        case _ActivityFilter.all:
          return true;
        case _ActivityFilter.pending:
          return !_isSettled(item, friendById, myUid);
        case _ActivityFilter.groups:
          return item.bill.groupId != null;
      }
    }).toList();

    if (filtered.isEmpty) return [_buildEmptyFilter()];

    return _buildBillCards(
      filtered,
      friendNameById,
      nameByLinkedUid,
      friendById,
      myUid,
      groupNameById,
    );
  }

  List<Widget> _buildBillCards(
    List<_ActivityItem> items,
    Map<String, String> friendNameById,
    Map<String, String> nameByLinkedUid,
    Map<String, Friend> friendById,
    String myUid,
    Map<String, String> groupNameById,
  ) {
    return items.map((item) {
      final bill = item.bill;

      String subtitle;
      final bool isSettled = _isSettled(item, friendById, myUid);
      final date = _shortDate(bill.date);

      if (item.isOwn) {
        final names = bill.friendIds
            .map((id) => friendNameById[id] ?? 'unknown'.tr())
            .join(', ');
        subtitle = names.isEmpty
            ? '${'no_friends'.tr()} \u2022 $date'
            : 'with $names \u2022 $date';
      } else {
        final creatorName = nameByLinkedUid[bill.ownerId] ?? 'someone'.tr();
        final groupName = bill.groupId != null
            ? groupNameById[bill.groupId]
            : null;
        subtitle = groupName != null
            ? 'Shared by $creatorName \u00b7 $groupName \u2022 $date'
            : 'Shared by $creatorName \u2022 $date';
      }

      final signed = _signedAmount(
        bill,
        myUid,
        useUidMaps: !item.isOwn || bill.groupId != null,
      );
      final visual = billVisual(bill.title);

      final tile = ActivityTile(
        title: bill.title,
        subtitle: subtitle,
        amount: signed,
        settled: isSettled,
        visual: visual,
        hidden: _hidden,
        settledLabel: 'settled'.tr(),
        pendingLabel: 'pending'.tr(),
        onTap: () {
          // BillDetailScreen is uid-based: fine for group + shared bills.
          // Own 1:1 bills open the friend's page instead.
          if (bill.groupId != null || !item.isOwn) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BillDetailScreen(
                  bill: bill,
                  icon: visual.icon,
                  iconBg: visual.bg,
                  iconColor: visual.color,
                ),
              ),
            );
          } else {
            final f = bill.friendIds.isEmpty
                ? null
                : friendById[bill.friendIds.first];
            if (f != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FriendDetailsScreen(friend: f),
                ),
              );
            }
          }
        },
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: item.isOwn
            ? Dismissible(
                key: ValueKey(bill.id),
                background: _swipeBackground(
                  alignment: Alignment.centerLeft,
                  color: AppColors.error,
                  icon: Icons.delete_rounded,
                ),
                secondaryBackground: _swipeBackground(
                  alignment: Alignment.centerRight,
                  color: AppColors.primary,
                  icon: Icons.edit_rounded,
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await BillService.deleteBill(bill.id);
                    return true;
                  } else {
                    if (bill.settledFriendIds.isNotEmpty ||
                        bill.settledUids.isNotEmpty ||
                        bill.partialPaymentsByFriend.isNotEmpty ||
                        bill.partialPaymentsByUid.isNotEmpty ||
                        bill.myPartialPayment > 0) {
                      showAppToast(
                        context,
                        'This bill has settled activity and can no longer be edited',
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditBillScreen(bill: bill),
                        ),
                      );
                    }
                    return false;
                  }
                },
                child: tile,
              )
            : tile,
      );
    }).toList();
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _newGroupPromo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_alt_1_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planning a trip or weekend outing?',
                  style: AppText.labelLg.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Split hotel, cabs, or dinner easily with a group pool.',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => GroupsScreen.showCreateGroupSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '+ New Group',
                style: AppText.labelMd.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          _filter == _ActivityFilter.pending
              ? 'No pending bills'
              : 'No group bills yet',
          style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEmptyBills() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'no_bills_yet'.tr(),
            style: AppText.labelLg.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'add_first_bill_hint'.tr(),
            style: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _billsSkeleton() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final Bill bill;
  final bool isOwn;

  _ActivityItem({required this.bill, required this.isOwn});
}
