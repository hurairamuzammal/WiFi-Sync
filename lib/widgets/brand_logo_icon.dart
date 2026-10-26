import 'package:flutter/material.dart';

/// Minimal flat Nordic-pastel brand icon for ClipSync.
/// Matches `assets/icons/app_icon.png` via crisp native vector rendering:
/// soft pastel lavender squircle (#EBE7F8), clean white clipboard card,
/// muted slate-plum (#463E66) refined stroke, and soft pastel mint (#A6E1C8) accents.
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
        painter: _MinimalPastelClipboardPainter(showBadge: showBadge),
      ),
    );
  }
}

class _MinimalPastelClipboardPainter extends CustomPainter {
  final bool showBadge;

  const _MinimalPastelClipboardPainter({this.showBadge = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final cy = s / 2;

    const inkPlum = Color(0xFF463E66);
    const pastelMint = Color(0xFFA6E1C8);
    const pastelIris = Color(0xFFC4BCEA);

    final boardW = s * 0.44;
    final boardH = s * 0.54;
    final boardR = s * 0.095;
    final strokeW = (s * 0.028).clamp(1.5, 6.0);

    final bx0 = cx - boardW / 2;
    final by0 = cy - boardH / 2 + s * 0.03;
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx0, by0, boardW, boardH),
      Radius.circular(boardR),
    );

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = inkPlum
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(boardRect, fillWhite);
    canvas.drawRRect(boardRect, strokePaint);

    // Top pastel-mint clip pill
    final clipW = boardW * 0.46;
    final clipH = boardH * 0.19;
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - clipW / 2, by0 - clipH * 0.48, clipW, clipH),
      Radius.circular(clipH / 2),
    );
    canvas.drawRRect(clipRect, Paint()..color = pastelMint);
    canvas.drawRRect(clipRect, strokePaint);

    // Minimal pastel horizontal pills inside
    final lineH = (s * 0.038).clamp(1.6, 8.0);
    final padX = boardW * 0.23;
    final lx0 = bx0 + padX;

    final ly1 = by0 + boardH * 0.43;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx0, ly1, boardW - padX * 2, lineH),
        Radius.circular(lineH / 2),
      ),
      Paint()..color = pastelIris,
    );

    final ly2 = by0 + boardH * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx0, ly2, boardW * 0.35, lineH),
        Radius.circular(lineH / 2),
      ),
      Paint()..color = pastelMint,
    );

    final dotR = lineH * 0.52;
    canvas.drawCircle(
      Offset(bx0 + boardW - padX - dotR, ly2 + lineH / 2),
      dotR,
      Paint()..color = showBadge ? const Color(0xFF34C77B) : inkPlum,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimalPastelClipboardPainter oldDelegate) =>
      oldDelegate.showBadge != showBadge;
}
