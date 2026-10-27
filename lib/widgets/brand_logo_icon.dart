import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Minimal monochrome WiFi brand icon for WiFi Sync.
/// Sleek obsidian squircle (#18181B) with crisp pure white WiFi arcs
/// and central broadcast dot, designed for pixel-perfect scaling across all sizes.
class BrandLogoIcon extends StatelessWidget {
  final double size;
  final bool showBadge;

  const BrandLogoIcon({
    super.key,
    this.size = 64,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF3F3F46),
          width: (size * 0.02).clamp(1.0, 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x2E000000),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _MonochromeWiFiPainter(showBadge: showBadge),
        ),
      ),
    );
  }
}

class _MonochromeWiFiPainter extends CustomPainter {
  final bool showBadge;

  const _MonochromeWiFiPainter({this.showBadge = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2.0;
    final cy = s * 0.65;

    final strokeW = (s * 0.065).clamp(1.8, 6.5);
    final dotR = (s * 0.068).clamp(2.0, 6.8);

    // Center broadcast dot
    final dotPaint = Paint()
      ..color = showBadge ? const Color(0xFF34C77B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), dotR, dotPaint);

    // WiFi waves (pure monochrome white)
    final wavePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Symmetric 86 degree sweep centered around vertical top (-pi / 2)
    const sweepAngle = 86.0 * math.pi / 180.0;
    final startAngle = -math.pi / 2.0 - (sweepAngle / 2.0);

    final radii = [s * 0.18, s * 0.31, s * 0.44];

    for (final r in radii) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, startAngle, sweepAngle, false, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonochromeWiFiPainter oldDelegate) =>
      oldDelegate.showBadge != showBadge;
}
