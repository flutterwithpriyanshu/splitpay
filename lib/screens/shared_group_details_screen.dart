import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

const _kMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _kMonthFullNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _monthAbbr(DateTime d) => _kMonthNames[d.month - 1];
String _dayPad(DateTime d) => d.day.toString().padLeft(2, '0');
String _monthYear(DateTime d) => '${_kMonthFullNames[d.month - 1]} ${d.year}';

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

/// Shown when you tap a group that someone ELSE created and added you
/// to as a linked member. Same visual language as the owner's
/// GroupDetailsScreen (gradient header, balance line, tab pills,
/// month-grouped bill list) but read-only: no add-bill FAB, no
/// settings/edit-members action, bills aren't tappable. Data is scoped
/// to `streamSharedBillsFrom(group.ownerId)` — bills that involve you,
/// not the owner's full bill list.
class SharedGroupDetailsScreen extends StatelessWidget {
  final Group group;

  const SharedGroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Bill>>(
        stream: BillService.streamSharedBillsFrom(group.ownerId),
        builder: (context, snapshot) {
          final bills = (snapshot.data ?? [])
              .where((b) => b.groupId == group.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          double net = 0;
          for (final bill in bills) {
            net += bill.balanceForUid(myUid);
          }

          return Column(
            children: [
              _SharedHeader(group: group),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BalanceLine(net: net),
              ),
              const SizedBox(height: 14),
              _TabsRow(
                onSettleUp: () {
                  showAppToast(
                    context,
                    'Open a friend from this group to settle up',
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : bills.isEmpty
                        ? Center(
                            child: Text(
                              'No bills in this group yet.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : _SharedBillList(bills: bills, myUid: myUid),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SharedHeader extends StatelessWidget {
  final Group group;

  const _SharedHeader({required this.group});

  void _showMembers(BuildContext context) {
    final uids = [group.ownerId, ...group.memberUids];
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
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary.withOpacity(0.4),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<String>(
                                future: FriendService.getUserName(uid),
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
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
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
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: FutureBuilder<String>(
                  future: FriendService.getUserName(group.ownerId),
                  builder: (context, snap) => Text(
                    'Shared by ${snap.data ?? '...'}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    _HeaderPill(
                      icon: Icons.people_alt_rounded,
                      label: '${group.memberUids.length + 1} people',
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

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final double net;

  const _BalanceLine({required this.net});

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() <= 0.009;

    String text;
    Color color;
    if (isSettled) {
      text = 'You are all settled up';
      color = AppColors.textSecondary;
    } else if (net > 0) {
      text = 'You are owed ₹${net.toStringAsFixed(2)}';
      color = AppColors.success;
    } else {
      text = 'You owe ₹${(-net).toStringAsFixed(2)}';
      color = AppColors.warning;
    }

    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final VoidCallback onSettleUp;

  const _TabsRow({required this.onSettleUp});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _TabPill(
            icon: Icons.handshake_outlined,
            label: 'Settle up',
            onTap: onSettleUp,
          ),
          const SizedBox(width: 10),
          _TabPill(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Charts',
            onTap: () {
              showAppToast(context, 'Coming soon');
            },
          ),
          const SizedBox(width: 10),
          _TabPill(
            icon: Icons.bar_chart_rounded,
            label: 'Balances',
            onTap: () {
              showAppToast(context, 'Coming soon');
            },
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TabPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedBillList extends StatelessWidget {
  final List<Bill> bills;
  final String myUid;

  const _SharedBillList({required this.bills, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Bill>>{};
    for (final bill in bills) {
      final key = _monthYear(bill.date);
      grouped.putIfAbsent(key, () => []).add(bill);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
              (bill) => _SharedBillRow(bill: bill, myUid: myUid),
            ),
          ],
        );
      },
    );
  }
}

class _SharedBillRow extends StatelessWidget {
  final Bill bill;
  final String myUid;

  const _SharedBillRow({required this.bill, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final myShare = bill.sharesByUid[myUid] ?? 0;
    final remaining = bill.remainingForUid(myUid);
    final isSettled = remaining <= 0.009;
    final youPaid = bill.paidByUid == myUid;

    final label = isSettled ? 'settled' : (youPaid ? 'you lent' : 'you owe');
    final amountColor = isSettled
        ? AppColors.textSecondary
        : (youPaid ? AppColors.success : AppColors.warning);

    final icon = _iconFor(bill.title);
    final iconBg = _iconBgFor(bill.title);

    return Padding(
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
            child: Icon(icon, color: Colors.black.withOpacity(0.55), size: 20),
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
                  'Your share ₹${myShare.toStringAsFixed(0)}',
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
                isSettled ? '₹0' : '₹${remaining.toStringAsFixed(2)}',
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
  }
}
