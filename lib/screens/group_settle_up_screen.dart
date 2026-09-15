import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:splitpay/core/app_currency.dart';

enum _PaymentMethod { cash, upi }

class _SettleResult {
  final double amount;
  final _PaymentMethod method;
  _SettleResult(this.amount, this.method);
}

/// Standalone "Settle Up" screen for a group — separate from
/// [GroupSplitupScreen] (which is just a read-only balance list).
/// Shows the minimal set of "who pays whom" payments (or the raw
/// per-bill debts, depending on [Group.simplifyDebts]) and lets the
/// current user actually settle any payment that involves them, via
/// Cash or UPI — same flow as FriendDetailsScreen's Settle Up.
class GroupSettleUpScreen extends StatelessWidget {
  final Group group;

  const GroupSettleUpScreen({super.key, required this.group});

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  /// Real UPI id + display name for any registered uid, read straight
  /// from their user doc (group members are always registered accounts,
  /// unlike a Friend which can be an unlinked local contact).
  Future<Map<String, String>?> _fetchUpiInfoForUid(String uid) async {
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
      'name': (name == null || name.isEmpty) ? 'User' : name,
    };
  }

  List<SimplifiedDebt> _rawDebts(List<Bill> bills) {
    final amountByPair = <String, double>{}; // "owerUid|payerUid" -> amount
    for (final bill in bills) {
      final payer = bill.paidByUid ?? bill.ownerId;
      for (final uid in bill.participantUids) {
        if (uid == payer) continue;
        final owed = bill.remainingForUid(uid);
        if (owed <= 0.009) continue;
        final key = '$uid|$payer';
        amountByPair[key] = (amountByPair[key] ?? 0) + owed;
      }
    }
    return amountByPair.entries
        .map((e) {
          final parts = e.key.split('|');
          return SimplifiedDebt(
            fromUid: parts[0],
            toUid: parts[1],
            amount: double.parse(e.value.toStringAsFixed(2)),
          );
        })
        .where((d) => d.amount > 0.009)
        .toList();
  }

  Future<_SettleResult?> _showSettleSheet(
    BuildContext context, {
    required String otherName,
    required double outstanding,
    required bool youOwe,
    required bool upiAvailable,
  }) {
    final controller = TextEditingController(
      text: outstanding.toStringAsFixed(2),
    );
    _PaymentMethod method = _PaymentMethod.cash;

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
                        ? 'Pay $otherName ${AppCurrency.symbol}${outstanding.toStringAsFixed(0)}'
                        : 'Get ${AppCurrency.symbol}${outstanding.toStringAsFixed(0)} from $otherName',
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
                      if (upiAvailable)
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
                  if (!upiAvailable) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$otherName hasn\'t set up a UPI ID yet.',
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
                          'Amount cannot exceed ${AppCurrency.symbol}${outstanding.toStringAsFixed(0)}',
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

  /// Writes the transaction (both sides) + updates group-bill settlement
  /// state via [BillService.settleGroupPayment]. Shared by Cash and the
  /// confirmed-UPI path.
  Future<void> _recordSettlement(
    BuildContext context, {
    required SimplifiedDebt debt,
    required double entered,
    required String otherName,
    String? note,
  }) async {
    final youOwe = debt.fromUid == _myUid;
    try {
      await BillService.settleGroupPayment(
        groupId: group.id,
        fromUid: debt.fromUid,
        toUid: debt.toUid,
        amount: entered,
      );

      await TransactionService.addTransaction(
        personName: otherName,
        amount: entered,
        type: youOwe ? TransactionType.sent : TransactionType.received,
        note: note,
      );

      final myProfile = await FriendService.getMyProfile();
      final myName = myProfile?['fullName'] ?? 'A friend';
      final otherUid = youOwe ? debt.toUid : debt.fromUid;

      await TransactionService.addTransactionForUid(
        targetUid: otherUid,
        personName: myName,
        amount: entered,
        type: youOwe ? TransactionType.received : TransactionType.sent,
        note: note,
      );

      if (context.mounted) {
        showAppToast(
          context,
          entered >= debt.amount - 0.01
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

  /// UPI branch: fetch the receiving side's real UPI id, launch intent,
  /// then ask the user to confirm the payment actually went through
  /// (client-side UPI response can't be trusted as proof).
  Future<void> _handleUpiSettlement(
    BuildContext context, {
    required SimplifiedDebt debt,
    required _SettleResult result,
    required String otherName,
    required String receiverUid,
  }) async {
    final upiInfo = await _fetchUpiInfoForUid(receiverUid);
    if (upiInfo == null) {
      if (context.mounted) {
        showAppToast(
          context,
          '$otherName hasn\'t set up a UPI ID yet. Try Cash instead.',
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
          'Did the UPI payment of ${AppCurrency.symbol}${result.amount.toStringAsFixed(0)} go through?',
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
      debt: debt,
      entered: result.amount,
      otherName: otherName,
      note: 'Paid via UPI',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Settle Up · ${group.name}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<Bill>>(
        stream: BillService.streamGroupBills(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bills = snapshot.data ?? const <Bill>[];

          List<SimplifiedDebt> debts;
          if (group.simplifyDebts) {
            final netByUid = <String, double>{};
            for (final uid in group.allMemberUids) {
              netByUid[uid] = bills.fold<double>(
                0,
                (sum, bill) => sum + bill.balanceForUid(uid),
              );
            }
            debts = simplifyDebts(netByUid);
          } else {
            debts = _rawDebts(bills);
          }

          if (debts.isEmpty) {
            return Center(
              child: Text(
                'Everyone is settled up 🎉',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: debts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final debt = debts[index];
              final youOwe = debt.fromUid == _myUid;

              return FutureBuilder<List<String>>(
                future: Future.wait([
                  FriendService.getUserName(debt.fromUid),
                  FriendService.getUserName(debt.toUid),
                ]),
                builder: (context, nameSnap) {
                  final fromName = nameSnap.data?[0] ?? '...';
                  final toName = nameSnap.data?[1] ?? '...';
                  final otherName = youOwe ? toName : fromName;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: debt.fromUid == _myUid
                                      ? 'You'
                                      : fromName,
                                ),
                                TextSpan(
                                  text: ' pay',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${debt.toUid == _myUid ? 'you' : toName} ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${AppCurrency.symbol}${debt.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: youOwe
                                        ? AppColors.error
                                        : (debt.toUid == _myUid
                                              ? AppColors.success
                                              : AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (youOwe)
                          ElevatedButton(
                            onPressed: () async {
                              final upiInfo = await _fetchUpiInfoForUid(
                                youOwe ? debt.toUid : debt.fromUid,
                              );
                              if (!context.mounted) return;
                              final result = await _showSettleSheet(
                                context,
                                otherName: otherName,
                                outstanding: debt.amount,
                                youOwe: youOwe,
                                upiAvailable: upiInfo != null,
                              );
                              if (result == null) return;

                              if (result.method == _PaymentMethod.cash) {
                                await _recordSettlement(
                                  context,
                                  debt: debt,
                                  entered: result.amount,
                                  otherName: otherName,
                                );
                                return;
                              }

                              await _handleUpiSettlement(
                                context,
                                debt: debt,
                                result: result,
                                otherName: otherName,
                                receiverUid: youOwe ? debt.toUid : debt.fromUid,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Settle'),
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
    );
  }
}
