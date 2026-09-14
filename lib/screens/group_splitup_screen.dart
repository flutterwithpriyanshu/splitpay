import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/debt_simplifier.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/model/group.dart';
import 'package:splitpay/model/transaction.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/services/transaction_service.dart';
import 'package:splitpay/services/upi_service.dart';
import 'package:splitpay/theme/app_colors.dart';

enum _PaymentMethod { cash, upi }

/// Settle-up screen for a group: takes the smallest set of "who pays whom"
/// payments (core/debt_simplifier.dart) and lets the CURRENT user act on
/// whichever row involves them — pay via UPI or Cash if they're the one
/// who owes, or mark it received (Cash) if they're the one owed.
class GroupSettleUpScreen extends StatelessWidget {
  final Group group;

  const GroupSettleUpScreen({super.key, required this.group});

  Future<Map<String, String>?> _fetchUpiInfo(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    final upiId = (data?['upiId'] as String?)?.trim();
    if (upiId == null || upiId.isEmpty) return null;
    final name = (data?['fullName'] as String?)?.trim();
    return {
      'upiId': upiId,
      'name': (name == null || name.isEmpty) ? 'them' : name,
    };
  }

  Future<void> _record(
    BuildContext context, {
    required SimplifiedDebt payment,
    required String myUid,
    required _PaymentMethod method,
  }) async {
    final youOwe = payment.fromUid == myUid;
    try {
      await BillService.settleGroupPayment(
        groupId: group.id,
        fromUid: payment.fromUid,
        toUid: payment.toUid,
        amount: payment.amount,
      );

      final otherUid = youOwe ? payment.toUid : payment.fromUid;
      final otherName = await FriendService.getUserName(otherUid);
      final note = method == _PaymentMethod.upi
          ? 'Paid via UPI \u2022 ${group.name}'
          : 'Cash \u2022 ${group.name}';

      await TransactionService.addTransaction(
        personName: otherName,
        amount: payment.amount,
        type: youOwe ? TransactionType.sent : TransactionType.received,
        note: note,
      );
      await TransactionService.addTransactionForUid(
        targetUid: otherUid,
        personName: await FriendService.getUserName(myUid),
        amount: payment.amount,
        type: youOwe ? TransactionType.received : TransactionType.sent,
        note: note,
      );

      if (context.mounted) {
        showAppToast(context, 'Settled up!', isError: false);
      }
    } catch (e) {
      if (context.mounted) showAppToast(context, 'Settle Up failed: $e');
    }
  }

  Future<void> _handleUpi(
    BuildContext context, {
    required SimplifiedDebt payment,
  }) async {
    final upiInfo = await _fetchUpiInfo(payment.toUid);
    if (upiInfo == null) {
      if (context.mounted) {
        showAppToast(context, 'They haven\'t set up a UPI ID yet. Try Cash.');
      }
      return;
    }

    final launchResult = await UpiService.launchUpiPayment(
      upiId: upiInfo['upiId']!,
      receiverName: upiInfo['name']!,
      amount: payment.amount,
    );

    if (launchResult == UpiLaunchResult.noAppFound) {
      if (context.mounted) {
        showAppToast(context, 'No UPI app found. Install one or choose Cash.');
      }
      return;
    }
    if (launchResult == UpiLaunchResult.failed) {
      if (context.mounted) showAppToast(context, 'Could not open UPI app.');
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Did the UPI payment of \u20b9${payment.amount.toStringAsFixed(0)} go through?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Not yet / Cancelled',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
      if (context.mounted) showAppToast(context, 'Payment not recorded');
      return;
    }

    await _record(
      context,
      payment: payment,
      myUid: payment.fromUid,
      method: _PaymentMethod.upi,
    );
  }

  Future<void> _showSettleSheet(
    BuildContext context, {
    required SimplifiedDebt payment,
    required bool youOwe,
    required String otherName,
  }) async {
    _PaymentMethod method = _PaymentMethod.cash;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                        ? 'You owe $otherName \u20b9${payment.amount.toStringAsFixed(0)}'
                        : '$otherName owes you \u20b9${payment.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (youOwe) ...[
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
                          child: RadioListTile<_PaymentMethod>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Cash',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            value: _PaymentMethod.cash,
                            groupValue: method,
                            onChanged: (v) => setSheetState(() => method = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<_PaymentMethod>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'UPI',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            value: _PaymentMethod.upi,
                            groupValue: method,
                            onChanged: (v) => setSheetState(() => method = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    Text(
                      'Mark this as received once the cash is in hand.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      youOwe ? method.name : 'received',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      youOwe
                          ? (method == _PaymentMethod.upi
                                ? 'Pay via UPI'
                                : 'Continue')
                          : 'Mark Received',
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

    if (action == null || !context.mounted) return;

    if (action == 'upi') {
      await _handleUpi(context, payment: payment);
    } else if (action == 'cash') {
      await _record(
        context,
        payment: payment,
        myUid: payment.fromUid,
        method: _PaymentMethod.cash,
      );
    } else if (action == 'received') {
      await _record(
        context,
        payment: payment,
        myUid: payment.toUid,
        method: _PaymentMethod.cash,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final memberUids = group.allMemberUids;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Settle Up',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<Bill>>(
        stream: BillService.streamGroupBills(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bills = snapshot.data ?? const <Bill>[];
          final netByUid = <String, double>{
            for (final uid in memberUids)
              uid: bills.fold<double>(
                0,
                (sum, bill) => sum + bill.balanceForUid(uid),
              ),
          };
          final payments = simplifyDebts(netByUid);

          if (payments.isEmpty) {
            return Center(
              child: Text(
                'Everyone is settled up',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final youOwe = payment.fromUid == myUid;
              final youAreOwed = payment.toUid == myUid;
              final canAct = youOwe || youAreOwed;

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
                      child: FutureBuilder<List<String>>(
                        future: Future.wait([
                          FriendService.getUserName(payment.fromUid),
                          FriendService.getUserName(payment.toUid),
                        ]),
                        builder: (context, snap) {
                          final names = snap.data;
                          final fromName = names?[0] ?? 'Loading...';
                          final toName = names?[1] ?? 'Loading...';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: youOwe ? 'You' : fromName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: ' pays '),
                                    TextSpan(
                                      text: youAreOwed ? 'you' : toName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\u20b9${payment.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (canAct)
                      ElevatedButton(
                        onPressed: () async {
                          final otherUid = youOwe
                              ? payment.toUid
                              : payment.fromUid;
                          final otherName = await FriendService.getUserName(
                            otherUid,
                          );
                          if (!context.mounted) return;
                          _showSettleSheet(
                            context,
                            payment: payment,
                            youOwe: youOwe,
                            otherName: otherName,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Settle',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
