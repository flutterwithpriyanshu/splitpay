import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/model/bill.dart';
import 'package:splitpay/services/bill_service.dart';
import 'package:splitpay/services/friend_service.dart';
import 'package:splitpay/screens/edit_bill_screen.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Full detail view for one bill inside a group — icon/title header,
/// who added it and when, an Edit button (owner only), and a row per
/// participant showing what they paid / still owe.
class BillDetailScreen extends StatelessWidget {
  final Bill bill;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const BillDetailScreen({
    super.key,
    required this.bill,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  static const _avatarPalette = [
    Color(0xFFB0184D),
    Color(0xFF2E2E2E),
    Color(0xFFFF7A45),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
  ];

  Color _avatarColorFor(String uid) =>
      _avatarPalette[uid.hashCode.abs() % _avatarPalette.length];

  Future<String> _nameFor(String uid, String myUid) {
    if (uid == myUid) return Future.value('You');
    return FriendService.getUserName(uid);
  }

  void _openEdit(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final canManage = bill.ownerId == myUid;
    final payerUid = bill.paidByUid ?? bill.ownerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Expense details',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\u20b9${bill.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: _nameFor(bill.ownerId, myUid),
                      builder: (context, snap) => Text(
                        'Added by ${snap.data ?? '...'} on ${formatDate(bill.date)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (canManage)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openEdit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit expense'),
              ),
            ),
          const SizedBox(height: 24),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          ...bill.participantUids.map((uid) {
            final isPayer = uid == payerUid;
            final amount = isPayer ? bill.amount : (bill.sharesByUid[uid] ?? 0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _avatarColorFor(uid),
                    child: Text(
                      uid == myUid
                          ? 'Y'
                          : (uid.isNotEmpty ? uid[0].toUpperCase() : '?'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _nameFor(uid, myUid),
                      builder: (context, snap) {
                        final name = snap.data ?? '...';
                        return RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(text: '$name '),
                              TextSpan(
                                text: isPayer ? 'paid' : 'get',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: ' INR${amount.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isPayer
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
