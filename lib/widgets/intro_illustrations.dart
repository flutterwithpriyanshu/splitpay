import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';

part 'upi_illustration.dart';

// Intro illustrations. Pure widgets, no image assets.
// Each one has a fixed design size; IntroScreen scales it with FittedBox.

const _kMaroon = Color(0xFF9B1239);
const _kForest = Color(0xFF0F7A55);

/// Dark green text on mint fill (light), plain success (dark).
Color get _onMint =>
    AppColors.palette.isDark ? AppColors.success : const Color(0xFF065F46);

BoxDecoration _floatDeco() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.pill),
  border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
  boxShadow: AppShadows.raised,
);

BoxDecoration _cardDeco() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.card),
  border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
  boxShadow: AppShadows.raised,
);

/// Slow up/down drift for floating chips.
class _Float extends StatelessWidget {
  const _Float({
    required this.child,
    this.dy = 4,
    this.delayMs = 0,
  });

  final Widget child;
  final double dy;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
          delay: Duration(milliseconds: delayMs),
        )
        .moveY(
          begin: -dy,
          end: dy,
          duration: const Duration(milliseconds: 2600),
          curve: Curves.easeInOut,
        );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.text, this.color, {this.size = 32, this.ring = false});

  final String text;
  final Color color;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: AppColors.surface, width: 2) : null,
      ),
      child: Text(
        text,
        style: AppText.labelMd.copyWith(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppText.labelMd.copyWith(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating "X paid / X owes" chip.
class _Toast extends StatelessWidget {
  const _Toast({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: _floatDeco(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.labelMd.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                amount,
                style: AppText.currencyMd.copyWith(
                  fontSize: 16,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Add Bills
// ---------------------------------------------------------------------------

class BillIllustration extends StatelessWidget {
  const BillIllustration({super.key});

  static const double width = 340;
  static const double height = 330;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 30,
            top: 52,
            width: 280,
            child: Transform.rotate(angle: -0.035, child: _card()),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: _Float(
              child: _Toast(
                icon: Icons.check_rounded,
                iconBg: _kForest,
                iconColor: Colors.white,
                title: 'Aarav paid',
                amount: '+ ₹1,200',
                amountColor: _kForest,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 74,
            child: _Float(
              delayMs: 500,
              child: _Toast(
                icon: Icons.schedule_rounded,
                iconBg: AppColors.dangerTint,
                iconColor: _kMaroon,
                title: 'Priya owes',
                amount: '- ₹1,200',
                amountColor: _kMaroon,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 262,
            child: _Float(
              delayMs: 900,
              child: _Toast(
                icon: Icons.priority_high_rounded,
                iconBg: AppColors.dangerTint,
                iconColor: _kMaroon,
                title: 'Rohan owes',
                amount: '- ₹1,200',
                amountColor: _kMaroon,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 288,
            child: _Float(
              delayMs: 300,
              dy: 3,
              child: _Pill(
                text: 'Equal Split 1/3',
                icon: Icons.bolt_rounded,
                bg: AppColors.success.withValues(alpha: 0.28),
                fg: _onMint,
                fontSize: 13,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 244,
            child: _Float(
              delayMs: 700,
              dy: 5,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.raised,
                ),
                child: Text(
                  '₹',
                  style: AppText.labelMd.copyWith(
                    color: const Color(0xFF0F1226),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 176,
            child: _Float(
              delayMs: 200,
              dy: 3,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.bodyMd.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
        ),
        Text(
          amount,
          style: AppText.labelMd
              .copyWith(color: AppColors.textPrimary, fontSize: 15)
              .tabular,
        ),
      ],
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.ramen_dining_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinner',
                    style: AppText.headlineSm.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Burma Burma',
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              children: [
                _line('Khow Suey & Teas', '₹3,200'),
                const SizedBox(height: 10),
                _line('Taxes & Service', '₹400'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TOTAL BILL',
                style: AppText.labelSm.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹3,600',
                style: AppText.currencyMd.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 72,
                height: 32,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: _Avatar('A', AppColors.primary, ring: true),
                    ),
                    const Positioned(
                      left: 20,
                      child: _Avatar('P', _kMaroon, ring: true),
                    ),
                    const Positioned(
                      left: 40,
                      child: _Avatar('R', _kForest, ring: true),
                    ),
                  ],
                ),
              ),
              Text(
                '₹1,200 / person',
                style: AppText.labelMd
                    .copyWith(color: AppColors.primary)
                    .tabular,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Track Balances
// ---------------------------------------------------------------------------

class BalanceIllustration extends StatelessWidget {
  const BalanceIllustration({super.key});

  static const double width = 340;
  static const double height = 366;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 5, top: 18, width: 330, child: _card()),
          Positioned(
            left: 0,
            top: 0,
            child: _Float(
              dy: 3,
              child: Transform.rotate(
                angle: -0.09,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: _floatDeco(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-Netted',
                        style: AppText.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 100,
            child: _Float(
              dy: 3,
              delayMs: 600,
              child: Transform.rotate(
                angle: 0.08,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: _floatDeco(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Zero Disputes',
                        style: AppText.labelMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _person({
    required String initials,
    required Color color,
    required String name,
    required String sub,
    required String amount,
    required Color amountColor,
    required String action,
    required IconData actionIcon,
    required Color actionBg,
    required Color actionFg,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          _Avatar(initials, color, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: AppText.currencyMd.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 6),
          _Pill(
            text: action,
            icon: actionIcon,
            bg: actionBg,
            fg: actionFg,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                Icon(
                  Icons.currency_rupee_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'SMART NETTING',
                  style: AppText.labelSm.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                _Pill(
                  text: 'Realtime',
                  icon: Icons.sync_rounded,
                  bg: AppColors.success.withValues(alpha: 0.22),
                  fg: _onMint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Overall Balance',
                      style: AppText.bodyMd.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    _Pill(
                      text: 'You get back',
                      icon: Icons.trending_up_rounded,
                      bg: AppColors.success.withValues(alpha: 0.22),
                      fg: _onMint,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '+₹1,850.00',
                  style: AppText.currencyDisplay.copyWith(
                    fontSize: 34,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _person(
            initials: 'K',
            color: AppColors.primary,
            name: 'Kabir Mehta',
            sub: 'Owes you for…',
            amount: '+₹2,500',
            amountColor: AppColors.success,
            action: 'Remind',
            actionIcon: Icons.notifications_none_rounded,
            actionBg: AppColors.primaryTint,
            actionFg: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _person(
            initials: 'S',
            color: _kMaroon,
            name: 'Sneha Kapoor',
            sub: 'You owe for fuel',
            amount: '-₹650',
            amountColor: AppColors.error,
            action: 'Pay',
            actionIcon: Icons.bolt_rounded,
            actionBg: AppColors.dangerTint,
            actionFg: AppColors.error,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Smart Simplification: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '6 circular debts collapsed into 2 swift payments.',
                        ),
                      ],
                    ),
                    style: AppText.bodySm.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
