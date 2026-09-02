import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/add_bill_screen.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<Friend>>(
                stream: FriendService.streamFriends(),
                builder: (context, friendSnapshot) {
                  final friends = friendSnapshot.data ?? [];
                  final friendById = {for (final f in friends) f.id: f};
                  final members = friends
                      .where((f) => group.memberFriendIds.contains(f.id))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member avatar row
                      if (members.isNotEmpty)
                        SizedBox(
                          height: 78,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: members.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final friend = members[index];
                              return Column(
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
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                          'Bills',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      Expanded(
                        child: StreamBuilder<List<Bill>>(
                          stream: BillService.streamBills(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final bills =
                                (snapshot.data ?? [])
                                    .where((b) => b.groupId == group.id)
                                    .toList()
                                  ..sort((a, b) => b.date.compareTo(a.date));

                            if (bills.isEmpty) {
                              return Center(
                                child: Text(
                                  'No bills in this group yet. Tap + to add one.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                final bill = bills[index];
                                final remaining = _remainingForBill(
                                  bill,
                                  friendById,
                                );
                                final isSettled = remaining <= 0.009;

                                return GestureDetector(
                                  onTap: () {
                                    if (bill.settledFriendIds.isNotEmpty ||
                                        bill.settledUids.isNotEmpty ||
                                        bill
                                            .partialPaymentsByFriend
                                            .isNotEmpty ||
                                        bill.partialPaymentsByUid.isNotEmpty ||
                                        bill.myPartialPayment > 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'This bill has settled activity and can no longer be edited',
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditBillScreen(bill: bill),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                bill.title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Total ₹${bill.amount.toStringAsFixed(0)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              isSettled
                                                  ? '₹0'
                                                  : '₹${remaining.toStringAsFixed(0)} due',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              isSettled ? 'Settled' : 'Pending',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: isSettled
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
