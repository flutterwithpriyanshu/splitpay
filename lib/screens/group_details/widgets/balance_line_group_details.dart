import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/theme/app_colors.dart';

class GroupBalanceLine extends StatelessWidget {
  const GroupBalanceLine({required this.net, required this.members, super.key});

  final double net;
  final List<Friend> members;

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() <= 0.009;
    final other = members.length == 1 ? members.first.name : null;

    final String text;
    final Color color;
    if (isSettled) {
      text = 'Settled up';
      color = AppColors.textSecondary;
    } else if (net > 0) {
      text = other != null
          ? 'Get ₹${net.toStringAsFixed(2)} from $other'
          : 'Get ₹${net.toStringAsFixed(2)}';
      color = AppColors.success;
    } else {
      text = other != null
          ? 'Pay $other ₹${(-net).toStringAsFixed(2)}'
          : 'Pay ₹${(-net).toStringAsFixed(2)}';
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
