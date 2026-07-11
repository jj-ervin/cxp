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

enum _EditorMode { select, draw }

/// CXP.04/CXP.06/CXP.07/CXP.15 — basketball court editor prototype.
///
/// CXP.04: drag-and-drop players on a single frame (select/move).
/// CXP.06: route drawing (pass/dribble/cut/screen/shot/defense) as a
/// distinct **mode**, not a gesture disambiguated on the same tokens —
/// `docs/architecture/ux-philosophy.md` flags select-vs-move-vs-draw as
/// the hardest interaction problem in this editor; a mode toggle (the
/// same pattern most pro diagram tools use — a "select tool" vs. a "pen
/// tool") is the deliberately simple first answer, not the final one.
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
/// previously saved play. No export yet (CXP.16).
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
  _EditorMode _mode = _EditorMode.select;
  PathType _drawPathType = PathType.pass;

  String? _dragStartActorId;
  List<Offset> _previewPoints = const [];

  String? _currentPlayId;
  String _currentPlayName = 'Untitled Play';

  List<CourtActor> get _actors => _frames[_currentFrameIndex].actors;
  List<ActorPath> get _paths => _frames[_currentFrameIndex].paths;

  void _updateCurrentFrame(PlayFrameData Function(PlayFrameData frame) update) {
    setState(() {
      _frames = [
        for (var i = 0; i < _frames.length; i++)
          if (i == _currentFrameIndex) update(_frames[i]) else _frames[i],
      ];
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
    setState(() {
      _selectedActorId = _selectedActorId == actorId ? null : actorId;
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

  void _addFrame() {
    setState(() {
      final duplicated = PlayFrameData(actors: _actors);
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
    final isDrawMode = _mode == _EditorMode.draw;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
