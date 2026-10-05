import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/app_logo.dart';

// Brand splash: same gradient in light and dark (DESIGN.md primary gradient
// + mid stop from the splash design).
const _kViolet = Color(0xFF5B3DF5);
const _kVioletMid = Color(0xFF6D4CF6);
const _kViolet2 = Color(0xFF8E5BFF);
const _kMint = Color(0xFF34D399);

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kViolet,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _kViolet2,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kViolet, _kVioletMid, _kViolet2],
            ),
          ),
          child: Stack(
            children: [
              // Ambient glows
              Positioned(
                top: -128,
                left: -128,
                child: _glow(384, Colors.white.withValues(alpha: 0.10)),
              ),
              Positioned(
                bottom: -96,
                right: -96,
                child: _glow(384, _kMint.withValues(alpha: 0.15)),
              ),
              Center(
                child: OverflowBox(
                  maxWidth: 500,
                  maxHeight: 500,
                  child: _glow(500, _kViolet2.withValues(alpha: 0.30)),
                ),
              ),
              // Circle watermark
              Center(
                child: OverflowBox(
                  maxWidth: 560,
                  maxHeight: 560,
                  child: const SizedBox(
                    width: 560,
                    height: 560,
                    child: CustomPaint(painter: _WatermarkPainter()),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _content(),
                        ),
                      ),
                    ),
                    _footer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow(double size, Color c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
    ),
  );

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo coin + aura
        Stack(
              alignment: Alignment.center,
              children: [
                _glow(160, Colors.white.withValues(alpha: 0.20))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.5, end: 1, duration: 600.ms),
                _glow(128, _kMint.withValues(alpha: 0.25)),
                _Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(12),
                  fill: Colors.white.withValues(alpha: 0.10),
                  border: Colors.white.withValues(alpha: 0.20),
                  shadow: BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 45,
                    offset: const Offset(0, 20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icon/playstore.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const AppLogo(size: 96),
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 250.ms),
        const SizedBox(height: 24),
        // Wordmark + mint dot
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SplitPay',
              style: AppText.displayLgMobile.copyWith(
                fontSize: 36,
                height: 1.1,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kMint,
                  boxShadow: [
                    BoxShadow(
                      color: _kMint.withValues(alpha: 0.9),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 250.ms),
        const SizedBox(height: 6),
        Text(
          'Split smart. Settle easy.',
          textAlign: TextAlign.center,
          style: AppText.bodyLg.copyWith(
            color: Colors.white.withValues(alpha: 0.90),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 250.ms),
        const SizedBox(height: 24),
        _Glass(
          radius: 999,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          fill: Colors.white.withValues(alpha: 0.15),
          border: Colors.white.withValues(alpha: 0.25),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: _kMint),
              const SizedBox(width: 6),
              Text(
                'Instant Peer Settlements',
                style: AppText.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 250.ms),
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDots(),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, size: 15, color: _kMint),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'FAST UPI SETTLEMENTS • NPCI COMPLIANT',
                  style: AppText.labelSm.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> {
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _dot(active: _step % 3 == i),
        ],
      ],
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedScale(
      scale: active ? 1.35 : 1,
      duration: 180.ms,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.65,
        duration: 180.ms,
        child: AnimatedContainer(
          duration: 180.ms,
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _kMint : Colors.white.withValues(alpha: 0.80),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _kMint.withValues(alpha: 0.9),
                      blurRadius: 14,
                    ),
                  ]
                : const [],
          ),
        ),
      ),
    );
  }
}

/// Glass-look container: translucent fill + hairline border (no blur).
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    required this.radius,
    required this.padding,
    required this.fill,
    required this.border,
    this.shadow,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color fill;
  final Color border;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow == null ? null : [shadow!],
      ),
      // No BackdropFilter: it renders blank on some Impeller/GLES devices.
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: r,
          border: Border.all(color: border),
        ),
        child: child,
      ),
    );
  }
}

/// Dashed rings + arcs behind content (500x500 design space, 15% opacity).
class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 500, size.height / 500);
    const o = Offset(250, 250);
    const base = 0.15;

    Paint p(Color c, double op, double w, {bool round = false}) => Paint()
      ..color = c.withValues(alpha: base * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;

    void dashed(Path path, double dash, double gap, Paint paint) {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + dash), paint);
          d += dash + gap;
        }
      }
    }

    dashed(
      Path()..addOval(Rect.fromCircle(center: o, radius: 235)),
      6,
      8,
      p(Colors.white, 0.5, 1.5),
    );
    dashed(
      Path()..addOval(Rect.fromCircle(center: o, radius: 185)),
      14,
      10,
      p(_kMint, 0.4, 1.5),
    );
    canvas.drawCircle(o, 130, p(Colors.white, 0.6, 1));

    canvas.drawPath(
      Path()
        ..moveTo(120, 70)
        ..arcToPoint(
          const Offset(380, 430),
          radius: const Radius.circular(230),
        ),
      p(Colors.white, 0.7, 2.5, round: true),
    );
    canvas.drawPath(
      Path()
        ..moveTo(390, 100)
        ..arcToPoint(
          const Offset(110, 390),
          radius: const Radius.circular(210),
        ),
      p(_kMint, 0.55, 2, round: true),
    );
    dashed(
      Path()
        ..moveTo(90, 90)
        ..lineTo(410, 410),
      4,
      6,
      p(Colors.white, 0.3, 1),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
