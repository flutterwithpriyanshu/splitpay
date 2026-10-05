import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_text.dart';

const kMint = Color(0xFF6BF5C6);
const kMintInk = Color(0xFF0F2A22);

/// Solid or dashed thin ring used as card decoration.
class RingPainter extends CustomPainter {
  const RingPainter({this.dashed = false});
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: dashed ? 0.16 : 0.12);
    final r = size.width / 2;
    final c = Offset(r, r);
    if (!dashed) {
      canvas.drawCircle(c, r, p);
      return;
    }
    const n = 48;
    const sweep = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * sweep,
        sweep * 0.5,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(RingPainter old) => old.dashed != dashed;
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(badgeIcon, size: 14, color: badgeFg),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppText.headlineSm
                  .copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )
                  .tabular,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.fill,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return Material(
      color: fill,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
