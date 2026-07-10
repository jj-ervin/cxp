/// Prototype-scoped version of the `PlayFrame` shape defined in
/// `docs/architecture/domain-model.md`. Sport-neutral: this file has no
/// basketball-specific logic — that lives in the basketball sport pack
/// (see `docs/architecture/plugin-architecture.md`).
library;

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
