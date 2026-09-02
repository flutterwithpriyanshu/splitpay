import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/theme/app_colors.dart';

class FriendsGroupNetListener extends StatelessWidget {
  const FriendsGroupNetListener({
    required this.group,
    required this.myUid,
    required this.friendById,
    super.key,
  });

  final Group group;
  final String myUid;
  final Map<String, Friend> friendById;

  double _remainingForBill(Bill bill) {
    double total = 0;
    for (final id in bill.friendIds) {
      final friend = friendById[id];
      total += friend != null && friend.isLinked
          ? bill.remainingForUid(friend.linkedUid!)
          : bill.remainingForFriend(id);
    }
    return total;
  }

  double _netForBill(Bill bill) {
    if (bill.ownerId == myUid) {
      if (bill.paidBy == 'me') return _remainingForBill(bill);
      return -bill.remainingMyShare;
    }
    return bill.balanceForUid(myUid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bill>>(
      stream: BillService.streamGroupBills(group.id),
      builder: (context, snapshot) {
        final bills = snapshot.data ?? [];
        final net = bills.fold<double>(
          0,
          (sum, bill) => sum + _netForBill(bill),
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Loading...',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          );
        }

        final isSettled = net.abs() <= 0.009;
        final String subtitle;
        final Color color;
        if (bills.isEmpty) {
          subtitle = 'No bills yet';
          color = AppColors.textSecondary;
        } else if (isSettled) {
          subtitle = 'Settled up';
          color = AppColors.textSecondary;
        } else if (net > 0) {
          subtitle = 'you are owed ₹${net.toStringAsFixed(2)}';
          color = AppColors.success;
        } else {
          subtitle = 'you owe ₹${(-net).toStringAsFixed(2)}';
          color = AppColors.warning;
        }

        return Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        );
      },
    );
  }
}
