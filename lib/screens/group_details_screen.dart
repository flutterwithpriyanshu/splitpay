import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/add_bill_screen.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/widgets/day_of_month_picker.dart';
import 'package:splitpay/core/debt_simplifier.dart';
import 'package:splitpay/screens/group_details/widgets/header_pill.dart';
import 'package:splitpay/screens/group_details/widgets/balance_line.dart';
import 'package:splitpay/screens/group_details/widgets/tabs_row.dart';

const _kMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _kMonthFullNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _monthAbbr(DateTime d) => _kMonthNames[d.month - 1];
String _dayPad(DateTime d) => d.day.toString().padLeft(2, '0');
String _monthYear(DateTime d) => '${_kMonthFullNames[d.month - 1]} ${d.year}';

class GroupDetailsScreen extends StatelessWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  /// Remaining amount owed on this bill, summed across its participants.
  ///
  /// A friend is either tracked via `friendIds`/`remainingForFriend` (local,
  /// non-linked) OR via `participantUids`/`remainingForUid` (linked) — never
  /// both. Looping over both lists unconditionally double-counts every
  /// linked friend's share (and even pulls in your OWN share via
  /// participantUids, which always includes the owner's uid). That's what
  /// was inflating the "due" total for groups.
  double _remainingForBill(Bill bill, Map<String, Friend> friendById) {
    double total = 0;
    for (final id in bill.friendIds) {
      final friend = friendById[id];
      if (friend != null && friend.isLinked) {
        total += bill.remainingForUid(friend.linkedUid!);
      } else {
        total += bill.remainingForFriend(id);
      }
    }
    return total;
  }

  /// Net signed balance for this bill from the current user's point of
  /// view: positive = you are owed, negative = you owe.
  double _netForBill(Bill bill, Map<String, Friend> friendById) {
    if (bill.paidBy == 'me') {
      return _remainingForBill(bill, friendById);
    }
    return -bill.remainingMyShare;
  }

  IconData _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('electric') || t.contains('water') || t.contains('light')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (t.contains('petrol') || t.contains('fuel') || t.contains('gas')) {
      return Icons.local_gas_station_rounded;
    }
    if (t.contains('pizza') ||
        t.contains('dinner') ||
        t.contains('lunch') ||
        t.contains('breakfast') ||
        t.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('rent') || t.contains('flat') || t.contains('home')) {
      return Icons.home_rounded;
    }
    if (t.contains('grocery') || t.contains('zepto') || t.contains('shop')) {
      return Icons.receipt_rounded;
    }
    if (t.contains('travel') ||
        t.contains('cab') ||
        t.contains('taxi') ||
        t.contains('uber')) {
      return Icons.local_taxi_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _iconBgFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('electric') || t.contains('water') || t.contains('light')) {
      return const Color(0xFFDCEEFB);
    }
    if (t.contains('petrol') || t.contains('fuel') || t.contains('gas')) {
      return const Color(0xFFF9D8D8);
    }
    if (t.contains('pizza') ||
        t.contains('dinner') ||
        t.contains('lunch') ||
        t.contains('breakfast') ||
        t.contains('food')) {
      return const Color(0xFFDDF3E4);
    }
    return const Color(0xFFE9E7FB);
  }

  Color _iconColorFor(Color bg) => Colors.black.withOpacity(0.55);

  /// Nets every bill down to one balance per group member, runs the debt
  /// simplifier over it, and shows the resulting "X pays Y ₹Z" list — the
  /// fewest payments needed to settle the whole group up.
  void _showSimplifiedDebts(
    BuildContext context,
    List<Bill> bills,
    List<Friend> members,
  ) {
    final netByUid = <String, double>{};
    final nameByUid = <String, String>{};

    for (final bill in bills) {
      for (final uid in bill.participantUids) {
        netByUid[uid] = (netByUid[uid] ?? 0) + bill.balanceForUid(uid);
      }
    }
    for (final friend in members) {
      if (friend.isLinked) nameByUid[friend.linkedUid!] = friend.name;
    }
    nameByUid[group.ownerId] = nameByUid[group.ownerId] ?? 'Owner';

    final simplified = simplifyDebts(netByUid);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simplified balances',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The fewest payments needed to settle everyone up.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (simplified.isEmpty)
                Text(
                  'Everyone is settled up 🎉',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...simplified.map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${nameByUid[d.fromUid] ?? 'Someone'} pays ${nameByUid[d.toUid] ?? 'someone'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '₹${d.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddBillScreen(
                group: group,
                onBillSaved: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<Friend>>(
        stream: FriendService.streamFriends(),
        builder: (context, friendSnapshot) {
          final friends = friendSnapshot.data ?? [];
          final friendById = {for (final f in friends) f.id: f};
          final members = friends
              .where((f) => group.memberFriendIds.contains(f.id))
              .toList();

          return Column(
            children: [
              _Header(group: group, members: members),
              Expanded(
                child: StreamBuilder<List<Bill>>(
                  stream: BillService.streamGroupBills(group.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bills = (snapshot.data ?? [])
                      ..sort((a, b) => b.date.compareTo(a.date));

                    double net = 0;
                    for (final bill in bills) {
                      net += _netForBill(bill, friendById);
                    }

                    // Keep this device's monthly settle-up reminder in sync
                    // with the group's current settle-up day and my current
                    // balance in this group. Cheap no-op if unchanged.
                    if (group.settleUpDay != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        LocalNotificationService.scheduleMonthlySettleReminder(
                          groupId: group.id,
                          groupName: group.name,
                          day: group.settleUpDay!,
                          myNetBalance: net,
                        );
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GroupBalanceLine(net: net, members: members),
                        ),
                        const SizedBox(height: 14),
                        GroupTabsRow(
                          onSettleUp: () {
                            showAppToast(
                              context,
                              'Open a friend from this group to settle up',
                            );
                          },
                          onBalances: () =>
                              _showSimplifiedDebts(context, bills, members),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: bills.isEmpty
                              ? Center(
                                  child: Text(
                                    'No bills in this group yet. Tap + to add one.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : _BillList(
                                  bills: bills,
                                  friendById: friendById,
                                  iconFor: _iconFor,
                                  iconBgFor: _iconBgFor,
                                  iconColorFor: _iconColorFor,
                                  remainingForBill: _remainingForBill,
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Group group;
  final List<Friend> members;

  const _Header({required this.group, required this.members});

  Future<void> _editSettleUpDate(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          DayOfMonthPicker(initialDay: group.settleUpDay, allowClear: true),
    );
    if (picked == null || !context.mounted) return;

    if (picked == -1) {
      await GroupService.updateSettleUpDay(group.id, null);
      await LocalNotificationService.cancelSettleReminder(group.id);
      if (context.mounted) {
        showAppToast(context, 'Settle up reminder turned off');
      }
      return;
    }

    await GroupService.updateSettleUpDay(group.id, picked);
    await LocalNotificationService.scheduleMonthlySettleReminder(
      groupId: group.id,
      groupName: group.name,
      day: picked,
      myNetBalance: 0,
    );
    if (context.mounted) {
      showAppToast(context, 'You\'ll be reminded every month on day $picked');
    }
  }

  void _showMembers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${members.length} people',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (members.isEmpty)
                  Text(
                    'No members yet.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: members
                      .map(
                        (friend) => SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              LocalAvatar(
                                localKey: friend.id,
                                isProfile: false,
                                fallbackUrl: friend.avatarUrl,
                                radius: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                friend.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 16),
                child: Text(
                  group.name,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    GroupHeaderPill(
                      icon: Icons.calendar_today_rounded,
                      label: group.settleUpDay == null
                          ? 'Add settle up date'
                          : 'Settle up on day ${group.settleUpDay}',
                      onTap: () => _editSettleUpDate(context),
                    ),
                    const SizedBox(width: 10),
                    GroupHeaderPill(
                      icon: Icons.people_alt_rounded,
                      label: '${members.length} people',
                      onTap: () => _showMembers(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillList extends StatelessWidget {
  final List<Bill> bills;
  final Map<String, Friend> friendById;
  final IconData Function(String) iconFor;
  final Color Function(String) iconBgFor;
  final Color Function(Color) iconColorFor;
  final double Function(Bill, Map<String, Friend>) remainingForBill;

  const _BillList({
    required this.bills,
    required this.friendById,
    required this.iconFor,
    required this.iconBgFor,
    required this.iconColorFor,
    required this.remainingForBill,
  });

  @override
  Widget build(BuildContext context) {
    // Group bills by month/year, preserving the incoming (newest-first) sort.
    final grouped = <String, List<Bill>>{};
    for (final bill in bills) {
      final key = _monthYear(bill.date);
      grouped.putIfAbsent(key, () => []).add(bill);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final monthKey = grouped.keys.elementAt(groupIndex);
        final monthBills = grouped[monthKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                monthKey,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...monthBills.map(
              (bill) => _BillRow(
                bill: bill,
                remaining: remainingForBill(bill, friendById),
                icon: iconFor(bill.title),
                iconBg: iconBgFor(bill.title),
                iconColor: iconColorFor(iconBgFor(bill.title)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BillRow extends StatelessWidget {
  final Bill bill;
  final double remaining;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _BillRow({
    required this.bill,
    required this.remaining,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final youPaid = bill.paidBy == 'me';
    final isSettled = youPaid
        ? remaining <= 0.009
        : bill.remainingMyShare <= 0.009;

    final amount = youPaid ? remaining : bill.remainingMyShare;
    final label = isSettled
        ? 'settled'
        : (youPaid ? 'you lent' : 'you borrowed');
    final amountColor = isSettled
        ? AppColors.textSecondary
        : (youPaid ? AppColors.success : AppColors.warning);

    return GestureDetector(
      onTap: () {
        if (bill.ownerId != FirebaseAuth.instance.currentUser?.uid) {
          showAppToast(
            context,
            'Only the person who added this bill can edit it',
          );
          return;
        }
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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => EditBillScreen(bill: bill)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    _monthAbbr(bill.date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _dayPad(bill.date),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    youPaid
                        ? 'You paid ₹${bill.amount.toStringAsFixed(0)}'
                        : 'A friend paid ₹${bill.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: amountColor),
                ),
                Text(
                  isSettled ? '₹0' : '₹${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
