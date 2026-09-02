import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/theme/app_colors.dart';

class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({
    required this.youOwe,
    required this.youGet,
    super.key,
  });

  final double youOwe;
  final double youGet;

  @override
  Widget build(BuildContext context) {
    final total = youGet - youOwe;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${total < 0 ? '-' : ''}₹${total.abs().toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'You Owe',
                  amount: '₹${youOwe.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _BalanceStat(
                  label: 'You Get',
                  amount: '₹${youGet.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
