import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/theme/app_colors.dart';

class ManageFriendsScreen extends StatelessWidget {
  const ManageFriendsScreen({super.key});

  void _confirmRemove(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove friend?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove them from your friends list.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FriendService.removeFriend(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Balance with a specific friend across all bills.
  /// Positive = friend owes you. Negative = you owe friend.
  double _balanceForFriend(List<Bill> bills, String friendId) {
    double balance = 0;
    for (final bill in bills) {
      if (bill.isSettledFor(friendId)) continue;
      if (!bill.friendIds.contains(friendId)) continue;
      if (bill.paidBy == 'me') {
        balance += bill.shareForFriend(friendId);
      } else if (bill.paidBy == friendId) {
        balance -= bill.myShare;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Text(
                  'Manage Friends',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<Friend>>(
                stream: FriendService.streamFriends(),
                builder: (context, friendSnapshot) {
                  final friends = friendSnapshot.data ?? [];
                  final friendsLoading =
                      friendSnapshot.connectionState == ConnectionState.waiting;

                  if (friendsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (friends.isEmpty) {
                    return Center(
                      child: Text(
                        'No friends added yet',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<List<Bill>>(
                    stream: BillService.streamBills(),
                    builder: (context, billSnapshot) {
                      final bills = billSnapshot.data ?? [];
                      final billsLoading =
                          billSnapshot.connectionState ==
                          ConnectionState.waiting;

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final balance = _balanceForFriend(bills, friend.id);

                          String balanceText;
                          Color balanceColor;

                          if (billsLoading) {
                            balanceText = '...';
                            balanceColor = AppColors.textSecondary;
                          } else if (balance == 0) {
                            balanceText = 'Settled up';
                            balanceColor = AppColors.textSecondary;
                          } else if (balance > 0) {
                            balanceText =
                                'Owes you ₹${balance.abs().toStringAsFixed(0)}';
                            balanceColor = AppColors.success;
                          } else {
                            balanceText =
                                'You owe ₹${balance.abs().toStringAsFixed(0)}';
                            balanceColor = AppColors.error;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(
                                    friend.avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        balanceText,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: balanceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _confirmRemove(context, friend.id),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
