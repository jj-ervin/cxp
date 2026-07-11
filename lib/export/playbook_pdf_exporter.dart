import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/play_frame.dart';
import '../models/court_configuration.dart';

/// CXP.16 — the "beautiful PDF playbook export" pillar named in
/// `CXP-OVERVIEW.md`'s v0.1 MVP definition. One page per frame; each page
/// draws the same court/actor/path visual language as the live editor
/// (`basketball_court_painter.dart`), reimplemented against `package:pdf`'s
/// `PdfGraphics` API rather than Flutter's `Canvas` — the two packages
/// don't share a canvas abstraction, so this is a deliberate, bounded
/// duplication, not a reuse failure. Kept intentionally simpler than the
/// live editor's styling (no dashed-line/screen-bar distinction per path
/// type — every path is a solid line with an open arrowhead) — that gap
/// is logged as CXP.19, not silently accepted.
///
/// PNG and SVG export are explicitly out of scope for this pass — see
/// `DEV-PATH.md`'s CXP.16 entry for why, tracked as CXP.18.
Future<Uint8List> buildPlaybookPdf({
  required String playName,
  required List<PlayFrameData> frames,
  CourtConfiguration courtConfiguration = CourtConfiguration.defaultValue,
}) async {
  final doc = pw.Document();
  final aspectRatio = courtConfiguration.dimensions.widthFeet / courtConfiguration.displayedLengthFeet;
  final diagramWidth = math.min(420.0, 600 * aspectRatio);
  final diagramSize = PdfPoint(diagramWidth, diagramWidth / aspectRatio);

  for (var i = 0; i < frames.length; i++) {
    final frame = frames[i];
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(playName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Frame ${i + 1} of ${frames.length}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.SizedBox(
                width: diagramSize.x,
                height: diagramSize.y,
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        size: diagramSize,
                        painter: (canvas, size) => _paintCourtAndPaths(canvas, size, frame, courtConfiguration),
                      ),
                    ),
                    for (final actor in frame.actors)
                      _actorToken(actor, diagramSize, hasBall: actor.id == frame.ballHolderId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return doc.save();
}

pw.Widget _actorToken(CourtActor actor, PdfPoint size, {bool hasBall = false}) {
  const tokenSize = 22.0;
  final isOffense = actor.side == ActorSide.offense;
  return pw.Positioned(
    left: actor.x * size.x - tokenSize / 2,
    top: actor.y * size.y - tokenSize / 2,
    child: pw.Stack(
      children: [
        pw.Container(
          width: tokenSize,
          height: tokenSize,
          decoration: pw.BoxDecoration(
            color: isOffense ? PdfColors.blue700 : PdfColors.red700,
            shape: isOffense ? pw.BoxShape.circle : pw.BoxShape.rectangle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(actor.label, style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
        ),
        if (hasBall)
          pw.Positioned(
            right: -3,
            top: -3,
            child: pw.Container(
              width: 9,
              height: 9,
              decoration: const pw.BoxDecoration(
                color: PdfColors.orange800,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}

void _paintCourtAndPaths(
  PdfGraphics canvas,
  PdfPoint size,
  PlayFrameData frame,
  CourtConfiguration configuration,
) {
  // Court surface + boundary.
  canvas
    ..setColor(
      configuration.surface == CourtSurface.blacktop
          ? const PdfColor.fromInt(0xFF46515A)
          : const PdfColor.fromInt(0xFFDDB27A),
    )
    ..drawRect(0, 0, size.x, size.y)
    ..fillPath()
    ..setColor(PdfColors.black)
    ..setLineWidth(1)
    ..drawRect(1, 1, size.x - 2, size.y - 2)
    ..strokePath();

  final dimensions = configuration.dimensions;
  final xScale = size.x / dimensions.widthFeet;
  final yScale = size.y / configuration.displayedLengthFeet;
  _paintPdfBasketEnd(canvas, size, dimensions, xScale, yScale, baselineAtBottom: true);
  if (configuration.extent == CourtExtent.full) {
    _paintPdfBasketEnd(canvas, size, dimensions, xScale, yScale, baselineAtBottom: false);
    canvas
      ..moveTo(0, size.y / 2)
      ..lineTo(size.x, size.y / 2)
      ..strokePath()
      ..drawEllipse(size.x / 2, size.y / 2, 6 * xScale, 6 * xScale)
      ..strokePath();
  }

  // Paths.
  for (final path in frame.paths) {
    if (path.points.length < 2) continue;
    final start = PdfPoint(path.points.first.dx * size.x, (1 - path.points.first.dy) * size.y);
    final end = PdfPoint(path.points.last.dx * size.x, (1 - path.points.last.dy) * size.y);
    canvas
      ..setColor(_colorFor(path.type))
      ..setLineWidth(1.5);

    if (path.type == PathType.dribble || path.type == PathType.shot || path.type == PathType.defense) {
      _strokeDashedLine(canvas, start, end);
    } else {
      canvas
        ..moveTo(start.x, start.y)
        ..lineTo(end.x, end.y)
        ..strokePath();
    }

    if (path.type == PathType.screen) {
      _strokeScreenBar(canvas, start, end);
    } else if (path.type != PathType.defense) {
      _strokeArrowhead(canvas, start, end);
    }
  }
}

void _paintPdfBasketEnd(
  PdfGraphics canvas,
  PdfPoint size,
  CourtDimensions dimensions,
  double xScale,
  double yScale, {
  required bool baselineAtBottom,
}) {
  double yFromBaseline(double feet) => baselineAtBottom ? feet * yScale : size.y - feet * yScale;
  final laneWidth = dimensions.laneWidthFeet * xScale;
  final laneEnd = yFromBaseline(dimensions.freeThrowLineFeet);
  final laneBottom = math.min(yFromBaseline(0), laneEnd);
  canvas
    ..setColor(PdfColors.black)
    ..drawRect((size.x - laneWidth) / 2, laneBottom, laneWidth, dimensions.freeThrowLineFeet * yScale)
    ..strokePath()
    ..drawEllipse(size.x / 2, laneEnd, 6 * xScale, 6 * xScale)
    ..strokePath();

  final basketY = yFromBaseline(dimensions.basketOffsetFeet);
  canvas
    ..drawEllipse(size.x / 2, basketY, 0.75 * xScale, 0.75 * xScale)
    ..strokePath();

  final radiusX = dimensions.threePointRadiusFeet * xScale;
  final radiusY = dimensions.threePointRadiusFeet * yScale;
  final cornerX = dimensions.cornerThreeDistanceFeet * xScale;
  final leftX = size.x / 2 - cornerX;
  final rightX = size.x / 2 + cornerX;
  final intersection = radiusY * math.sqrt(math.max(0, 1 - cornerX * cornerX / (radiusX * radiusX)));
  final intersectionY = baselineAtBottom ? basketY + intersection : basketY - intersection;
  canvas
    ..moveTo(leftX, yFromBaseline(0))
    ..lineTo(leftX, intersectionY)
    ..moveTo(rightX, yFromBaseline(0))
    ..lineTo(rightX, intersectionY)
    ..strokePath();
  // PdfGraphics has no elliptical-arc primitive; drawEllipse preserves
  // regulation radius and custom-court scaling while corner lines make
  // the selected standard visible in print.
  canvas
    ..drawEllipse(size.x / 2, basketY, radiusX, radiusY)
    ..strokePath();
}

PdfColor _colorFor(PathType type) {
  switch (type) {
    case PathType.pass:
      return PdfColors.black;
    case PathType.cut:
      return PdfColors.green800;
    case PathType.dribble:
      return PdfColors.orange800;
    case PathType.shot:
      return PdfColors.purple800;
    case PathType.screen:
      return PdfColors.brown800;
    case PathType.defense:
      return PdfColors.red800;
  }
}

void _strokeArrowhead(PdfGraphics canvas, PdfPoint start, PdfPoint end) {
  const arrowLength = 8.0;
  const arrowAngle = 0.5;
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  if (dx == 0 && dy == 0) return;
  final angle = math.atan2(dy, dx);

  final p1x = end.x - math.cos(angle - arrowAngle) * arrowLength;
  final p1y = end.y - math.sin(angle - arrowAngle) * arrowLength;
  final p2x = end.x - math.cos(angle + arrowAngle) * arrowLength;
  final p2y = end.y - math.sin(angle + arrowAngle) * arrowLength;

  canvas
    ..moveTo(end.x, end.y)
    ..lineTo(p1x, p1y)
    ..moveTo(end.x, end.y)
    ..lineTo(p2x, p2y)
    ..strokePath();
}

void _strokeScreenBar(PdfGraphics canvas, PdfPoint start, PdfPoint end) {
  const barHalfLength = 6.0;
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  if (dx == 0 && dy == 0) return;
  final angle = math.atan2(dy, dx);
  final perpX = math.cos(angle + math.pi / 2) * barHalfLength;
  final perpY = math.sin(angle + math.pi / 2) * barHalfLength;

  canvas
    ..moveTo(end.x - perpX, end.y - perpY)
    ..lineTo(end.x + perpX, end.y + perpY)
    ..strokePath();
}

void _strokeDashedLine(PdfGraphics canvas, PdfPoint start, PdfPoint end) {
  const dashLength = 5.0;
  const gapLength = 4.0;
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final total = math.sqrt(dx * dx + dy * dy);
  if (total == 0) return;
  final ux = dx / total;
  final uy = dy / total;
  var covered = 0.0;
  while (covered < total) {
    final segmentEnd = covered + dashLength > total ? total : covered + dashLength;
    canvas
      ..moveTo(start.x + ux * covered, start.y + uy * covered)
      ..lineTo(start.x + ux * segmentEnd, start.y + uy * segmentEnd)
      ..strokePath();
    covered += dashLength + gapLength;
  }
}
