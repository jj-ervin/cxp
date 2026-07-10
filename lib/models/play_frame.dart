/// Prototype-scoped version of the `PlayFrame` shape defined in
/// `docs/architecture/domain-model.md`. Sport-neutral: this file has no
/// basketball-specific logic — that lives in the basketball sport pack
/// (see `docs/architecture/plugin-architecture.md`).
library;

import 'dart:ui' show Offset;

enum ActorSide { offense, defense }

class CourtActor {
  const CourtActor({
    required this.id,
    required this.label,
    required this.side,
    required this.x,
    required this.y,
  });

  /// Stable identity within a frame/play — matches `actor_id` in the
  /// domain model's `PlayFrame.positions`.
  final String id;

  /// Sport-pack-defined label (jersey number, position code, etc.).
  final String label;

  final ActorSide side;

  /// Fractional coordinates in `[0.0, 1.0]`, relative to the court
  /// surface — resolution-independent, matches `PlayFrame.positions`
  /// `{ actor_id, x, y }`.
  final double x;
  final double y;

  CourtActor copyWith({double? x, double? y}) {
    return CourtActor(
      id: id,
      label: label,
      side: side,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

/// Basketball sport pack validation rule (see plugin-architecture.md):
/// exactly 5 offense + 5 defense actors, unless explicitly overridden for
/// a drill.
List<CourtActor> defaultBasketballFrame() {
  final offense = List.generate(5, (i) {
    return CourtActor(
      id: 'off_$i',
      label: '${i + 1}',
      side: ActorSide.offense,
      x: 0.3 + (i % 3) * 0.2,
      y: 0.25 + (i ~/ 3) * 0.35,
    );
  });
  final defense = List.generate(5, (i) {
    return CourtActor(
      id: 'def_$i',
      label: 'X${i + 1}',
      side: ActorSide.defense,
      x: 0.32 + (i % 3) * 0.2,
      y: 0.3 + (i ~/ 3) * 0.35,
    );
  });
  return [...offense, ...defense];
}

/// Linear interpolation between two frames holding the same actor ids in
/// the same order. This is the "frames + generated transitions" animation
/// model chosen in `docs/architecture/ux-philosophy.md` over full
/// timeline keyframing — the coach places frames, the engine generates
/// the motion between them.
List<CourtActor> lerpFrame(List<CourtActor> a, List<CourtActor> b, double t) {
  assert(a.length == b.length, 'lerpFrame requires frames with matching actor lists');
  return [
    for (var i = 0; i < a.length; i++)
      a[i].copyWith(
        x: a[i].x + (b[i].x - a[i].x) * t,
        y: a[i].y + (b[i].y - a[i].y) * t,
      ),
  ];
}

/// Basketball sport pack path types (see plugin-architecture.md's
/// `symbols.path_types`). Curved-vs-straight rendering variants per type
/// are a later refinement — CXP.06's prototype draws every path as a
/// straight segment between two points.
enum PathType { pass, dribble, cut, screen, shot, defense }

/// Sport-neutral shell matching `PlayFrame.paths` in the domain model:
/// `{ actor_id, type, points, style }`. `style` is not a separate field
/// here — the basketball sport pack derives rendering style from [type]
/// (see `basketball_court_painter.dart`'s path-drawing companion).
class ActorPath {
  const ActorPath({required this.actorId, required this.type, required this.points});

  /// The actor this path originates from — matches `CourtActor.id`.
  final String actorId;

  final PathType type;

  /// Fractional coordinates in `[0.0, 1.0]`, same coordinate space as
  /// `CourtActor.x`/`y`. At least 2 points; this prototype only ever
  /// produces exactly 2 (a straight segment), but the shape allows more
  /// for a future curved-path upgrade without a schema change.
  final List<Offset> points;
}

/// CXP.03 perf-spike input: generates [frameCount] frames of the default
/// 5v5 basketball set, each frame reshuffling every actor's position, so
/// the animation has to interpolate all 10 actors simultaneously on every
/// tick — the worst case the spike is meant to probe (see
/// `docs/architecture/perf-spike-cxp03.md` for findings and limitations).
List<List<CourtActor>> stressTestFrames({int frameCount = 4}) {
  final base = defaultBasketballFrame();
  return List.generate(frameCount, (frameIndex) {
    if (frameIndex == 0) return base;
    final phase = frameIndex / frameCount;
    return [
      for (var i = 0; i < base.length; i++)
        base[i].copyWith(
          x: (0.15 + 0.7 * ((i + frameIndex) % base.length) / base.length).clamp(0.05, 0.95),
          y: (0.15 + 0.75 * ((phase + i / base.length) % 1.0)).clamp(0.05, 0.95),
        ),
    ];
  });
}
