import 'package:flutter/material.dart';

import '../../models/play_frame.dart';
import 'animation_perf_spike_screen.dart';
import 'basketball_court_painter.dart';

enum _EditorMode { select, draw }

/// CXP.04/CXP.06 — basketball court editor prototype.
///
/// CXP.04 scope: drag-and-drop players on a single frame (select/move).
/// CXP.06 adds route drawing (pass/dribble/cut/screen/shot/defense) as a
/// distinct **mode**, not a gesture disambiguated on the same tokens —
/// `docs/architecture/ux-philosophy.md` flags select-vs-move-vs-draw as
/// the hardest interaction problem in this editor; a mode toggle (the
/// same pattern most pro diagram tools use — a "select tool" vs. a "pen
/// tool") is the deliberately simple first answer, not the final one.
/// Still no multi-frame animation, save, or export.
class CourtEditorScreen extends StatefulWidget {
  const CourtEditorScreen({super.key});

  @override
  State<CourtEditorScreen> createState() => _CourtEditorScreenState();
}

class _CourtEditorScreenState extends State<CourtEditorScreen> {
  late List<CourtActor> _actors = defaultBasketballFrame();
  String? _selectedActorId;

  _EditorMode _mode = _EditorMode.select;
  PathType _drawPathType = PathType.pass;
  final List<ActorPath> _paths = [];

  String? _dragStartActorId;
  List<Offset> _previewPoints = const [];

  void _onPanUpdate(String actorId, DragUpdateDetails details, Size courtSize) {
    setState(() {
      _actors = [
        for (final actor in _actors)
          if (actor.id == actorId)
            actor.copyWith(
              x: (actor.x + details.delta.dx / courtSize.width).clamp(0.0, 1.0),
              y: (actor.y + details.delta.dy / courtSize.height).clamp(0.0, 1.0),
            )
          else
            actor,
      ];
    });
  }

  void _onTapActor(String actorId) {
    setState(() {
      _selectedActorId = _selectedActorId == actorId ? null : actorId;
    });
  }

  void _reset() {
    setState(() {
      _actors = defaultBasketballFrame();
      _selectedActorId = null;
      _paths.clear();
      _previewPoints = const [];
      _dragStartActorId = null;
    });
  }

  void _undoLastPath() {
    if (_paths.isEmpty) return;
    setState(() => _paths.removeLast());
  }

  CourtActor? _nearestActor(Offset fractionalPoint, {double thresholdFraction = 0.08}) {
    CourtActor? nearest;
    var bestDistance = double.infinity;
    for (final actor in _actors) {
      final distance = (Offset(actor.x, actor.y) - fractionalPoint).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = actor;
      }
    }
    return bestDistance <= thresholdFraction ? nearest : null;
  }

  void _onDrawPanStart(DragStartDetails details, Size courtSize) {
    final fractional = Offset(
      details.localPosition.dx / courtSize.width,
      details.localPosition.dy / courtSize.height,
    );
    final startActor = _nearestActor(fractional);
    if (startActor == null) return;
    setState(() {
      _dragStartActorId = startActor.id;
      _previewPoints = [Offset(startActor.x, startActor.y), fractional];
    });
  }

  void _onDrawPanUpdate(DragUpdateDetails details, Size courtSize) {
    if (_dragStartActorId == null) return;
    final fractional = Offset(
      details.localPosition.dx / courtSize.width,
      details.localPosition.dy / courtSize.height,
    );
    setState(() {
      _previewPoints = [_previewPoints.first, fractional];
    });
  }

  void _onDrawPanEnd(DragEndDetails details) {
    if (_dragStartActorId == null || _previewPoints.length < 2) {
      setState(() {
        _dragStartActorId = null;
        _previewPoints = const [];
      });
      return;
    }
    final start = _previewPoints.first;
    final end = _previewPoints.last;
    if ((end - start).distance > 0.02) {
      setState(() {
        _paths.add(ActorPath(actorId: _dragStartActorId!, type: _drawPathType, points: [start, end]));
      });
    }
    setState(() {
      _dragStartActorId = null;
      _previewPoints = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDrawMode = _mode == _EditorMode.draw;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Editor — prototype'),
        actions: [
          IconButton(
            onPressed: _paths.isEmpty ? null : _undoLastPath,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last path',
          ),
          IconButton(onPressed: _reset, icon: const Icon(Icons.restart_alt), tooltip: 'Reset'),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnimationPerfSpikeScreen()),
            ),
            icon: const Icon(Icons.speed),
            tooltip: 'Animation perf spike (CXP.03)',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<_EditorMode>(
                  segments: const [
                    ButtonSegment(value: _EditorMode.select, label: Text('Select/Move'), icon: Icon(Icons.pan_tool_alt)),
                    ButtonSegment(value: _EditorMode.draw, label: Text('Draw Route'), icon: Icon(Icons.timeline)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => setState(() => _mode = selection.first),
                ),
                if (isDrawMode)
                  DropdownButton<PathType>(
                    value: _drawPathType,
                    items: [
                      for (final type in PathType.values)
                        DropdownMenuItem(value: type, child: Text(type.name)),
                    ],
                    onChanged: (type) {
                      if (type != null) setState(() => _drawPathType = type);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AspectRatio(
                  aspectRatio: 0.94, // roughly a basketball half-court's proportions
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final courtSize = Size(constraints.maxWidth, constraints.maxHeight);
                      final preview = _dragStartActorId == null
                          ? null
                          : ActorPath(actorId: _dragStartActorId!, type: _drawPathType, points: _previewPoints);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: const BasketballCourtPainter()),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BasketballPathsPainter(paths: _paths, preview: preview),
                            ),
                          ),
                          if (isDrawMode)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) => _onDrawPanStart(details, courtSize),
                                onPanUpdate: (details) => _onDrawPanUpdate(details, courtSize),
                                onPanEnd: _onDrawPanEnd,
                              ),
                            ),
                          for (final actor in _actors)
                            _ActorToken(
                              actor: actor,
                              courtSize: courtSize,
                              selected: actor.id == _selectedActorId,
                              ignoring: isDrawMode,
                              onTap: () => _onTapActor(actor.id),
                              onPanUpdate: (details) => _onPanUpdate(actor.id, details, courtSize),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActorToken extends StatelessWidget {
  const _ActorToken({
    required this.actor,
    required this.courtSize,
    required this.selected,
    required this.onTap,
    required this.onPanUpdate,
    this.ignoring = false,
  });

  final CourtActor actor;
  final Size courtSize;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  /// True while the editor is in Draw Route mode — the token must not
  /// intercept the full-canvas route-drawing gesture. `Positioned` must
  /// stay the direct `Stack` child, so this wraps the `GestureDetector`
  /// inside, not the `Positioned` itself.
  final bool ignoring;

  static const double _tokenSize = 36;

  @override
  Widget build(BuildContext context) {
    final isOffense = actor.side == ActorSide.offense;
    return Positioned(
      left: actor.x * courtSize.width - _tokenSize / 2,
      top: actor.y * courtSize.height - _tokenSize / 2,
      child: IgnorePointer(
        ignoring: ignoring,
        child: GestureDetector(
          onTap: onTap,
          onPanUpdate: onPanUpdate,
          child: Container(
            width: _tokenSize,
            height: _tokenSize,
            decoration: BoxDecoration(
              shape: isOffense ? BoxShape.circle : BoxShape.rectangle,
              color: isOffense ? Colors.blue.shade700 : Colors.red.shade700,
              border: selected ? Border.all(color: Colors.yellowAccent, width: 3) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              actor.label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
