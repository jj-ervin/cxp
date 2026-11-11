# CXP — Coach Experience Platform

**Status:** basketball coaching prototype — editor, frame actor playback, local play storage and PDF export implemented; no public release.

CXP is proprietary software owned by Osprey Strategic Holdings LLC and developed by HBL Creative Studios. Public repository visibility does not grant reuse rights; see [LICENSE](LICENSE).\n\nCXP is a coaching operations workspace following
the same architectural pattern as this portfolio's DXP work: one core, AI
as an assistant rather than the product, deterministic tools underneath.
Basketball is the first sport.

- [`CXP-OVERVIEW.md`](CXP-OVERVIEW.md) — vision, mission, architecture,
  module map, security/AI/data model, roadmap, MVP, pricing, business
  model, technical stack, Azure architecture, future vision, open
  questions
- [`DEV-PATH.md`](DEV-PATH.md) — phase history and design decisions
- [`DEV-PLAN.md`](DEV-PLAN.md) — current execution state and work queue
- [`DEV-RELEASE.md`](DEV-RELEASE.md) — prototype release posture and open draft criteria
- [`AGENTS.md`](AGENTS.md) — GC agent bootstrap

Governed under this portfolio's `governance-commons/` standards — see
`AGENTS.md` for the reading order.


## Current prototype

The Flutter app opens a coaching home with local teams and player names, a practice planner and drill library, and access to the basketball court editor. The editor with actor dragging, route tools, frame sequencing and ball ownership in the editor. It supports configurable half/full surfaces and saved plays, and can export PDF playbooks. Playback animates actor positions; route animation and playback ball ownership are not implemented. Saved plays use a local SharedPreferences JSON list, without server sync, play revision history, account isolation or search/tags/folders.

For source checks, use `flutter pub get --enforce-lockfile`, `flutter analyze --no-pub` and `flutter test --no-pub`. Native plugin setup on Windows requires working symlink support. `flutter build web --no-pub` is a web build check, not native/device/performance or installation proof. Six target scaffolds do not establish six supported releases.

pubspec's 1.0.0+1 is build metadata; the product remains pre-release in planning. Coach retest, real-device profiling, release/installation acceptance and the four draft DEV-RELEASE criteria remain open. Architecture/AI/SKU/backend/game-operation plans are directional scope, not shipped modules.
