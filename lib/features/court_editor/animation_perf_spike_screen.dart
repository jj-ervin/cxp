import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import '../../models/play_frame.dart';
import 'basketball_court_painter.dart';

/// CXP.03 — CustomPainter performance spike.
///
/// Continuously interpolates between [frameCount] frames (all 10 actors
/// moving simultaneously every tick, worst case for this prototype) and
/// repaints every animation tick. Also tracks per-frame build/paint cost
/// via `SchedulerBinding.addTimingsCallback` so the on-screen readout
/// reflects real frame timings from this session — not a canned number.
///
/// **What this validates:** the interaction/rendering approach doesn't
/// throw, doesn't visibly stutter in a debug session, and produces frame
/// timings this app can read.
/// **What this does NOT validate:** true device performance. This has
/// only been run in a debug/test harness in this environment, not
/// profiled on a real phone/tablet in release mode. See
/// `docs/architecture/perf-spike-cxp03.md` for the full writeup and the
/// concrete follow-up needed before this is trusted for v0.1.
class AnimationPerfSpikeScreen extends StatefulWidget {
  const AnimationPerfSpikeScreen({super.key, this.frameCount = 4, this.secondsPerSegment = 1.2});

  final int frameCount;
  final double secondsPerSegment;

  @override
  State<AnimationPerfSpikeScreen> createState() => _AnimationPerfSpikeScreenState();
}

class _AnimationPerfSpikeScreenState extends State<AnimationPerfSpikeScreen>
    with SingleTickerProviderStateMixin {
  late final List<List<CourtActor>> _frames = stressTestFrames(frameCount: widget.frameCount);
  late final AnimationController _controller;

  double _worstFrameMs = 0;
  double _lastFrameMs = 0;
  int _sampledFrames = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (widget.secondsPerSegment * 1000 * (widget.frameCount - 1)).round(),
      ),
    )..repeat(reverse: true);
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      _lastFrameMs = totalMs;
      if (totalMs > _worstFrameMs) _worstFrameMs = totalMs;
      _sampledFrames++;
    }
    // Throttle setState to avoid the readout itself becoming the bottleneck.
    if (_sampledFrames % 5 == 0) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _controller.dispose();
    super.dispose();
  }

  List<CourtActor> _actorsAt(double progress) {
    final segment = progress * (_frames.length - 1);
    final index = segment.floor().clamp(0, _frames.length - 2);
    final t = segment - index;
    return lerpFrame(_frames[index], _frames[index + 1], t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation perf spike (CXP.03)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sampled frames: $_sampledFrames · last: ${_lastFrameMs.toStringAsFixed(1)}ms '
              '· worst: ${_worstFrameMs.toStringAsFixed(1)}ms\n'
              'Debug-mode session reading only — not a release-mode device profile.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AspectRatio(
                  aspectRatio: 0.94,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final courtSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return CustomPaint(
                            size: courtSize,
                            painter: _StressPainter(actors: _actorsAt(_controller.value)),
                          );
                        },
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

class _StressPainter extends CustomPainter {
  _StressPainter({required this.actors});

  final List<CourtActor> actors;
  static const _courtPainter = BasketballCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _courtPainter.paint(canvas, size);

    final trailPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final actor in actors) {
      final center = Offset(actor.x * size.width, actor.y * size.height);
      // A short trailing segment per actor simulates the paint cost of a
      // drawn route (CXP.06) without depending on that feature existing.
      canvas.drawLine(center.translate(-18, -18), center, trailPaint);
      final dotPaint = Paint()
        ..color = actor.side == ActorSide.offense ? Colors.blue.shade700 : Colors.red.shade700;
      canvas.drawCircle(center, 12, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StressPainter oldDelegate) => true;
}
