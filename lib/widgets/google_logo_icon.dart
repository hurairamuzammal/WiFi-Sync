import 'package:flutter/material.dart';

/// Crisp, pixel-perfect official 4-color Google "G" brand icon.
/// Renders via native vector paths with zero blur, scaling smoothly
/// to any requested resolution without external network or SVG asset dependencies.
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    // Google Brand Colors (Blue #4285F4, Green #34A853, Yellow #FBBC05, Red #EA4335)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // 1. Blue Path (Horizontal bar & upper right arc)
    final bluePath = Path();
    bluePath.moveTo(23.745 * scale, 12.27 * scale);
    bluePath.cubicTo(23.745 * scale, 11.48 * scale, 23.67 * scale, 10.73 * scale, 23.54 * scale, 10.0 * scale);
    bluePath.lineTo(12.0 * scale, 10.0 * scale);
    bluePath.lineTo(12.0 * scale, 14.58 * scale);
    bluePath.lineTo(18.6 * scale, 14.58 * scale);
    bluePath.cubicTo(18.32 * scale, 16.08 * scale, 17.47 * scale, 17.35 * scale, 16.2 * scale, 18.2 * scale);
    bluePath.lineTo(16.2 * scale, 21.22 * scale);
    bluePath.lineTo(20.08 * scale, 21.22 * scale);
    bluePath.cubicTo(22.35 * scale, 19.13 * scale, 23.745 * scale, 16.0 * scale, 23.745 * scale, 12.27 * scale);
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Path (Bottom arc)
    final greenPath = Path();
    greenPath.moveTo(12.0 * scale, 24.0 * scale);
    greenPath.cubicTo(15.24 * scale, 24.0 * scale, 17.96 * scale, 22.93 * scale, 20.08 * scale, 21.22 * scale);
    greenPath.lineTo(16.2 * scale, 18.2 * scale);
    greenPath.cubicTo(15.12 * scale, 18.93 * scale, 13.69 * scale, 19.38 * scale, 12.0 * scale, 19.38 * scale);
    greenPath.cubicTo(8.87 * scale, 19.38 * scale, 6.2 * scale, 17.26 * scale, 5.25 * scale, 14.4 * scale);
    greenPath.lineTo(1.24 * scale, 14.4 * scale);
    greenPath.lineTo(1.24 * scale, 17.51 * scale);
    greenPath.cubicTo(3.27 * scale, 21.36 * scale, 7.34 * scale, 24.0 * scale, 12.0 * scale, 24.0 * scale);
    greenPath.close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow Path (Bottom-left & left arc)
    final yellowPath = Path();
    yellowPath.moveTo(5.25 * scale, 14.4 * scale);
    yellowPath.cubicTo(5.0 * scale, 13.66 * scale, 4.87 * scale, 12.85 * scale, 4.87 * scale, 12.0 * scale);
    yellowPath.cubicTo(4.87 * scale, 11.15 * scale, 5.0 * scale, 10.34 * scale, 5.25 * scale, 9.6 * scale);
    yellowPath.lineTo(5.25 * scale, 6.49 * scale);
    yellowPath.lineTo(1.24 * scale, 6.49 * scale);
    yellowPath.cubicTo(0.45 * scale, 8.16 * scale, 0.0 * scale, 10.02 * scale, 0.0 * scale, 12.0 * scale);
    yellowPath.cubicTo(0.0 * scale, 13.98 * scale, 0.45 * scale, 15.84 * scale, 1.24 * scale, 17.51 * scale);
    yellowPath.lineTo(5.25 * scale, 14.4 * scale);
    yellowPath.close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red Path (Top arc)
    final redPath = Path();
    redPath.moveTo(12.0 * scale, 4.62 * scale);
    redPath.cubicTo(13.76 * scale, 4.62 * scale, 15.34 * scale, 5.23 * scale, 16.58 * scale, 6.42 * scale);
    redPath.lineTo(20.16 * scale, 2.84 * scale);
    redPath.cubicTo(18.0 * scale, 0.83 * scale, 15.24 * scale, 0.0 * scale, 12.0 * scale, 0.0 * scale);
    redPath.cubicTo(7.34 * scale, 0.0 * scale, 3.27 * scale, 2.64 * scale, 1.24 * scale, 6.49 * scale);
    redPath.lineTo(5.25 * scale, 9.6 * scale);
    redPath.cubicTo(6.2 * scale, 6.74 * scale, 8.87 * scale, 4.62 * scale, 12.0 * scale, 4.62 * scale);
    redPath.close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
