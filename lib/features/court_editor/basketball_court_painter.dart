import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/court_configuration.dart';
import '../../models/play_frame.dart';

/// Basketball sport pack playing surface (half-court, offensive end).
/// Sport-pack-owned per `docs/architecture/plugin-architecture.md` — the
/// editor's core canvas has no opinion on what a "court" looks like.
class BasketballCourtPainter extends CustomPainter {
  const BasketballCourtPainter({this.configuration = CourtConfiguration.defaultValue});

  final CourtConfiguration configuration;

  @override
  void paint(Canvas canvas, Size size) {
    final court = Paint()
      ..color = configuration.surface == CourtSurface.blacktop
          ? const Color(0xFF46515A)
          : const Color(0xFFDDB27A)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Offset.zero & size;
    canvas.drawRect(rect, court);
    canvas.drawRect(rect.deflate(1), line);

    final dimensions = configuration.dimensions;
    final xScale = size.width / dimensions.widthFeet;
    final yScale = size.height / configuration.displayedLengthFeet;

    _drawBasketEnd(canvas, size, line, dimensions, xScale, yScale, baselineAtBottom: true);
    if (configuration.extent == CourtExtent.full) {
      _drawBasketEnd(canvas, size, line, dimensions, xScale, yScale, baselineAtBottom: false);
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6 * xScale, line);
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 6 * xScale),
        0,
        math.pi,
        false,
        line,
      );
    }
  }

  void _drawBasketEnd(
    Canvas canvas,
    Size size,
    Paint line,
    CourtDimensions dimensions,
    double xScale,
    double yScale, {
    required bool baselineAtBottom,
  }) {
    double yFromBaseline(double feet) => baselineAtBottom ? size.height - feet * yScale : feet * yScale;
    final laneWidth = dimensions.laneWidthFeet * xScale;
    final laneEndY = yFromBaseline(dimensions.freeThrowLineFeet);
    final lane = Rect.fromLTRB(
      (size.width - laneWidth) / 2,
      math.min(yFromBaseline(0), laneEndY),
      (size.width + laneWidth) / 2,
      math.max(yFromBaseline(0), laneEndY),
    );
    canvas.drawRect(lane, line);

    final freeThrowCenter = Offset(size.width / 2, laneEndY);
    canvas.drawCircle(freeThrowCenter, 6 * xScale, line);

    final basketCenter = Offset(size.width / 2, yFromBaseline(dimensions.basketOffsetFeet));
    canvas.drawCircle(basketCenter, 0.75 * xScale, line);

    if (dimensions.restrictedArcRadiusFeet > 0) {
      final radius = dimensions.restrictedArcRadiusFeet * xScale;
      canvas.drawArc(
        Rect.fromCircle(center: basketCenter, radius: radius),
        baselineAtBottom ? math.pi : 0,
        math.pi,
        false,
        line,
      );
    }

    final arcRadiusX = dimensions.threePointRadiusFeet * xScale;
    final arcRadiusY = dimensions.threePointRadiusFeet * yScale;
    final cornerX = dimensions.cornerThreeDistanceFeet * xScale;
    final leftCornerX = size.width / 2 - cornerX;
    final rightCornerX = size.width / 2 + cornerX;
    final intersectionAlongY = arcRadiusY * math.sqrt(math.max(0, 1 - (cornerX * cornerX) / (arcRadiusX * arcRadiusX)));
    final intersectionY = baselineAtBottom ? basketCenter.dy - intersectionAlongY : basketCenter.dy + intersectionAlongY;
    canvas.drawLine(Offset(leftCornerX, yFromBaseline(0)), Offset(leftCornerX, intersectionY), line);
    canvas.drawLine(Offset(rightCornerX, yFromBaseline(0)), Offset(rightCornerX, intersectionY), line);

    final cornerAngle = math.acos((cornerX / arcRadiusX).clamp(-1.0, 1.0));
    final start = baselineAtBottom ? math.pi + cornerAngle : math.pi - cornerAngle;
    final sweep = math.pi - 2 * cornerAngle;
    canvas.drawArc(
      Rect.fromCenter(center: basketCenter, width: arcRadiusX * 2, height: arcRadiusY * 2),
      start,
      baselineAtBottom ? sweep : -sweep,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant BasketballCourtPainter oldDelegate) => oldDelegate.configuration != configuration;
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
