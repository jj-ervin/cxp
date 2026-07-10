# CXP.03 — CustomPainter Performance Spike

**Status:** functional spike complete; real-device profiling still outstanding
**Updated:** 2026-07-10

---

## Question being probed

`CXP-OVERVIEW.md`'s Open Questions flagged: does Flutter's `CustomPainter`
hold up for animated multi-frame plays with many simultaneous paths, or
does the court editor need a different rendering approach before v0.1?

## What was built

- `lib/models/play_frame.dart`: `lerpFrame()` (linear interpolation
  between two frames sharing the same actor ids/order) and
  `stressTestFrames()` (generates N frames that reshuffle all 10 actors'
  positions — the worst case for this prototype, since every actor moves
  every tick rather than a more realistic mostly-static play).
- `lib/features/court_editor/animation_perf_spike_screen.dart`: an
  `AnimationController`-driven screen that continuously interpolates
  across the generated frames and repaints a `CustomPainter`
  (`shouldRepaint` hardcoded to `true` — the worst case, no repaint
  skipping) drawing the court, 10 actor tokens, and a trailing line
  segment per actor (standing in for a drawn route, since CXP.06 doesn't
  exist yet). Reachable from the court editor via the speed icon in the
  app bar.
- A `SchedulerBinding.addTimingsCallback` hook reads real
  `FrameTiming.totalSpan` values from the running session and displays
  sampled/last/worst frame time on screen — this is genuine timing data
  from whatever session it's running in, not a hardcoded number.

## What this validated

- The interpolation + repaint approach runs without throwing across
  repeated animation cycles (`flutter test` pumps 30 ticks in
  `test/widget_test.dart` and asserts no exception).
- The rendering approach composes cleanly: the stress painter delegates
  to `BasketballCourtPainter` and layers actor/route drawing on top,
  confirming the core-engine/sport-pack painter separation from
  `plugin-architecture.md` doesn't fight the animation model.
- `flutter analyze` and `flutter test` are clean with this code in the
  tree.

## What this did NOT validate

This is the important part, and the reason CXP.03 is not being marked
fully resolved:

- **No release-mode build was profiled.** Everything above ran in this
  development environment via `flutter test`, which uses a software
  renderer / test harness, not a real GPU compositor pipeline. Frame
  timings collected this way are not representative of real device
  performance.
- **No real device was used.** No phone, tablet, or the actual target
  hardware (whatever a coach would realistically use courtside) has run
  this build. Windows desktop testing wasn't available either (Visual
  Studio's C++ workload isn't installed on this machine — see
  `DEV-PATH.md` Phase 2).
- **The stress scenario is synthetic**, not drawn from a real play. Real
  plays likely have fewer simultaneously-moving actors and shorter path
  segments than this worst-case generator produces. This spike
  deliberately tested a harder case than expected production use, which
  is useful for a lower bound but doesn't say what a *typical* play costs.
- **No comparison rendering approach was tried** (e.g. `flutter_scene`,
  a lower-level canvas API, or precomputed sprite batching) — this spike
  only asks "does the obvious approach work," not "is it the best
  approach."

## Recommendation

Treat this as **passed for continuing basketball-editor development**,
not as **validated for release**. Before v0.1 ships:

1. Run the perf-spike screen in `flutter run --profile` on at least one
   real mid-range Android or iOS device, using Flutter DevTools' frame
   rendering timeline to check for dropped frames (target: no
   consistent frames over ~16ms at 60fps / ~33ms at 30fps).
2. Re-run with a more realistic stress scenario built from an actual
   drawn play (once CXP.06 route drawing exists) rather than the
   synthetic full-reshuffle generator used here.
3. If real-device profiling shows jank, the fallback options — reduce
   simultaneous animated actors, cache static court background as a
   pre-rendered image instead of repainting it every frame, or move to a
   lower-level rendering API — are all compatible with the current
   architecture and don't require a rewrite.

## Related

- `lib/features/court_editor/animation_perf_spike_screen.dart` — the spike itself
- `lib/models/play_frame.dart` — `lerpFrame`, `stressTestFrames`
- `test/widget_test.dart` — functional regression test (not a benchmark)
- `docs/architecture/ux-philosophy.md` — frames + generated transitions
  as the chosen animation model
