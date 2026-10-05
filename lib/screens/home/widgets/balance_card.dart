import 'package:flutter/material.dart';
import 'package:splitpay/core/app_date_format.dart';
import 'package:splitpay/core/app_toast.dart';
import 'package:splitpay/core/money_format.dart';
import 'package:splitpay/screens/home/widgets/balance_card_parts.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

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
  static const _bg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B3DF5), Color(0xFF4527DE), Color(0xFF2E12B8)],
  );

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
      statusColor = kMint;
    } else {
      status = 'in debt';
      statusColor = const Color(0xFFFFB4C0);
    }
    final totalText = hidden
        ? _mask
        : '${total < 0 ? '-' : ''}${formatMoney(total)}';
    final dark = AppColors.palette.isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: _bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF5B3DF5).withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -70,
              child: CustomPaint(size: Size(240, 240), painter: RingPainter()),
            ),
            const Positioned(
              top: -40,
              right: -40,
              child: CustomPaint(
                size: Size(170, 170),
                painter: RingPainter(dashed: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  _amount(totalText, status, statusColor),
                  _tiles(),
                  const SizedBox(height: 14),
                  _buttons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Text(
          'Total net balance',
          style: AppText.labelMd.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
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
            size: 15,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            monthYear(DateTime.now()),
            style: AppText.labelSm.copyWith(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _amount(String text, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: AppText.displayLgMobile
                    .copyWith(color: Colors.white, fontSize: 34, height: 1.1)
                    .tabular,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (!hidden)
            Text(
              status,
              style: AppText.labelMd.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tiles() {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: 'You owe',
            amount: hidden ? _mask : formatMoney(youOwe),
            caption: oweCaption,
            badgeBg: const Color(0xFFFFC9D1),
            badgeFg: const Color(0xFFB4234A),
            badgeIcon: Icons.north_east_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            label: 'You get back',
            amount: hidden ? _mask : formatMoney(youGet),
            caption: getCaption,
            badgeBg: kMint,
            badgeFg: kMintInk,
            badgeIcon: Icons.south_west_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CardButton(
            label: 'Settle Up',
            icon: Icons.bolt_rounded,
            fill: kMint,
            fg: kMintInk,
            onTap: onSettleUp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: CardButton(
            label: 'Analytics',
            icon: Icons.query_stats_rounded,
            fill: Colors.white.withValues(alpha: 0.14),
            fg: Colors.white,
            onTap: onAnalytics,
          ),
        ),
      ],
    );
  }
}
