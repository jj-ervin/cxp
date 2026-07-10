import 'package:flutter/material.dart';

/// Basketball sport pack playing surface (half-court, offensive end).
/// Sport-pack-owned per `docs/architecture/plugin-architecture.md` — the
/// editor's core canvas has no opinion on what a "court" looks like.
class BasketballCourtPainter extends CustomPainter {
  const BasketballCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final court = Paint()
      ..color = const Color(0xFFDDB27A)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Offset.zero & size;
    canvas.drawRect(rect, court);
    canvas.drawRect(rect.deflate(1), line);

    // Key / paint (free-throw lane), centered on the baseline.
    final laneWidth = size.width * 0.32;
    final laneHeight = size.height * 0.42;
    final lane = Rect.fromLTWH(
      (size.width - laneWidth) / 2,
      size.height - laneHeight,
      laneWidth,
      laneHeight,
    );
    canvas.drawRect(lane, line);

    // Free-throw circle.
    final ftCenter = Offset(size.width / 2, lane.top);
    canvas.drawCircle(ftCenter, laneWidth / 2, line);

    // Three-point arc (simplified, single radius).
    final basketCenter = Offset(size.width / 2, size.height - size.height * 0.06);
    final arcRadius = size.width * 0.44;
    canvas.drawArc(
      Rect.fromCircle(center: basketCenter, radius: arcRadius),
      3.4, // ~195deg, roughly past the sideline break
      2.6,
      false,
      line,
    );

    // Rim.
    canvas.drawCircle(basketCenter, size.width * 0.02, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
