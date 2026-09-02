import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/model/transaction.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/transaction_service.dart';
import 'package:splitpay/services/upi_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/widgets/local_avatar.dart';
import 'package:splitpay/screens/friend_details/widgets/bill_tile.dart';

enum PaymentMethod { cash, upi }

class _SettleResult {
  final double amount;
  final PaymentMethod method;
  _SettleResult(this.amount, this.method);
}

class FriendDetailsScreen extends StatelessWidget {
  final Friend friend;

  const FriendDetailsScreen({super.key, required this.friend});

  /// Fetches the friend's REAL UPI ID + name from their own user doc.
  /// Only works for linked friends — unlinked friends have no account,
  /// so there's nowhere to read a UPI ID from.
  Future<Map<String, String>?> _fetchFriendUpiInfo() async {
    if (!friend.isLinked) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friend.linkedUid)
        .get();
    final data = doc.data();
    final upiId = (data?['upiId'] as String?)?.trim();
    if (upiId == null || upiId.isEmpty) return null;
    final name = (data?['fullName'] as String?)?.trim();
    return {
      'upiId': upiId,
      'name': (name == null || name.isEmpty) ? friend.name : name,
    };
  }

  Future<_SettleResult?> _showSettleSheet(
    BuildContext context, {
    required double outstanding,
    required bool youOwe,
  }) {
    final controller = TextEditingController(
      text: outstanding.toStringAsFixed(2),
    );
    PaymentMethod method = PaymentMethod.cash;

    return showModalBottomSheet<_SettleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Settle Up',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    youOwe
                        ? 'You owe ${friend.name} ₹${outstanding.toStringAsFixed(0)}'
                        : '${friend.name} owes you ₹${outstanding.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Amount to settle',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Method',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PaymentMethod>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Cash',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          value: PaymentMethod.cash,
                          groupValue: method,
                          onChanged: (v) => setSheetState(() => method = v!),
                        ),
                      ),
                      // UPI only offered when this friend is linked — an
                      // unlinked friend has no account, so there's no
                      // real UPI ID to pay into.
                      if (friend.isLinked)
                        Expanded(
                          child: RadioListTile<PaymentMethod>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'UPI',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            value: PaymentMethod.upi,
                            groupValue: method,
                            onChanged: (v) => setSheetState(() => method = v!),
                          ),
                        ),
                    ],
                  ),
                  if (!friend.isLinked) ...[
                    const SizedBox(height: 4),
                    Text(
                      'UPI is only available for friends with a SplitPay account.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(controller.text.trim());
                      if (val == null || val <= 0) {
                        showAppToast(context, 'Enter a valid amount');
                        return;
                      }
                      if (val > outstanding + 0.01) {
                        showAppToast(
                          context,
                          'Amount cannot exceed ₹${outstanding.toStringAsFixed(0)}',
                        );
                        return;
                      }
                      Navigator.pop(context, _SettleResult(val, method));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Writes the transaction + updates bill settlement state. Shared by
  /// both the Cash path and the confirmed-UPI path.
  Future<void> _recordSettlement(
    BuildContext context, {
    required double entered,
    required bool youOwe,
    required double outstanding,
    String? note,
  }) async {
    try {
      await TransactionService.addTransaction(
        personName: friend.name,
        amount: entered,
        type: youOwe ? TransactionType.sent : TransactionType.received,
        note: note,
      );

      await BillService.settlePartialForFriend(
        friendId: friend.id,
        linkedUid: friend.isLinked ? friend.linkedUid : null,
        youOwe: youOwe,
        amount: entered,
      );

      if (friend.isLinked) {
        final myProfile = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
        final myName = myProfile.data()?['fullName'] ?? 'A friend';

        await TransactionService.addTransactionForUid(
          targetUid: friend.linkedUid!,
          personName: myName,
          amount: entered,
          type: youOwe ? TransactionType.received : TransactionType.sent,
          note: note,
        );
      }

      if (context.mounted) {
        showAppToast(
          context,
          entered >= outstanding - 0.01
              ? 'Settled up!'
              : 'Partial payment recorded',
          isError: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, 'Settle Up failed: $e');
      }
    }
  }

  /// Handles the UPI branch: fetch the friend's REAL UPI ID, launch
  /// intent, then ask user to confirm the payment actually went through
  /// (client-side UPI response can't be trusted as proof).
  Future<void> _handleUpiSettlement(
    BuildContext context, {
    required _SettleResult result,
    required bool youOwe,
    required double outstanding,
  }) async {
    final upiInfo = await _fetchFriendUpiInfo();
    if (upiInfo == null) {
      if (context.mounted) {
        showAppToast(
          context,
          '${friend.name} hasn\'t set up a UPI ID yet. Try Cash instead.',
        );
      }
      return;
    }

    final launchResult = await UpiService.launchUpiPayment(
      upiId: upiInfo['upiId']!,
      receiverName: upiInfo['name']!,
      amount: result.amount,
    );

    if (launchResult == UpiLaunchResult.noAppFound) {
      if (context.mounted) {
        showAppToast(
          context,
          'No UPI app found. Please install a UPI app or choose Cash.',
        );
      }
      return;
    }
    if (launchResult == UpiLaunchResult.failed) {
      if (context.mounted) {
        showAppToast(context, 'Could not open UPI app.');
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Did the UPI payment of ₹${result.amount.toStringAsFixed(0)} go through?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not yet / Cancelled',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, paid',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (context.mounted) {
        showAppToast(context, 'Payment not recorded');
      }
      return;
    }

    await _recordSettlement(
      context,
      entered: result.amount,
      youOwe: youOwe,
      outstanding: outstanding,
      note: 'Paid via UPI',
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Bill>>(
          stream: BillService.streamBillsForFriend(friend.id),
          builder: (context, ownSnapshot) {
            final ownBills = ownSnapshot.data ?? [];
            final ownLoading =
                ownSnapshot.connectionState == ConnectionState.waiting;

            final sharedStream = friend.isLinked
                ? BillService.streamSharedBillsFrom(friend.linkedUid!)
                : const Stream<List<Bill>>.empty();

            return StreamBuilder<List<Bill>>(
              stream: sharedStream,
              builder: (context, sharedSnapshot) {
                final sharedBills = sharedSnapshot.data ?? [];
                final sharedLoading =
                    friend.isLinked &&
                    sharedSnapshot.connectionState == ConnectionState.waiting;

                final isLoading = ownLoading || sharedLoading;

                // Balance from bills you created (uses REMAINING, not full share).
                double balance = 0;
                for (final bill in ownBills) {
                  if (bill.paidBy == 'me') {
                    if (bill.friendIds.contains(friend.id)) {
                      balance += friend.isLinked
                          ? bill.remainingForUid(friend.linkedUid!)
                          : bill.remainingForFriend(friend.id);
                    }
                  } else if (bill.paidBy == friend.id) {
                    balance -= bill.remainingMyShare;
                  }
                }
                // Balance from bills THEY created that include you.
                for (final bill in sharedBills) {
                  balance += bill.balanceForUid(myUid);
                }

                final youOwe = balance < 0;
                final outstanding = balance.abs();
                final balanceText = balance == 0
                    ? 'You are settled up'
                    : youOwe
                    ? 'You owe ${friend.name} ₹${outstanding.toStringAsFixed(0)}'
                    : '${friend.name} owes you ₹${outstanding.toStringAsFixed(0)}';
                final balanceColor = balance == 0
                    ? AppColors.textSecondary
                    : youOwe
                    ? AppColors.error
                    : AppColors.success;

                final allBills = [...ownBills, ...sharedBills]
                  ..sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Text(
                            'Friend Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          Column(
                            children: [
                              LocalAvatar(
                                localKey: friend.id,
                                isProfile: false,
                                fallbackUrl: friend.avatarUrl,
                                radius: 44,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                friend.name,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (friend.isLinked) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SplitPay user',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    balanceText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: balanceColor,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Shared Bills',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isLoading)
                            ...List.generate(
                              2,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            )
                          else if (allBills.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No shared bills yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...allBills.map((bill) {
                              final isOwn = bill.ownerId == myUid;
                              bool settled;
                              double amount;
                              if (isOwn) {
                                settled = friend.isLinked
                                    ? bill.settledUids.contains(
                                        friend.linkedUid,
                                      )
                                    : bill.isSettledFor(friend.id);
                                amount = bill.amount;
                              } else {
                                settled = bill.settledUids.contains(myUid);
                                amount = bill.sharesByUid[myUid] ?? 0;
                              }
                              return FriendBillTile(
                                bill: bill,
                                isSettled: settled,
                                amount: amount,
                              );
                            }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: balance == 0
                              ? null
                              : () async {
                                  final result = await _showSettleSheet(
                                    context,
                                    outstanding: outstanding,
                                    youOwe: youOwe,
                                  );
                                  if (result == null) return;

                                  if (result.method == PaymentMethod.cash) {
                                    await _recordSettlement(
                                      context,
                                      entered: result.amount,
                                      youOwe: youOwe,
                                      outstanding: outstanding,
                                    );
                                    return;
                                  }

                                  await _handleUpiSettlement(
                                    context,
                                    result: result,
                                    youOwe: youOwe,
                                    outstanding: outstanding,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.textSecondary
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Settle Up',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
