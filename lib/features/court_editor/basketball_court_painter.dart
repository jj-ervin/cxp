import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/play_frame.dart';

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

/// Basketball sport pack path styling (CXP.06). Per
/// `docs/architecture/plugin-architecture.md`, the core engine has no
/// opinion on what a path "means" — this file owns the visual
/// vocabulary for the basketball pack's path types.
///
/// Deliberately simplified for the prototype: every path is drawn as a
/// straight segment (no curves yet — see `ActorPath.points` doc comment)
/// and dashed lines are approximated rather than using a dash-path
/// library dependency.
class BasketballPathsPainter extends CustomPainter {
  const BasketballPathsPainter({required this.paths, this.preview});

  final List<ActorPath> paths;

  /// An in-progress path being drawn (drag not yet released). Rendered
  /// with reduced opacity so it reads as provisional.
  final ActorPath? preview;

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      _drawPath(canvas, size, path, opacity: 1.0);
    }
    if (preview != null) {
      _drawPath(canvas, size, preview!, opacity: 0.55);
    }
  }

  void _drawPath(Canvas canvas, Size size, ActorPath path, {required double opacity}) {
    if (path.points.length < 2) return;
    final start = Offset(path.points.first.dx * size.width, path.points.first.dy * size.height);
    final end = Offset(path.points.last.dx * size.width, path.points.last.dy * size.height);

    final color = _colorFor(path.type).withValues(alpha: opacity);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    switch (path.type) {
      case PathType.pass:
        canvas.drawLine(start, end, paint);
        _drawArrowhead(canvas, start, end, paint, filled: false);
      case PathType.cut:
        canvas.drawLine(start, end, paint);
        _drawArrowhead(canvas, start, end, paint, filled: true);
      case PathType.dribble:
        _drawDashedLine(canvas, start, end, paint);
        _drawArrowhead(canvas, start, end, paint, filled: false);
      case PathType.shot:
        _drawDashedLine(canvas, start, end, paint);
        _drawArrowhead(canvas, start, end, paint, filled: true);
      case PathType.screen:
        canvas.drawLine(start, end, paint);
        _drawScreenBar(canvas, start, end, paint);
      case PathType.defense:
        _drawDashedLine(canvas, start, end, paint);
    }
  }

  Color _colorFor(PathType type) {
    switch (type) {
      case PathType.pass:
        return Colors.black87;
      case PathType.cut:
        return Colors.green.shade800;
      case PathType.dribble:
        return Colors.orange.shade800;
      case PathType.shot:
        return Colors.purple.shade700;
      case PathType.screen:
        return Colors.brown.shade700;
      case PathType.defense:
        return Colors.red.shade700;
    }
  }

  void _drawArrowhead(Canvas canvas, Offset start, Offset end, Paint paint, {required bool filled}) {
    const arrowLength = 10.0;
    const arrowAngle = 0.5; // radians
    final direction = (end - start);
    if (direction.distance == 0) return;
    final angle = math.atan2(direction.dy, direction.dx);

    final p1 = end - Offset(math.cos(angle - arrowAngle), math.sin(angle - arrowAngle)) * arrowLength;
    final p2 = end - Offset(math.cos(angle + arrowAngle), math.sin(angle + arrowAngle)) * arrowLength;

    if (filled) {
      final fillPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close(),
        fillPaint,
      );
    } else {
      canvas.drawLine(end, p1, paint);
      canvas.drawLine(end, p2, paint);
    }
  }

  void _drawScreenBar(Canvas canvas, Offset start, Offset end, Paint paint) {
    final direction = end - start;
    if (direction.distance == 0) return;
    final angle = math.atan2(direction.dy, direction.dx);
    const barHalfLength = 8.0;
    final perpendicular = Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2)) * barHalfLength;
    canvas.drawLine(end - perpendicular, end + perpendicular, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 5.0;
    final total = (end - start).distance;
    if (total == 0) return;
    final direction = (end - start) / total;
    var covered = 0.0;
    while (covered < total) {
      final segmentEnd = math.min(covered + dashLength, total);
      canvas.drawLine(start + direction * covered, start + direction * segmentEnd, paint);
      covered += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant BasketballPathsPainter oldDelegate) {
    return oldDelegate.paths != paths || oldDelegate.preview != preview;
  }
}
