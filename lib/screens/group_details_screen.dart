import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/screens/add_bill_screen.dart';
import 'package:splitpay/screens/add_group_bill_screen.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';
import 'package:splitpay/screens/bill_detail_screen.dart';
import 'package:splitpay/services/group_service.dart';
import 'package:splitpay/services/local_notification_service.dart';
import 'package:splitpay/widgets/day_of_month_picker.dart';
import 'package:splitpay/screens/group_splitup_screen.dart';
import 'package:splitpay/screens/edit_group_settings_screen.dart';
import 'package:splitpay/screens/group_details/widgets/header_pill.dart';
import 'package:splitpay/screens/group_details/widgets/balance_line.dart';
import 'package:splitpay/screens/group_details/widgets/tabs_row.dart';
import 'package:splitpay/core/app_date_format.dart';

/// ONE group-details screen for EVERYONE in the group — owner and every
/// linked member land on the exact same layout, same tabs, same bill
/// list. The only gaps are gated behind `isOwner`: renaming the group /
/// editing members / the simplify-debts toggle (EditGroupSettingsScreen),
/// and changing the monthly settle-up date — everything else (balance,
/// Settle Up, Balances, adding/reading bills) behaves identically no
/// matter who's looking at it.
///
/// Accounting is uid-based (bill.balanceForUid / remainingForUid) instead
/// of the old friendId-based fields, because a member usually isn't
/// `bill.ownerId` and has no entry in the bill's friendId-shaped fields —
/// only the shared uid-based fields (participantUids/sharesByUid/
/// paidByUid) are guaranteed correct for every member, so that's what
/// this screen — and only this screen's math — now runs on for everyone.
class GroupDetailsScreen extends StatelessWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

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

  Color _iconColorFor(Color bg) => Colors.black.withValues(alpha: 0.55);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<Group>(
      // Live doc — member count, name, settle date all stay correct in
      // real time no matter who edits what while this screen is open.
      stream: GroupService.streamGroup(group.id),
      initialData: group,
      builder: (context, groupSnapshot) {
        final liveGroup = groupSnapshot.data ?? group;
        final isOwner = liveGroup.ownerId == myUid;

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => isOwner
                      ? AddBillScreen(
                          group: liveGroup,
                          onBillSaved: () => Navigator.of(context).pop(),
                        )
                      : AddGroupBillScreen(
                          group: liveGroup,
                          onBillSaved: () => Navigator.of(context).pop(),
                        ),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
          body: StreamBuilder<List<Bill>>(
            stream: BillService.streamGroupBills(liveGroup.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final bills = (snapshot.data ?? [])
                ..sort((a, b) => b.date.compareTo(a.date));

              double net = 0;
              for (final bill in bills) {
                net += bill.balanceForUid(myUid);
              }

              if (liveGroup.settleUpDay != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  LocalNotificationService.scheduleMonthlySettleReminder(
                    groupId: liveGroup.id,
                    groupName: liveGroup.name,
                    day: liveGroup.settleUpDay!,
                    myNetBalance: net,
                  );
                });
              }

              return Column(
                children: [
                  _Header(group: liveGroup, isOwner: isOwner),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // members left empty on purpose — same generic "You
                    // are owed / You owe" wording for every member,
                    // instead of the owner-only 1:1 friend-name variant.
                    child: GroupBalanceLine(net: net, members: const []),
                  ),
                  const SizedBox(height: 14),
                  GroupTabsRow(
                    onSettleUp: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupSettleUpScreen(group: liveGroup),
                        ),
                      );
                    },
                    onBalances: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupSettleUpScreen(group: liveGroup),
                        ),
                      );
                    },
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
                            myUid: myUid,
                            iconFor: _iconFor,
                            iconBgFor: _iconBgFor,
                            iconColorFor: _iconColorFor,
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Group group;
  final bool isOwner;

  const _Header({required this.group, required this.isOwner});

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

  /// Owner + every member, uid-based — identical for whoever opens it.
  void _showMembers(BuildContext context) {
    final uids = group.allMemberUids;
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
                  '${uids.length} people',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: uids
                      .map(
                        (uid) => SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<String>(
                                future:
                                    uid ==
                                        FirebaseAuth.instance.currentUser?.uid
                                    ? Future.value('You')
                                    : FriendService.getUserName(uid),
                                builder: (context, snap) => Text(
                                  uid == group.ownerId
                                      ? '${snap.data ?? '...'} (owner)'
                                      : (snap.data ?? '...'),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
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
                  // Rename / members / group type / simplify-debts is an
                  // owner-only action — every member still sees the same
                  // header, just without this gear.
                  if (isOwner)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditGroupSettingsScreen(group: group),
                          ),
                        );
                      },
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
                    if (isOwner)
                      GroupHeaderPill(
                        icon: Icons.calendar_today_rounded,
                        label: group.settleUpDay == null
                            ? 'Add settle up date'
                            : 'Settle up on day ${group.settleUpDay}',
                        onTap: () => _editSettleUpDate(context),
                      )
                    else if (group.settleUpDay != null)
                      GroupHeaderPill(
                        icon: Icons.calendar_today_rounded,
                        label: 'Settle up on day ${group.settleUpDay}',
                        onTap: () => showAppToast(
                          context,
                          'Only ${group.name}\'s owner can change the settle up date',
                        ),
                      ),
                    if (isOwner || group.settleUpDay != null)
                      const SizedBox(width: 10),
                    // allMemberUids = ownerId + memberUids, same formula
                    // every group screen uses — one source of truth,
                    // updates the moment the doc changes since this whole
                    // screen is fed by a live GroupService.streamGroup.
                    GroupHeaderPill(
                      icon: Icons.people_alt_rounded,
                      label: '${group.allMemberUids.length} people',
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
  final String myUid;
  final IconData Function(String) iconFor;
  final Color Function(String) iconBgFor;
  final Color Function(Color) iconColorFor;

  const _BillList({
    required this.bills,
    required this.myUid,
    required this.iconFor,
    required this.iconBgFor,
    required this.iconColorFor,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Bill>>{};
    for (final bill in bills) {
      final key = monthYear(bill.date);
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
                myUid: myUid,
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
  final String myUid;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _BillRow({
    required this.bill,
    required this.myUid,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // uid-based, same math on every member's screen: positive = you're
    // owed on this bill, negative = you still owe on it.
    final netForBill = bill.balanceForUid(myUid);
    final isSettled = netForBill.abs() <= 0.009;
    final youPaid = bill.paidByUid == myUid;

    final amount = netForBill.abs();
    final label = isSettled ? 'settled' : (youPaid ? 'you lent' : 'you owe');
    final amountColor = isSettled
        ? AppColors.textSecondary
        : (youPaid ? AppColors.success : AppColors.warning);
    final canManage = bill.ownerId == myUid;

    final cardContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  monthAbbr(bill.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  dayPad(bill.date),
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
                  'Paid \u20b9${bill.amount.toStringAsFixed(0)}',
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
                isSettled ? '\u20b90' : '\u20b9${amount.toStringAsFixed(2)}',
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
    );

    void openEdit() {
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
    }

    void openDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(
            bill: bill,
            icon: icon,
            iconBg: iconBg,
            iconColor: iconColor,
          ),
        ),
      );
    }

    if (!canManage) {
      return GestureDetector(onTap: openDetail, child: cardContent);
    }

    return Dismissible(
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
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete bill?'),
              content: const Text(
                'This bill will be removed for everyone in the group.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed != true) return false;
          try {
            await BillService.deleteBill(bill.id);
            return true;
          } catch (error) {
            if (context.mounted) {
              showAppToast(context, error.toString());
            }
            return false;
          }
        } else {
          openEdit();
          return false;
        }
      },
      child: GestureDetector(onTap: openDetail, child: cardContent),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color),
    );
  }
}
