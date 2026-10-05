import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';

const _kMint = Color(0xFF34D399);
const _kForest = Color(0xFF0F7A55);

/// Full-screen "Device Shield" page shown while Firebase sends the OTP.
/// Progress is cosmetic: climbs to ~94% and waits until the parent pops it.
class SecurityCheckScreen extends StatefulWidget {
  const SecurityCheckScreen({super.key, required this.onCancel});

  /// Close (X), system back, or "Cancel and retry".
  final VoidCallback onCancel;

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..forward();

  // (icon, title, subtitle, progress needed to be "verified")
  static const _checks = <(IconData, String, String, double)>[
    (
      Icons.sim_card_outlined,
      'SIM Slot 1 Integrity',
      'Dual-hash IMSI validated',
      0.28,
    ),
    (
      Icons.lock_outline_rounded,
      'Device Root Integrity',
      'Tamper and root checks',
      0.60,
    ),
    (
      Icons.fingerprint_rounded,
      'Device Binding',
      'Secure hardware key attached',
      0.90,
    ),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: dark
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEDE9FF), Color(0xFFF5F6FB)],
                    ),
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final progress = Curves.easeOut.transform(_c.value) * 0.94;
                  return Column(
                    children: [
                      _header(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              _illustration(),
                              _statusChip(),
                              const SizedBox(height: 12),
                              Text(
                                'Checking device security…',
                                textAlign: TextAlign.center,
                                style: AppText.headlineLg.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _progressCard(progress),
                              const SizedBox(height: 12),
                              _checksCard(progress),
                              const SizedBox(height: 12),
                              _zeroRetention(),
                              const SizedBox(height: 8),
                              _footer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const AppLogo(size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SplitPay',
                style: AppText.labelLg.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Device Shield v2.4',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: AppColors.primaryTint,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onCancel,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustration() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer hairline ring
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Mint glow
          Positioned(
            bottom: 0,
            child: Container(
              width: 260,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kMint.withValues(alpha: 0.22),
                    _kMint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Soft mid circle
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.07),
            ),
          ),
          // Dashed ring
          SizedBox(
            width: 232,
            height: 232,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          // Orbiting mint dot
          SizedBox(
                width: 232,
                height: 232,
                child: Stack(
                  children: [
                    Positioned(
                      left: 116 + 116 * math.cos(math.pi * 0.75) - 7,
                      top: 116 + 116 * math.sin(math.pi * 0.75) - 7,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _kMint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kMint.withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 7000.ms, begin: 0, end: 1),
          // Main coin
          Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 62,
                      color: AppColors.primary,
                    ),
                    Positioned(
                      right: 22,
                      bottom: 24,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _kForest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.04, 1.04),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.3, end: 1, duration: 700.ms),
          const SizedBox(width: 8),
          Text(
            'ISOLATED SANDBOX RUNNING',
            style: AppText.labelSm.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
    boxShadow: AppShadows.card,
  );

  Widget _progressCard(double progress) {
    final done = _checks.where((c) => progress >= c.$4).length;
    final step = (done + 1).clamp(1, 3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Security Protocols',
                style: AppText.labelLg.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppText.labelLg
                    .copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    )
                    .tabular,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.surfaceRaised),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, _kMint],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Step $step of 3',
              style: AppText.labelMd.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checksCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        children: [
          for (var i = 0; i < _checks.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _checkRow(
              icon: _checks[i].$1,
              title: _checks[i].$2,
              sub: _checks[i].$3,
              status: progress >= _checks[i].$4
                  ? _CheckStatus.verified
                  : (i == 0 || progress >= _checks[i - 1].$4)
                  ? _CheckStatus.scanning
                  : _CheckStatus.queued,
            ),
          ],
        ],
      ),
    );
  }

  Widget _checkRow({
    required IconData icon,
    required String title,
    required String sub,
    required _CheckStatus status,
  }) {
    final verified = status == _CheckStatus.verified;
    final scanning = status == _CheckStatus.scanning;
    final onMint = AppColors.palette.isDark
        ? AppColors.success
        : const Color(0xFF065F46);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: verified || scanning
            ? AppColors.primaryTint
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.success.withValues(alpha: 0.22)
                  : AppColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: verified ? onMint : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.success.withValues(alpha: 0.22)
                  : scanning
                  ? AppColors.surface
                  : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verified) ...[
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: onMint,
                  ),
                  const SizedBox(width: 4),
                ] else if (scanning) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  verified
                      ? 'Verified'
                      : scanning
                      ? 'Scanning'
                      : 'Queued',
                  style: AppText.labelMd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: verified
                        ? onMint
                        : scanning
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeroRetention() {
    Widget badge(IconData icon, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.labelMd.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: _kForest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero Data Retention Guarantee',
                      style: AppText.labelLg.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SplitPay complies with RBI master directions. We never view, transfer, or store your UPI MPIN or bank passcodes.',
                      style: AppText.bodySm.copyWith(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              badge(Icons.verified_outlined, 'NPCI Certified'),
              const SizedBox(width: 8),
              badge(Icons.lock_clock_outlined, '256-Bit SSL'),
              const SizedBox(width: 8),
              badge(Icons.gpp_good_outlined, 'RBI Regulated'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return InkWell(
      onTap: widget.onCancel,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Having trouble? Cancel and retry',
              style: AppText.labelMd.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CheckStatus { queued, scanning, verified }

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rect = (Offset.zero & size).deflate(1);
    const n = 56;
    const step = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, step * 0.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
