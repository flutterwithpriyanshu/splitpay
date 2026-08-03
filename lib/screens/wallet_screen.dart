import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/model/transaction.dart';
import 'package:splitpay/services/transaction_service.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<WalletTransaction>>(
          stream: TransactionService.streamTransactions(),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            double walletBalance = 0;
            for (final tx in transactions) {
              if (tx.type == TransactionType.received) {
                walletBalance += tx.amount;
              } else {
                walletBalance -= tx.amount;
              }
            }

            final monthlySpending = _buildMonthlySpending(transactions);

            if (isLoading) return _buildSkeleton();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    'Wallet',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBalanceCard(walletBalance),
                  const SizedBox(height: 24),
                  Text(
                    'Monthly Spending',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(monthlySpending),
                  const SizedBox(height: 24),
                  Text(
                    'Transaction History',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    _buildEmptyTransactions()
                  else
                    ...transactions.map(_buildTransactionTile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Groups "sent" transactions (money that left your wallet) into the
  /// last 6 calendar months for the bar chart.
  List<Map<String, dynamic>> _buildMonthlySpending(
    List<WalletTransaction> transactions,
  ) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      return date;
    });

    return months.map((month) {
      final total = transactions
          .where(
            (tx) =>
                tx.type == TransactionType.sent &&
                tx.date.year == month.year &&
                tx.date.month == month.month,
          )
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return {'month': monthNames[month.month - 1], 'amount': total};
    }).toList();
  }

  Widget _buildBalanceCard(double balance) {
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
            'Wallet Balance',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${balance < 0 ? '-' : ''}₹${balance.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> monthlySpending) {
    final maxAmount = monthlySpending
        .map((e) => e['amount'] as double)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxAmount == 0 ? 100.0 : maxAmount * 1.2;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
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
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= monthlySpending.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthlySpending[index]['month'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(monthlySpending.length, (index) {
            final amount = monthlySpending[index]['amount'] as double;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMax,
                    color: AppColors.background,
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx) {
    final isSent = tx.type == TransactionType.sent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isSent ? AppColors.error : AppColors.success).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSent
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isSent ? AppColors.error : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSent
                      ? 'Sent to ${tx.personName}'
                      : 'Received from ${tx.personName}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Show the adjustment note if present, otherwise the date
                  tx.note ?? '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isSent ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSent ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (tx.isCompleted ? AppColors.success : AppColors.warning)
                          .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.isCompleted ? 'Completed' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tx.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.swap_vert_rounded,
            size: 56,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Settle up with a friend to see it here',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _skeletonBox(height: 32, width: 100),
        const SizedBox(height: 20),
        _skeletonBox(height: 130, width: double.infinity, radius: 24),
        const SizedBox(height: 24),
        _skeletonBox(height: 18, width: 160),
        const SizedBox(height: 16),
        _skeletonBox(height: 220, width: double.infinity, radius: 20),
        const SizedBox(height: 24),
        _skeletonBox(height: 18, width: 180),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _skeletonBox(height: 72, width: double.infinity, radius: 16),
          ),
        ),
      ],
    );
  }

  Widget _skeletonBox({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
