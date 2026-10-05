import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.withBackground = true});

  final double size;

  /// false = transparent (adaptive icon foreground / on-dark use).
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(withBackground)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.withBackground);
  final bool withBackground;

  static const _purple = Color(0xFF6C4DFF);
  static const _green = Color(0xFF2BC48A);
  static const _navy = Color(0xFF0F1128);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 240);

    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 240, 240),
          const Radius.circular(64),
        ),
        Paint()..color = _navy,
      );
    }

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    double rad(double deg) => deg * math.pi / 180;

    // "(" : math angle 118 -> 242 through 180
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(122, 119), radius: 58),
      -rad(118),
      -rad(124),
      false,
      stroke(_purple),
    );
    // ")" : math angle 62 -> -62 through 0
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(118, 124), radius: 58),
      -rad(62),
      rad(124),
      false,
      stroke(_green),
    );

    canvas.drawCircle(
      const Offset(120, 121),
      20,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(120, 121), 10, Paint()..color = _purple);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.withBackground != withBackground;
}
