import 'package:flutter/material.dart';

import '../../models/play_frame.dart';
import 'basketball_court_painter.dart';

/// CXP.04 — basketball court editor prototype.
///
/// Scope, deliberately narrow: drag-and-drop players on a single frame.
/// No routes, no multi-frame animation, no save/export yet (see
/// `DEV-PLAN.md` priority queue). The point of this prototype is to prove
/// out the select-vs-move interaction discipline flagged as the hardest
/// UX problem in `docs/architecture/ux-philosophy.md` — not to ship a
/// feature-complete editor.
class CourtEditorScreen extends StatefulWidget {
  const CourtEditorScreen({super.key});

  @override
  State<CourtEditorScreen> createState() => _CourtEditorScreenState();
}

class _CourtEditorScreenState extends State<CourtEditorScreen> {
  late List<CourtActor> _actors = defaultBasketballFrame();
  String? _selectedActorId;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Editor — prototype'),
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.restart_alt), tooltip: 'Reset'),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AspectRatio(
            aspectRatio: 0.94, // roughly a basketball half-court's proportions
            child: LayoutBuilder(
              builder: (context, constraints) {
                final courtSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: const BasketballCourtPainter()),
                    ),
                    for (final actor in _actors)
                      _ActorToken(
                        actor: actor,
                        courtSize: courtSize,
                        selected: actor.id == _selectedActorId,
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
  });

  final CourtActor actor;
  final Size courtSize;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  static const double _tokenSize = 36;

  @override
  Widget build(BuildContext context) {
    final isOffense = actor.side == ActorSide.offense;
    return Positioned(
      left: actor.x * courtSize.width - _tokenSize / 2,
      top: actor.y * courtSize.height - _tokenSize / 2,
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
    );
  }
}
