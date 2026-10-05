import 'package:flutter/material.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

const _mint = Color(0xFF34D399);
const _mintDark = Color(0xFF065F46);

class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({
    super.key,
    required this.youOwe,
    required this.youGet,
    required this.oweCaption,
    required this.getCaption,
    required this.hidden,
    required this.onSettleUp,
    required this.onAnalytics,
  });

  final double youOwe;
  final double youGet;
  final String oweCaption;
  final String getCaption;
  final bool hidden;
  final VoidCallback onSettleUp;
  final VoidCallback onAnalytics;

  static const _mask = '\u2022\u2022\u2022\u2022';

  @override
  Widget build(BuildContext context) {
    final total = youGet - youOwe;
    final settled = total.abs() < 0.005;
    final String status;
    final Color statusColor;
    if (settled) {
      status = 'all settled';
      statusColor = Colors.white.withValues(alpha: 0.75);
    } else if (total > 0) {
      status = 'in credit';
      statusColor = _mint;
    } else {
      status = 'in debt';
      statusColor = const Color(0xFFFFB4C0);
    }
    final totalText = hidden
        ? _mask
        : '${total < 0 ? '-' : ''}${formatMoney(total)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.raised,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -60,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total net balance',
                        style: AppText.labelLg.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => showAppToast(
                          context,
                          'Net balance = what you get back minus what you owe',
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          monthYear(DateTime.now()),
                          style: AppText.labelMd.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalText,
                            style: AppText.displayLg
                                .copyWith(
                                  color: Colors.white,
                                  fontSize: 46,
                                  height: 1.1,
                                )
                                .tabular,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!hidden)
                        Text(
                          status,
                          style: AppText.labelLg.copyWith(
                            color: statusColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'You owe',
                          amount: hidden ? _mask : formatMoney(youOwe),
                          caption: oweCaption,
                          badgeBg: const Color(0xFFFFC9D1),
                          badgeFg: const Color(0xFFB4234A),
                          badgeIcon: Icons.north_east_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          label: 'You get back',
                          amount: hidden ? _mask : formatMoney(youGet),
                          caption: getCaption,
                          badgeBg: _mint,
                          badgeFg: _mintDark,
                          badgeIcon: Icons.south_west_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _CardButton(
                          label: 'Settle Up',
                          icon: Icons.bolt_rounded,
                          fill: _mint,
                          fg: _mintDark,
                          onTap: onSettleUp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _CardButton(
                          label: 'Analytics',
                          icon: Icons.insights_rounded,
                          fill: Colors.white.withValues(alpha: 0.14),
                          fg: Colors.white,
                          border: Colors.white.withValues(alpha: 0.18),
                          onTap: onAnalytics,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.amount,
    required this.caption,
    required this.badgeBg,
    required this.badgeFg,
    required this.badgeIcon,
  });

  final String label;
  final String amount;
  final String caption;
  final Color badgeBg;
  final Color badgeFg;
  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(badgeIcon, size: 17, color: badgeFg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppText.headlineLg
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800)
                  .tabular,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMd.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.fill,
    required this.fg,
    required this.onTap,
    this.border,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color fg;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
