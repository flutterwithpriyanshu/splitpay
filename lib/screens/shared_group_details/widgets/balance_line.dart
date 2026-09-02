import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/theme/app_colors.dart';

class SharedGroupBalanceLine extends StatelessWidget {
  const SharedGroupBalanceLine({required this.net, super.key});

  final double net;

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() <= 0.009;

    final String text;
    final Color color;
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
