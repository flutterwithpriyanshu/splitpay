import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/core/app_currency.dart';

class SharedGroupBalanceLine extends StatelessWidget {
  const SharedGroupBalanceLine({required this.net, super.key});

  final double net;

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() <= 0.009;

    final String text;
    final Color color;
    if (isSettled) {
      text = 'Settled up';
      color = AppColors.textSecondary;
    } else if (net > 0) {
      text = 'Get ${AppCurrency.symbol}${net.toStringAsFixed(2)}';
      color = AppColors.success;
    } else {
      text = 'Pay ${AppCurrency.symbol}${(-net).toStringAsFixed(2)}';
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
