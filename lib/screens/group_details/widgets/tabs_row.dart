import 'package:flutter/material.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupTabsRow extends StatelessWidget {
  const GroupTabsRow({
    required this.onSettleUp,
    required this.onBalances,
    super.key,
  });

  final VoidCallback onSettleUp;
  final VoidCallback onBalances;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _TabPill(
            icon: Icons.handshake_outlined,
            label: 'Settle up',
            onTap: onSettleUp,
          ),
          const SizedBox(width: 10),
          _TabPill(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Charts',
            onTap: () => showAppToast(context, 'Coming soon'),
          ),
          const SizedBox(width: 10),
          _TabPill(
            icon: Icons.bar_chart_rounded,
            label: 'Balances',
            onTap: onBalances,
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
