import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../data/play_repository.dart';
import '../../export/playbook_pdf_exporter.dart';
import '../../models/play_frame.dart';
import '../../models/saved_play.dart';
import 'animation_perf_spike_screen.dart';
import 'basketball_court_painter.dart';
import 'frame_playback_screen.dart';
import 'play_library_screen.dart';

/// A tool in the persistent side rail — the select/move arrow plus one
/// tool per `PathType`. Replaces the earlier Select/Move-vs-Draw-Route
/// segmented toggle + separate path-type dropdown (CXP.06) after direct
/// coach feedback: "used to Photoshop/LibreCAD, a sidebar of tools that
/// knows what you're doing" — clicking a tool both switches mode *and*
/// picks what it draws, one action instead of two. See `DEV-PATH.md`'s
/// CXP.20 entry.
enum _Tool { select, ball, pass, dribble, cut, screen, shot, defense }

extension on _Tool {
  /// Null for `select` and `ball` — neither draws a path. `ball` is a
  /// tap-to-assign tool (see `_setBallHolder`), not a draw tool, so it's
  /// deliberately excluded from `_isDrawMode`'s definition even though it
  /// isn't `select` either.
  PathType? get pathType {
    switch (this) {
      case _Tool.select:
      case _Tool.ball:
        return null;
      case _Tool.pass:
        return PathType.pass;
      case _Tool.dribble:
        return PathType.dribble;
      case _Tool.cut:
        return PathType.cut;
      case _Tool.screen:
        return PathType.screen;
      case _Tool.shot:
        return PathType.shot;
      case _Tool.defense:
        return PathType.defense;
    }
  }

  IconData get icon {
    switch (this) {
      case _Tool.select:
        return Icons.pan_tool_alt;
      case _Tool.ball:
        return Icons.sports_basketball;
      case _Tool.pass:
        return Icons.arrow_forward;
      case _Tool.dribble:
        return Icons.gesture;
      case _Tool.cut:
        return Icons.trending_up;
      case _Tool.screen:
        return Icons.block;
      case _Tool.shot:
        return Icons.adjust;
      case _Tool.defense:
        return Icons.shield_outlined;
    }
  }

  String get label {
    switch (this) {
      case _Tool.select:
        return 'Select / Move';
      case _Tool.ball:
        return 'Ball';
      case _Tool.pass:
        return 'Pass';
      case _Tool.dribble:
        return 'Dribble';
      case _Tool.cut:
        return 'Cut';
      case _Tool.screen:
        return 'Screen';
      case _Tool.shot:
        return 'Shot';
      case _Tool.defense:
        return 'Defense';
    }
  }
}

/// CXP.04/CXP.06/CXP.07/CXP.15/CXP.16/CXP.20 — basketball court editor
/// prototype.
///
/// CXP.04: drag-and-drop players on a single frame (select/move).
/// CXP.06/CXP.20: route drawing (pass/dribble/cut/screen/shot/defense) via
/// a persistent tool rail (see `_Tool` above) — `docs/architecture/
/// ux-philosophy.md` flags select-vs-move-vs-draw as the hardest
/// interaction problem in this editor; a tool palette (the same pattern
/// Photoshop/Illustrator/LibreCAD use) is the current answer, not
/// necessarily the final one.
/// CXP.07: multiple frames. Adding a frame duplicates the current frame's
/// actor positions (a coach places players, adds a frame, moves them) but
/// *not* its drawn paths — paths are per-frame coaching annotations, not
/// carried motion (see `PlayFrameData`'s doc comment in `play_frame.dart`).
/// "Play" pushes `FramePlaybackScreen`, which interpolates actor motion
/// between frames using the same `actorsAtSequenceProgress` helper the
/// CXP.03 perf spike uses.
/// CXP.15: local persistence via `PlayRepository` — Save writes the
/// current frames under the play's id (new id if this is a fresh play);
/// the library icon opens `PlayLibraryScreen` to load or delete a
/// previously saved play.
/// CXP.16: PDF playbook export via `Printing.layoutPdf`.
class CourtEditorScreen extends StatefulWidget {
  const CourtEditorScreen({super.key, PlayRepository? repository})
    : repository = repository ?? const _DefaultRepository();

  final PlayRepository repository;

  @override
  State<CourtEditorScreen> createState() => _CourtEditorScreenState();
}

/// Lazily constructs the real `SharedPreferencesPlayRepository` only when
/// no repository is injected — keeps widget tests free to inject an
/// in-memory fake without touching platform channels.
class _DefaultRepository implements PlayRepository {
  const _DefaultRepository();

  static final _delegate = SharedPreferencesPlayRepository();

  @override
  Future<void> delete(String id) => _delegate.delete(id);

  @override
  Future<List<SavedPlay>> loadAll() => _delegate.loadAll();

  @override
  Future<void> save(SavedPlay play) => _delegate.save(play);
}

class _CourtEditorScreenState extends State<CourtEditorScreen> {
  late List<PlayFrameData> _frames = defaultPlayFrames();
  int _currentFrameIndex = 0;

  String? _selectedActorId;
  _Tool _activeTool = _Tool.select;

  String? _dragStartActorId;
  List<Offset> _previewPoints = const [];

  String? _currentPlayId;
  String _currentPlayName = 'Untitled Play';

  bool get _isDrawMode => _activeTool.pathType != null;
  bool get _isBallTool => _activeTool == _Tool.ball;
  PathType get _drawPathType => _activeTool.pathType ?? PathType.pass;

  List<CourtActor> get _actors => _frames[_currentFrameIndex].actors;
  List<ActorPath> get _paths => _frames[_currentFrameIndex].paths;
  String? get _ballHolderId => _frames[_currentFrameIndex].ballHolderId;

  void _updateCurrentFrame(PlayFrameData Function(PlayFrameData frame) update) {
    setState(() {
      _frames = [
        for (var i = 0; i < _frames.length; i++)
          if (i == _currentFrameIndex) update(_frames[i]) else _frames[i],
      ];
    });
  }

  void _selectTool(_Tool tool) {
    setState(() {
      _activeTool = tool;
      _dragStartActorId = null;
      _previewPoints = const [];
    });
  }

  void _onPanUpdate(String actorId, DragUpdateDetails details, Size courtSize) {
    _updateCurrentFrame((frame) {
      return frame.copyWith(
        actors: [
          for (final actor in frame.actors)
            if (actor.id == actorId)
              actor.copyWith(
                x: (actor.x + details.delta.dx / courtSize.width).clamp(0.0, 1.0),
                y: (actor.y + details.delta.dy / courtSize.height).clamp(0.0, 1.0),
              )
            else
              actor,
        ],
      );
    });
  }

  void _onTapActor(String actorId) {
    if (_isBallTool) {
      _setBallHolder(actorId);
      return;
    }
    setState(() {
      _selectedActorId = _selectedActorId == actorId ? null : actorId;
    });
  }

  /// Tap a player with the Ball tool active to give them the ball;
  /// tapping the current holder again clears it. One designated holder
  /// per frame — matches how a coach actually diagrams it, not a
  /// free-floating ball position (see `PlayFrameData.ballHolderId`).
  void _setBallHolder(String actorId) {
    _updateCurrentFrame((frame) {
      return frame.copyWith(ballHolderId: frame.ballHolderId == actorId ? null : actorId);
    });
  }

  void _reset() {
    setState(() {
      _frames = defaultPlayFrames();
      _currentFrameIndex = 0;
      _selectedActorId = null;
      _previewPoints = const [];
      _dragStartActorId = null;
      // A reset play is a fresh, unsaved play — not a return to whatever
      // was last loaded/saved, so Save should create a new record rather
      // than silently overwrite the play this session started from.
      _currentPlayId = null;
      _currentPlayName = 'Untitled Play';
    });
  }

  Future<void> _saveCurrentPlay() async {
    final nameController = TextEditingController(text: _currentPlayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save play'),
        content: TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Play name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final play = SavedPlay(
      id: _currentPlayId ?? generateLocalPlayId(),
      name: name,
      frames: _frames,
      createdAt: DateTime.now(),
    );
    await widget.repository.save(play);
    if (!mounted) return;
    setState(() {
      _currentPlayId = play.id;
      _currentPlayName = play.name;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "${play.name}"')));
  }

  Future<void> _openLibrary() async {
    final selected = await Navigator.of(context).push<SavedPlay>(
      MaterialPageRoute(builder: (_) => PlayLibraryScreen(repository: widget.repository)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _frames = selected.frames;
      _currentFrameIndex = 0;
      _currentPlayId = selected.id;
      _currentPlayName = selected.name;
      _selectedActorId = null;
      _dragStartActorId = null;
      _previewPoints = const [];
    });
  }

  void _undoLastPath() {
    if (_paths.isEmpty) return;
    _updateCurrentFrame((frame) => frame.copyWith(paths: frame.paths.sublist(0, frame.paths.length - 1)));
  }

  /// CXP.16. Builds the PDF in pure Dart (unit-tested directly in
  /// `test/widget_test.dart` with no platform dependency), then hands the
  /// bytes to `Printing.layoutPdf`, which owns the actual save/share/print
  /// UX per-platform (including a browser download on web) — this widget
  /// does not implement per-platform file I/O itself.
  Future<void> _exportPdf() async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPlaybookPdf(playName: _currentPlayName, frames: _frames),
    );
  }

  /// CXP.21 (real coach feedback): if an actor has a drawn path in the
  /// current frame (a cut, a screen, a drive), the *next* frame should
  /// start them at the path's endpoint, not their pre-move position —
  /// otherwise the coach has to re-drag every player to match the arrow
  /// they just drew, which is exactly backwards. An actor with no drawn
  /// path keeps their current position unchanged, same as before.
  CourtActor _advanceToPathEnd(CourtActor actor, List<ActorPath> paths) {
    ActorPath? lastPath;
    for (final path in paths) {
      if (path.actorId == actor.id) lastPath = path;
    }
    if (lastPath == null || lastPath.points.isEmpty) return actor;
    final destination = lastPath.points.last;
    return actor.copyWith(x: destination.dx, y: destination.dy);
  }

  void _addFrame() {
    setState(() {
      final currentFrame = _frames[_currentFrameIndex];
      final advancedActors = [
        for (final actor in currentFrame.actors) _advanceToPathEnd(actor, currentFrame.paths),
      ];
      final advancedBallHolder = _advanceBallHolder(currentFrame.ballHolderId, currentFrame.paths, currentFrame.actors);
      final duplicated = PlayFrameData(actors: advancedActors, ballHolderId: advancedBallHolder);
      _frames = [
        ..._frames.sublist(0, _currentFrameIndex + 1),
        duplicated,
        ..._frames.sublist(_currentFrameIndex + 1),
      ];
      _currentFrameIndex += 1;
      _selectedActorId = null;
    });
  }

  void _deleteCurrentFrame() {
    if (_frames.length < 2) return;
    setState(() {
      _frames = [
        for (var i = 0; i < _frames.length; i++)
          if (i != _currentFrameIndex) _frames[i],
      ];
      _currentFrameIndex = _currentFrameIndex.clamp(0, _frames.length - 1);
      _selectedActorId = null;
    });
  }

  void _selectFrame(int index) {
    setState(() {
      _currentFrameIndex = index;
      _selectedActorId = null;
      _dragStartActorId = null;
      _previewPoints = const [];
    });
  }

  CourtActor? _nearestActor(Offset fractionalPoint, {double thresholdFraction = 0.08, List<CourtActor>? among}) {
    CourtActor? nearest;
    var bestDistance = double.infinity;
    for (final actor in among ?? _actors) {
      final distance = (Offset(actor.x, actor.y) - fractionalPoint).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = actor;
      }
    }
    return bestDistance <= thresholdFraction ? nearest : null;
  }

  /// If the current ball holder has a `pass` among their drawn paths in
  /// this frame, the ball follows that pass into the next frame — a coach
  /// can draw both a pass *and* a cut for the same player in one frame
  /// (pass the ball, then relocate), and the ball must still transfer
  /// even though the cut, not the pass, determines where that player
  /// physically ends up (see `_advanceToPathEnd`).
  ///
  /// A real bug this fixes: the first version only looked at whichever
  /// path was *drawn last* for that player, so "pass then cut" silently
  /// lost the pass — the cut overwrote it and the ball behaved as if the
  /// player had dribbled, not passed. This searches **all** of the
  /// holder's paths for a pass, independent of which one determines
  /// position. If none of their paths is a pass, the same player carries
  /// the ball forward (dribble/cut/screen/shot/defense, or no path at
  /// all).
  ///
  /// Deliberately searches `originalActors` (pre-`_advanceToPathEnd`
  /// positions), not the advanced ones, and excludes the passer: a passer
  /// who also cuts to a new spot gets advanced to their own path's
  /// endpoint by `_advanceToPathEnd`, which can land them almost exactly
  /// on top of the actual receiver — searching the advanced list let the
  /// passer match themself as "nearest" and the ball never transferred.
  /// The receiver is whoever was standing near the pass's landing spot
  /// *at the time of the pass*, not wherever players end up after
  /// everyone's own paths are applied.
  String? _advanceBallHolder(String? currentHolderId, List<ActorPath> paths, List<CourtActor> originalActors) {
    if (currentHolderId == null) return null;
    ActorPath? passPath;
    for (final path in paths) {
      if (path.actorId == currentHolderId && path.type == PathType.pass) passPath = path;
    }
    if (passPath == null || passPath.points.isEmpty) {
      return currentHolderId;
    }
    final candidates = originalActors.where((a) => a.id != currentHolderId).toList();
    final receiver = _nearestActor(passPath.points.last, thresholdFraction: 0.1, among: candidates);
    return receiver?.id ?? currentHolderId;
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
    final startActorId = _dragStartActorId;
    if (startActorId == null || _previewPoints.length < 2) {
      setState(() {
        _dragStartActorId = null;
        _previewPoints = const [];
      });
      return;
    }
    final start = _previewPoints.first;
    final end = _previewPoints.last;
    if ((end - start).distance > 0.02) {
      final newPath = ActorPath(actorId: startActorId, type: _drawPathType, points: [start, end]);
      _updateCurrentFrame((frame) => frame.copyWith(paths: [...frame.paths, newPath]));
    }
    setState(() {
      _dragStartActorId = null;
      _previewPoints = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlayName),
        actions: [
          IconButton(
            onPressed: _openLibrary,
            icon: const Icon(Icons.folder_open),
            tooltip: 'My Plays',
          ),
          IconButton(
            onPressed: _saveCurrentPlay,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save play',
          ),
          IconButton(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF playbook',
          ),
          IconButton(
            onPressed: _paths.isEmpty ? null : _undoLastPath,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last path',
          ),
          IconButton(onPressed: _reset, icon: const Icon(Icons.restart_alt), tooltip: 'Reset'),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FramePlaybackScreen(frames: [for (final f in _frames) f.actors]),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play sequence (CXP.07)',
          ),
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
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _frames.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ChoiceChip(
                          label: Text('Frame ${index + 1}'),
                          selected: index == _currentFrameIndex,
                          onSelected: (_) => _selectFrame(index),
                        );
                      },
                    ),
                  ),
                ),
                IconButton(onPressed: _addFrame, icon: const Icon(Icons.add_box), tooltip: 'Add frame'),
                IconButton(
                  onPressed: _frames.length < 2 ? null : _deleteCurrentFrame,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete current frame',
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ToolRail(activeTool: _activeTool, onToolSelected: _selectTool),
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
                                if (_isDrawMode)
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
                                    hasBall: actor.id == _ballHolderId,
                                    ignoring: _isDrawMode,
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
          ),
        ],
      ),
    );
  }
}

/// Persistent tool palette — Photoshop/Illustrator/LibreCAD-style, per
/// direct coach feedback (see `DEV-PATH.md` CXP.20). Each tool button both
/// switches the active tool and (for draw tools) picks the path type in
/// one click, instead of a mode toggle plus a separate dropdown.
class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.activeTool, required this.onToolSelected});

  final _Tool activeTool;
  final ValueChanged<_Tool> onToolSelected;

  static const _drawTools = [
    _Tool.pass,
    _Tool.dribble,
    _Tool.cut,
    _Tool.screen,
    _Tool.shot,
    _Tool.defense,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _ToolButton(tool: _Tool.select, active: activeTool == _Tool.select, onSelected: onToolSelected),
            _ToolButton(tool: _Tool.ball, active: activeTool == _Tool.ball, onSelected: onToolSelected),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
            for (final tool in _drawTools)
              _ToolButton(tool: tool, active: activeTool == tool, onSelected: onToolSelected),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.tool, required this.active, required this.onSelected});

  final _Tool tool;
  final bool active;
  final ValueChanged<_Tool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tool.label,
        child: InkWell(
          onTap: () => onSelected(tool),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(tool.icon, color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
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
    this.ignoring = false,
    this.hasBall = false,
  });

  final CourtActor actor;
  final Size courtSize;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  /// True while a draw tool is active — the token must not intercept the
  /// full-canvas route-drawing gesture. `Positioned` must stay the direct
  /// `Stack` child, so this wraps the `GestureDetector` inside, not the
  /// `Positioned` itself.
  final bool ignoring;

  /// Renders a small basketball badge on the token — see
  /// `PlayFrameData.ballHolderId`.
  final bool hasBall;

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
          child: SizedBox(
            width: _tokenSize,
            height: _tokenSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                if (hasBall)
                  Positioned(
                    key: ValueKey('ball-badge-${actor.id}'),
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.shade800,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
