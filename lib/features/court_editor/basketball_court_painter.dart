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

    // Key / paint (free-throw lane), centered on the baseline. Real
    // proportions (half-court ~50ft wide x 47ft long): 16ft lane width,
    // ~19ft lane length.
    final laneWidth = size.width * 0.32; // 16/50
    final laneHeight = size.height * 0.40; // 19/47
    final lane = Rect.fromLTWH(
      (size.width - laneWidth) / 2,
      size.height - laneHeight,
      laneWidth,
      laneHeight,
    );
    canvas.drawRect(lane, line);

    // Free-throw circle. Real radius ~6ft on a ~50ft-wide court = 12% of
    // width — deliberately NOT `laneWidth / 2` (that ties the circle to
    // the lane's 16ft width, producing a circle a third too large; a
    // real coach caught this — see DEV-PATH.md CXP.22).
    final ftCenter = Offset(size.width / 2, lane.top);
    final freeThrowRadius = size.width * 0.12;
    canvas.drawCircle(ftCenter, freeThrowRadius, line);

    // Rim, ~5.25ft from the baseline on a 47ft-long half-court.
    final basketCenter = Offset(size.width / 2, size.height - size.height * 0.11);
    canvas.drawCircle(basketCenter, size.width * 0.02, line);

    // Three-point arc. Real radius ~23.75ft on a 50ft-wide court = 47.5%
    // of width. Rather than hand-guessed start/sweep radians (the
    // previous version's actual bug — those two magic numbers didn't
    // correspond to any real geometry), derive the start/sweep angles
    // from where the arc should meet the baseline, so the arc is always
    // geometrically consistent regardless of court aspect ratio.
    final arcRadius = size.width * 0.475;
    final baselineY = size.height * 0.99;
    final verticalReach = (baselineY - basketCenter.dy).clamp(-arcRadius, arcRadius);
    final halfAngleFromBottom = math.asin(verticalReach / arcRadius);
    final startAngle = math.pi / 2 + halfAngleFromBottom; // left baseline intersection
    final sweepAngle = 2 * math.pi - 2 * halfAngleFromBottom; // over the top to the right intersection
    canvas.drawArc(
      Rect.fromCircle(center: basketCenter, radius: arcRadius),
      startAngle,
      sweepAngle,
      false,
      line,
    );
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
