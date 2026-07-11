import 'package:flutter/material.dart';

import '../../models/play_frame.dart';
import '../../models/court_configuration.dart';
import 'basketball_court_painter.dart';

/// CXP.07 — plays back a real play's frames (actor motion only; drawn
/// paths are per-frame coaching annotations, not animated — see
/// `PlayFrameData`'s doc comment). Unlike the CXP.03 perf spike, this
/// runs the sequence once (play/pause/restart), not an infinite
/// stress loop, and has no timing instrumentation.
class FramePlaybackScreen extends StatefulWidget {
  const FramePlaybackScreen({
    super.key,
    required this.frames,
    this.secondsPerSegment = 1.2,
    this.courtConfiguration = CourtConfiguration.defaultValue,
  });

  /// Actor positions per frame — `frames[i]` and `frames[i + 1]` must
  /// hold the same actor ids in the same order (see `lerpFrame`).
  final List<List<CourtActor>> frames;
  final double secondsPerSegment;
  final CourtConfiguration courtConfiguration;

  @override
  State<FramePlaybackScreen> createState() => _FramePlaybackScreenState();
}

class _FramePlaybackScreenState extends State<FramePlaybackScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final segmentCount = (widget.frames.length - 1).clamp(1, 1 << 30);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.secondsPerSegment * 1000 * segmentCount).round()),
    );
    if (widget.frames.length > 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play — sequence playback')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AspectRatio(
                  aspectRatio:
                      widget.courtConfiguration.dimensions.widthFeet / widget.courtConfiguration.displayedLengthFeet,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final actors = actorsAtSequenceProgress(widget.frames, _controller.value);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BasketballCourtPainter(configuration: widget.courtConfiguration),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(painter: _PlaybackActorsPainter(actors: actors)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _controller.reset(),
                  icon: const Icon(Icons.replay),
                  tooltip: 'Restart',
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final isPlaying = _controller.isAnimating;
                    return IconButton(
                      onPressed: widget.frames.length < 2
                          ? null
                          : () => isPlaying ? _controller.stop() : _controller.forward(),
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackActorsPainter extends CustomPainter {
  const _PlaybackActorsPainter({required this.actors});

  final List<CourtActor> actors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final actor in actors) {
      final center = Offset(actor.x * size.width, actor.y * size.height);
      final dotPaint = Paint()
        ..color = actor.side == ActorSide.offense ? Colors.blue.shade700 : Colors.red.shade700;
      canvas.drawCircle(center, 14, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlaybackActorsPainter oldDelegate) => oldDelegate.actors != actors;
}
