import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

class GroupSplitupScreen extends StatelessWidget {
  const GroupSplitupScreen({required this.group, super.key});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final memberUids = group.allMemberUids;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Group split-up',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<List<Bill>>(
        stream: BillService.streamGroupBills(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bills = snapshot.data ?? const <Bill>[];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: memberUids.length,
            itemBuilder: (context, index) {
              final uid = memberUids[index];
              final net = bills.fold<double>(
                0,
                (sum, bill) => sum + bill.balanceForUid(uid),
              );
              return _MemberSplitRow(
                uid: uid,
                net: net,
                isOwner: uid == group.ownerId,
              );
            },
          );
        },
      ),
    );
  }
}

class _MemberSplitRow extends StatelessWidget {
  const _MemberSplitRow({
    required this.uid,
    required this.net,
    required this.isOwner,
  });

  final String uid;
  final double net;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final color = net.abs() <= 0.009
        ? AppColors.textSecondary
        : net > 0
        ? AppColors.success
        : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: FriendService.getUserName(uid),
              builder: (context, snapshot) => Text(
                '${snapshot.data ?? 'Loading...'}${isOwner ? ' (owner)' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(
            net.abs() <= 0.009
                ? 'Settled'
                : net > 0
                ? 'Gets ₹${net.toStringAsFixed(2)}'
                : 'Owes ₹${(-net).toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
