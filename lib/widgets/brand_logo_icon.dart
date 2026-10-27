import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Minimal flat Nordic-pastel brand icon for WiFi Sync.
/// Signature pastel clipboard card centered in the squircle, with clean
/// WiFi broadcast waves radiating at the top-right of the clipboard:
/// soft pastel lavender squircle (#EBE7F8), clean white clipboard card,
/// muted slate-plum (#463E66) refined strokes, and soft pastel mint (#A6E1C8) accents.
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
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEBE7F8),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFDDD7F0),
          width: 1.0,
        ),
      ),
      child: CustomPaint(
        painter: _CenteredClipboardWithTopRightWiFiPainter(
          showBadge: showBadge,
        ),
      ),
    );
  }
}

class _CenteredClipboardWithTopRightWiFiPainter extends CustomPainter {
  final bool showBadge;

  const _CenteredClipboardWithTopRightWiFiPainter({this.showBadge = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2.0;
    final cy = s / 2.0;

    const inkPlum = Color(0xFF463E66);
    const pastelMint = Color(0xFFA6E1C8);
    const pastelIris = Color(0xFFC4BCEA);

    final strokeW = (s * 0.028).clamp(1.5, 6.0);

    final strokePaint = Paint()
      ..color = inkPlum
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 1. Centered Clipboard Card
    final boardW = s * 0.44;
    final boardH = s * 0.54;
    final boardR = s * 0.095;

    final bx0 = cx - boardW / 2.0;
    final by0 = cy - boardH / 2.0 + s * 0.035;

    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx0, by0, boardW, boardH),
      Radius.circular(boardR),
    );
    canvas.drawRRect(boardRect, fillWhite);
    canvas.drawRRect(boardRect, strokePaint);

    // Top pastel-mint clip pill
    final clipW = boardW * 0.46;
    final clipH = boardH * 0.19;
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - clipW / 2.0, by0 - clipH * 0.48, clipW, clipH),
      Radius.circular(clipH / 2.0),
    );
    canvas.drawRRect(clipRect, Paint()..color = pastelMint);
    canvas.drawRRect(clipRect, strokePaint);

    // Horizontal pastel lines inside card
    final padX = boardW * 0.22;
    final lineH = (s * 0.038).clamp(1.6, 8.0);
    final lx0 = bx0 + padX;
    final lx1 = bx0 + boardW - padX;

    final ly1 = by0 + boardH * 0.43;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx0, ly1, lx1 - lx0, lineH),
        Radius.circular(lineH / 2.0),
      ),
      Paint()..color = pastelIris,
    );

    final ly2 = by0 + boardH * 0.63;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx0, ly2, boardW * 0.36, lineH),
        Radius.circular(lineH / 2.0),
      ),
      Paint()..color = pastelMint,
    );

    final dotRBottom = lineH * 0.52;
    canvas.drawCircle(
      Offset(lx1 - dotRBottom, ly2 + lineH / 2.0),
      dotRBottom,
      Paint()..color = showBadge ? const Color(0xFF34C77B) : inkPlum,
    );

    // 2. WiFi symbol at TOP RIGHT of clipboard
    final wifiCx = cx + (boardW / 2.0) + s * 0.05;
    final wifiCenterY = by0 + s * 0.045;
    final wDotR = (s * 0.024).clamp(1.5, 4.0);

    // Broadcast dot
    canvas.drawCircle(
      Offset(wifiCx, wifiCenterY),
      wDotR,
      Paint()..color = showBadge ? const Color(0xFF34C77B) : inkPlum,
    );

    // Arcs radiating upward (start -135°, sweep 90°)
    const startAngle = -3.0 * math.pi / 4.0;
    const sweepAngle = math.pi / 2.0;

    final radii = [s * 0.06, s * 0.11, s * 0.16];
    for (final rad in radii) {
      final rect = Rect.fromCircle(
        center: Offset(wifiCx, wifiCenterY),
        radius: rad,
      );
      canvas.drawArc(rect, startAngle, sweepAngle, false, strokePaint);
    }
  }

  @override
  bool shouldRepaint(
          covariant _CenteredClipboardWithTopRightWiFiPainter oldDelegate) =>
      oldDelegate.showBadge != showBadge;
}
