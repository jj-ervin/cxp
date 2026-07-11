# DEV-PATH — CXP (Coach Experience Platform)

**AUTHORITY LEVEL: AL:2**
**Status:** ACTIVE — single authoritative source for CXP development path
**Updated:** 2026-07-10
**Supersedes:** N/A

---

## CANONICAL DOC RULE

`DEV-PATH.md` owns: phase history, design decisions, and task registry.
`DEV-PLAN.md` owns: current execution state, active milestones, release targets.
`DEV-RELEASE.md` owns: what ships, when, and under what conditions.
`CXP-OVERVIEW.md` owns: vision, architecture, module map — directional
scoping capture, not committed engineering scope.

Do not create or revive alternate root files named `devpath`, `DEV-PATH`, etc.

---

## MAINTAINER ONBOARDING — Read this first

Before starting any task in this repo, read in order:

1. `governance-commons/passes/dev-accord/DEV-ACCORD.03.md` — portfolio agent-trail
2. `AGENTS.md` — this repo's GC bootstrap
3. **This file** — current phase, task lineage, and relevant decisions
4. `DEV-PLAN.md` — current execution state
5. `CXP-OVERVIEW.md` — full scoping capture, if architecture context is needed

---

## PHASE HISTORY

### Phase 0 — Scoping (2026-07-10 → ongoing)

**Goal:** Capture a multi-session brainstorming conversation into a durable
planning artifact before any implementation begins. No code, no repo
architecture decisions have been executed yet — this phase exists to
preserve the reasoning, not to commit to it.

**Key decisions:**

- Product is scoped as **CXP — Coach Experience Platform**, following the
  DXP naming pattern (Developer Experience Platform → Coach Experience
  Platform), living under 20Amp Labs.
- Architecture split: **eco.ai** = intelligence/governance layer,
  **Cockpit** = domain-neutral experience shell (must be genericized away
  from developer-specific vocabulary before CXP depends on it),
  **CXP** = the coaching domain itself.
- Basketball is the first sport; the play/practice engine is built
  sport-neutral from the start so football (and later sports) are modules,
  not rewrites.
- eco.ai philosophy for CXP matches the Niji precedent: augment the coach,
  never replace deterministic coaching decisions. AI recommendations
  always show evidence + confidence + require approval before acting.
- MVP framing: basketball-only, offline-first, four things exceptional
  (court editor, frame-based animation, searchable play database, PDF
  playbook export) rather than broad-and-shallow.
- Three-product long-term staging: **CXP Coach** (v1 business) →
  **CXP Club** (org/finance/travel/marketplace, 2–4yr) → **CXP Network**
  (coach portfolios/mentorship, long-term).
- Client stack candidate: **Flutter**, reusing prior Kinjuu experience —
  cross-platform, custom canvas via `CustomPainter`, offline-first local
  storage with optional cloud sync.
- Finance/Travel/Certifications modules are explicitly scoped as
  **operational, not authoritative** — CXP integrates with QuickBooks/
  Xero/Business Central, Stripe, and certification providers rather than
  reinventing those systems.
- Full scoping content lives in `CXP-OVERVIEW.md` (Vision, Mission,
  Architecture, Modules, Security, AI Strategy, Data Model, Roadmap, MVP,
  Pricing, Business Model, Technical Stack, Azure Architecture, Future
  Vision, Open Questions).

**Completed:**

- CXP.00 — Scoping conversation captured to `CXP-OVERVIEW.md`
- CXP.01 — Repo scaffolded (GC bootstrap, DEV-PATH/DEV-PLAN/DEV-RELEASE,
  registered in portfolio `projects.yaml`)

**Carried forward:**

- CXP.03 — Flutter `CustomPainter` performance spike for animated
  multi-frame plays (unvalidated technical risk flagged in
  `CXP-OVERVIEW.md` Open Questions)
- CXP.04 — Basketball court editor prototype (single frame, drag-and-drop)

---

### Phase 1 — Architecture week (2026-07-10)

**Goal:** Produce the domain model, module boundaries, security model, AI
model, plugin architecture, and UX philosophy documents before any code is
written — same discipline used for Governance Commons. Design-only; no
implementation.

**Key decisions:**

- Domain model is multi-tenant from the first table (`organization_id` on
  every non-global row), event-sourced for statistics, versioned (not
  overwritten) for plays/practice/rosters, and carries an explicit
  ownership/license record on every coaching asset from v1 — including an
  `ai_use_permission` field, so the Marketplace's AI-retrieval permission
  model doesn't require a painful migration later.
- `PlayerSensitive` (medical/academic/emergency-contact data) is a
  separate table and separate permission boundary from `Player`, not a
  set of columns — hard requirement carried from the scoping
  conversation.
- Module contract: every module owns its own tables, declares its Core
  dependencies explicitly, is independently toggleable per organization,
  and emits audit records through Core rather than bespoke logging.
- Dependency direction is fixed: CXP may depend on Cockpit/eco.ai
  interfaces; neither may depend on CXP-specific types. CXP must still
  run in a degraded standalone mode with neither dependency present.
- Security model: Zero Trust permission evaluation on every call
  `(actor, organization_id, team_id?, resource, action)`; `PlayerSensitive`
  reads require an explicit additional grant beyond team membership;
  Finance enforces segregation of duties (submitter ≠ approver above a
  configured threshold).
- AI model: eco.ai gets context through the same permission layer as a
  human actor, never receives `PlayerSensitive` fields, and every
  recommendation must expose `{ text, why, confidence, evidence,
  approval_required, limitations }`. Guardrails (no injury diagnosis, no
  autonomous financial actions, no unsupervised minor messaging, etc.)
  are enforced at the tool/action layer CXP exposes, not left to prompt
  wording alone.
- Plugin architecture: sport packs (Basketball v1, Football later) supply
  playing surface, actor counts, symbols, path types, formation
  templates, validation rules, terminology, and export layout; the core
  engine (canvas, selection, frame/timeline, database, export) never
  branches on sport. `PlayFrame` needs an explicit decision on an optional
  `phase` field before football is built, to avoid reshaping the core
  frame schema later.
- UX philosophy: the Five-Minute Rule (org → team → players → tomorrow's
  practice, under 5 minutes) is the acceptance bar for every design
  decision. Click/prompt/hybrid modes are all first-class; no essential
  coaching task may require the prompt-driven mode. Accessibility
  (contrast, screen reader, keyboard nav, color-blind-safe diagrams) is
  treated as a v1-adjacent differentiator, not a Phase 4 afterthought.

**Completed:**

- CXP.02 — Architecture week: `docs/architecture/domain-model.md`,
  `module-boundaries.md`, `security-model.md`, `ai-model.md`,
  `plugin-architecture.md`, `ux-philosophy.md`
- CXP.05 — Flutter project skeleton (web + windows, org
  com.twentyamplabs), `flutter analyze` clean
- CXP.04 — Basketball court editor prototype: `lib/models/play_frame.dart`
  (sport-neutral `CourtActor`/frame shape, prototype-scoped version of the
  domain model's `PlayFrame`), `lib/features/court_editor/
  basketball_court_painter.dart` (basketball sport pack playing surface —
  key, free-throw circle, simplified three-point arc), `lib/features/
  court_editor/court_editor_screen.dart` (5 offense + 5 defense tokens,
  tap-to-select vs. pan-to-move disambiguation, reset action). No routes,
  no multi-frame animation, no save/export — scope was deliberately kept
  to the select-vs-move interaction discipline flagged as the hardest UX
  problem in `ux-philosophy.md`. `flutter analyze` and `flutter test` both
  clean.

**Carried forward:**

- CXP.03 — Flutter `CustomPainter` performance spike for multi-frame
  animated plays (still unvalidated — this prototype only exercises a
  single static frame with ~10 tokens, not animation or many
  simultaneous paths)
- CXP.06 — Route/path drawing (pass, cut, screen, shot) on top of the
  existing token drag-and-drop
- CXP.07 — Multi-frame sequencing (frame list + generated transitions)

---

### Phase 2 — Domain-agnostic Core + full platform target set (2026-07-10)

**Goal:** Resolve two open questions raised directly by the user before
more module code gets built on top of assumptions: (1) how domain-agnostic
should CXP's Core actually be, and (2) which platforms does the Flutter
client target. Both were decided by explicit user choice, not inferred.

**Key decisions:**

- **Full generic core + coaching vertical** (user's explicit choice over
  "keep coaching-specific, revisit later"). CXP's core is now formally
  domain-agnostic, mirroring `eco`'s `eco-core` → `eco-edu`/`eco-health`/...
  SKU model (`.eco/sku-inheritance.yaml`). `domain-model.md` was revised:
  `Organization`, `Cycle` (was "Season"), `Group`, `Member`,
  `MemberSensitive`, `Communication`, `Audit`, and `OwnershipRecord` are
  now `cxp-core` (domain-agnostic); `Team extends Group` and
  `Player extends Member` are `cxp-coaching` (the first Vertical Pack).
  Table names were deliberately **not** renamed away from coaching-familiar
  terms — the generic entity is real in Core, the coaching vertical
  extends it, rather than a wholesale rename churn with only one vertical
  to design against.
- **All six Flutter platform targets now** (user's explicit choice over
  "add platforms as we can test them"): `flutter create
  --platforms=macos,linux,android,ios` added the remaining platform
  folders alongside the existing web+windows scaffold. Only web is
  actually runnable/testable on this machine today (no Visual Studio C++
  workload, no Android SDK, no macOS/Linux toolchain) — the folders exist
  and compile-target correctly whenever those toolchains are available.
- **SKU model formalized**: `docs/architecture/sku-model.md` +
  `sku-inheritance.yaml` (repo root, mirrors `.eco/sku-inheritance.yaml`'s
  location/format) turn `CXP-OVERVIEW.md`'s pricing tiers into named SKUs
  (`cxp-community` → `cxp-coach-pro` → `cxp-team` → `cxp-club` →
  `cxp-enterprise`) with an inheritance chain and a capability-to-module
  mapping table. SKU tiers and Verticals are explicitly orthogonal:
  `Organization.vertical` picks the Vertical Pack, `Organization.tier`
  picks the SKU within that vertical's own ladder.
- `module-boundaries.md` revised to show the internal Core → Vertical
  Pack → Sport Pack layering (previously it only showed the external
  eco.ai/Cockpit/CXP split) and to tag every module in the inventory
  table with which layer it belongs to.

**Completed:**

- CXP.08 — Added macOS/Linux/Android/iOS Flutter platform targets
- CXP.09 — Domain-agnostic Core / Coaching Vertical Pack split
  (`domain-model.md`, `module-boundaries.md` revised)
- CXP.10 — SKU model (`sku-model.md`, `sku-inheritance.yaml`)

**Carried forward:**

- CXP.03, CXP.06, CXP.07 (unchanged from Phase 1)
- CXP.11 — No enforcement code reads `sku-inheritance.yaml` yet; it's a
  design artifact until the Core module's authorization layer is built

---

### Phase 3 — Animation perf spike (2026-07-10)

**Goal:** Resolve the `CustomPainter` performance open question
(`CXP-OVERVIEW.md`) before more editor features (routes, multi-frame
sequencing) build on an unvalidated rendering approach.

**Key decisions:**

- Spike scope is **functional only** in this environment: no release-mode
  build, no real device, no Windows-desktop run (Visual Studio's C++
  workload isn't installed here) was profiled. This is stated explicitly
  in `docs/architecture/perf-spike-cxp03.md` rather than implied as a
  full performance validation — the spike passed for continuing
  development, not for a release claim.
- Animation model confirmed as frames + generated transitions
  (`lerpFrame` between two frames), matching the choice already made in
  `ux-philosophy.md` over full keyframe timelines.
- `stressTestFrames()` deliberately generates a harder-than-realistic
  scenario (all 10 actors reshuffling every frame) to get a useful lower
  bound, with the explicit caveat that a typical real play likely costs
  less.
- Queued idea logged, not scoped: **CXP-edge** — a Raspberry Pi-class
  delivery target (local offline-sync hub, gym kiosk/scoreboard display,
  or video-capture appliance for Player Development), raised by the user
  and appended to `CXP-OVERVIEW.md` Open Questions rather than designed
  now, per `module-boundaries.md`'s "don't build ahead of the phase" rule.

**Completed:**

- CXP.03 — Animation perf spike (functional pass; real-device profiling
  remains an open follow-up, tracked as CXP.12)

**Carried forward:**

- CXP.12 — Real-device/release-mode profiling of the animation approach
  (blocked on having an actual device or a working Windows/Android/iOS
  toolchain in this environment)
- CXP.06, CXP.07 (unchanged)

---

### Phase 4 — Route drawing (2026-07-10)

**Goal:** Add route/path drawing (pass, dribble, cut, screen, shot,
defense) to the court editor without breaking the select/move
interaction CXP.04 already validated.

**Key decisions:**

- **Mode toggle, not gesture disambiguation on the same tokens.**
  `ux-philosophy.md` flags select-vs-move-vs-draw as the hardest
  interaction problem in this editor; rather than trying to infer intent
  from a single gesture stream, the prototype adds an explicit
  Select/Move ↔ Draw Route mode switch (`SegmentedButton`), the same
  pattern most pro diagram tools (Figma, Illustrator) use for a select
  tool vs. a pen tool. This is stated as a deliberate simplification, not
  a final answer — a future pass could attempt true gesture
  disambiguation within one mode.
- **`ActorPath` lives in Core's sport-neutral model** (`play_frame.dart`),
  matching `domain-model.md`'s `PlayFrame.paths` shape
  (`actor_id`/`type`/`points`) exactly. Styling per `PathType` (color,
  solid/dashed, arrowhead/screen-bar/none) is basketball-sport-pack-owned,
  living in `basketball_court_painter.dart`'s new
  `BasketballPathsPainter` — the core canvas still has no opinion on what
  a path "means," per `plugin-architecture.md`.
- Every path is a straight 2-point segment for this prototype — curved
  paths are deferred, but `ActorPath.points` is a list (not a fixed pair)
  so a curved-path upgrade doesn't require a schema change later.
- Drawing works by dragging from an actor's *rendered position* (nearest-
  actor hit test within a threshold), not by first tapping to "arm" a
  start actor — one drag gesture per path, consistent with the "drag a
  saved play or drill directly into a timeline" interaction style
  described in `CXP-OVERVIEW.md`.
- **Hit a real Flutter constraint mid-implementation:** wrapping
  `Positioned` widgets in `IgnorePointer` from the *outside* (to disable
  tokens while in Draw mode) throws — `Positioned` must be a direct
  `Stack` child. Fixed by moving `IgnorePointer` *inside* `_ActorToken`,
  wrapping only the `GestureDetector`. Logged here because it's a
  non-obvious Flutter framework constraint future work on this screen
  needs to remember.

**Completed:**

- CXP.06 — Route/path drawing: `ActorPath`/`PathType` model,
  `BasketballPathsPainter` (pass/dribble/cut/screen/shot/defense styling
  with arrowheads and a screen-bar symbol), mode-toggle UI, undo-last-path,
  Reset now also clears paths. `flutter analyze` clean; 7/7 tests passing
  (3 new: mode-switch reveals picker, drag-to-draw enables undo, Reset
  clears paths).

**Carried forward:**

- CXP.07 — Multi-frame sequencing (unchanged from Phase 1)
- CXP.13 — Curved path rendering (currently straight-line only)
- CXP.14 — Per-path delete/edit (currently only whole-list undo/clear)

---

### Phase 5 — Multi-frame sequencing (2026-07-10)

**Goal:** Let a play have more than one frame, with the engine generating
motion between them for playback — the last of the four "make basketball
MVP exceptional" pillars named in `CXP-OVERVIEW.md` (court editor, frame
animation, play database, PDF export) still outstanding on the editor
side.

**Key decisions:**

- **`PlayFrameData` bundles actors + paths per frame**, and paths are
  explicitly *not* carried forward when a frame is duplicated — a coach
  adding Frame 2 gets the previous frame's player positions (a sensible
  starting point to then move players from) but a blank canvas for new
  diagram annotations, since a pass drawn in Frame 1 doesn't mean
  anything in Frame 2's context. This is stated as a deliberate modeling
  choice in code comments, not an oversight.
- **Playback animates actor motion only — paths are not animated.**
  Reinforces the frames-plus-generated-transitions model from
  `ux-philosophy.md`: the engine interpolates positions between frames,
  but a drawn route is a teaching annotation for a specific frame, not a
  motion path to be traced by the animation.
- **Extracted `actorsAtSequenceProgress()`** from the CXP.03 perf-spike
  screen into the shared model file so CXP.03 (stress-test frames, timing
  instrumentation) and CXP.07 (real play frames, play/pause/restart
  controls, no instrumentation) share one implementation of "which
  segment, how far into it" instead of duplicating the math.
- **Frame UI:** horizontal chip row (`Frame 1`, `Frame 2`, ...) to select,
  `+` to add (duplicate-and-append-after-current), a trash icon to delete
  the current frame (disabled when only one frame remains — a play always
  has at least one frame). `Reset` collapses back to a single default
  frame, matching its existing "wipe everything" semantics from CXP.04.

**Completed:**

- CXP.07 — Multi-frame sequencing: `PlayFrameData`,
  `actorsAtSequenceProgress()` (shared with CXP.03),
  `FramePlaybackScreen` (play/pause/restart, no timing instrumentation),
  frame chip row with add/delete/select. `flutter analyze` clean; 14/14
  tests passing (7 new for frame add/delete/select/duplicate-semantics/
  playback).

**Carried forward:**

- CXP.13 — Curved path rendering
- CXP.14 — Per-path delete/edit
- CXP.15 — Local play persistence (play database) — nothing survives an
  app restart yet; this and CXP.16 are the remaining pieces of the
  `CXP-OVERVIEW.md` v0.1 MVP definition
- CXP.16 — PDF/PNG/SVG playbook export
- CXP.12 — Real-device/release-mode profiling (unchanged, still blocked
  on device/toolchain access)

---

### Phase 6 — Local play persistence (2026-07-10)

**Goal:** Close the "searchable play database" gap in `CXP-OVERVIEW.md`'s
v0.1 MVP definition — nothing survived an app restart until this pass.

**Key decisions:**

- **`shared_preferences`, not `sqflite`/Drift, for the prototype.**
  `shared_preferences` works identically across all six scaffolded
  Flutter targets (including web) with zero per-platform setup; a real
  SQLite-backed store would need different wiring per platform (and a
  separate web story via `sqflite_common_ffi_web`). One JSON-encoded list
  under a single key is enough to prove the save/load/delete flow; it is
  explicitly not the domain model's versioned event layer for plays (see
  `domain-model.md`'s "Versioned, not overwritten" discipline) — replacing
  it with a real backend is exactly why `PlayRepository` is an interface
  and not a concrete class UI code depends on directly.
- **`SavedPlay` is a deliberately thin cut of `domain-model.md`'s `Play`.**
  No `organization_id`, `group_id`, `sport`, `family`, `formation`,
  `tags`, `version`, or `OwnershipRecord` — there is no
  organization/team/auth layer in this prototype for those fields to mean
  anything yet. Documented in the model file's doc comment so it isn't
  mistaken for the real thing.
- **Reset clears play identity, not just canvas state.** Before this
  pass, "Reset" only wiped frames/paths; now it also clears
  `_currentPlayId`/`_currentPlayName` back to "Untitled Play" so pressing
  Save afterward creates a new record instead of silently overwriting
  whatever play the session started from.
- **Legacy `SharedPreferences.getInstance()` API, not the newer
  `SharedPreferencesAsync`** — chosen specifically for well-documented
  test-mocking support (`SharedPreferences.setMockInitialValues`), though
  the final tests ended up using an in-memory `_FakePlayRepository`
  instead and never needed the platform channel at all — documented here
  as the reasoning in case a future pass reaches for the real store in
  tests.
- **Found and fixed a stale doc reference while in this area:**
  `security-model.md` still said `PlayerSensitive` in several places from
  before the Core/Vertical split (`domain-model.md` renamed it to
  `MemberSensitive` in Phase 2) — corrected.
- **Logged, not built:** identity-provider federation (Entra ID/Google
  Workspace/Okta SSO, gated to `cxp-club`+; MFA/TOTP, ungated at every
  tier) added to `security-model.md` and the SKU capability map
  (`sso_integration`) per a direct user question — there is no auth
  backend yet for either to attach to, so this is a decided boundary, not
  an implementation.

**Completed:**

- CXP.15 — Local play persistence: `SavedPlay` model (JSON round-trip),
  `PlayRepository` interface + `SharedPreferencesPlayRepository`,
  `PlayLibraryScreen` (list/load/delete), Save dialog wired into the
  court editor with new-vs-overwrite semantics tied to play identity.
  `flutter analyze` clean; 20/20 tests passing (6 new: JSON round-trip,
  repository contract, save flow, library load flow, library delete flow,
  reset-then-save-creates-new-record).
- Identity-provider federation SKU boundary decided and documented
  (`security-model.md`, `sku-model.md`, `sku-inheritance.yaml`).

**Carried forward:**

- CXP.16 — PDF/PNG/SVG playbook export (last remaining v0.1 MVP piece)
- CXP.13, CXP.14, CXP.12 (unchanged)
- CXP.17 — Play search/tags/folders (library is a flat list today, fine
  for a handful of plays, not for a season's worth)

---

### Phase 7 — PDF playbook export (2026-07-10)

**Goal:** Close the last piece of `CXP-OVERVIEW.md`'s v0.1 MVP
definition — "beautiful PDF playbook export," the fourth of the four
named pillars (court editor, frame animation, play database, PDF export).

**Key decisions:**

- **PDF only this pass — PNG and SVG explicitly deferred (CXP.18).**
  `CXP-OVERVIEW.md` names PDF specifically as the MVP-critical format;
  PNG/SVG appear only in the fuller "Export to PNG, PDF, SVG..." list
  elsewhere. Rather than half-implement three formats, this pass finishes
  one properly. No mature, well-maintained Flutter package exists for
  writing SVG (only reading, via `flutter_svg`), so SVG export would need
  hand-rolled XML generation — a real but separate piece of work.
- **`package:pdf` + `package:printing`.** `pdf` builds the document in
  pure Dart (no platform dependency — this is what makes the byte
  generation unit-testable without a device or emulator). `printing`
  owns the actual save/share/print UX per platform, including a browser
  download on web, so this prototype does not hand-roll per-platform file
  I/O — the same reasoning that picked `shared_preferences` over
  `sqflite` for CXP.15 (work identically across all six scaffolded
  targets with minimal platform-specific code).
- **Reimplemented court/path rendering against `PdfGraphics`, not
  reused from `basketball_court_painter.dart`.** Flutter's `Canvas` and
  `package:pdf`'s `PdfGraphics` are different APIs with no shared
  abstraction — this is a deliberate, bounded duplication (rect/ellipse/
  line/dash/arrowhead primitives re-expressed against the PDF drawing
  calls), not a reuse failure. The actor tokens, by contrast, **are**
  built with `pw.Stack`/`pw.Positioned`/`pw.Container` — `package:pdf`'s
  widget API deliberately mirrors Flutter's, so that part *did* reuse the
  same structural approach as `_ActorToken`, just re-expressed in `pw.*`
  types.
- **Reduced path styling fidelity vs. the live editor, stated
  explicitly, not silently accepted.** The PDF version does not
  reproduce the live editor's full six-way visual distinction — dashed
  vs. solid and arrowhead vs. screen-bar are preserved, but exact colors/
  weights differ slightly. Logged as CXP.19 rather than treated as done.
- **One page per frame**, with the play name as a header and "Frame N of
  M" as a subheader — the minimum viable version of "play numbering" and
  "coaching notes" named in `CXP-OVERVIEW.md`'s export requirements; full
  coaching-notes metadata isn't captured by the editor yet, so it isn't
  in the export either.
- **Not widget-tested via a real button tap.** Same reasoning as CXP.03:
  `Printing.layoutPdf` talks to a platform channel with no real
  implementation in this test harness, so tapping it would throw
  `MissingPluginException`, not exercise real behavior. Tests instead
  call `buildPlaybookPdf()` directly (pure Dart, fully testable) and
  check only that the export button exists via finder — stated
  explicitly rather than silently skipped.

**Completed:**

- CXP.16 — PDF playbook export: `buildPlaybookPdf()`
  (`lib/export/playbook_pdf_exporter.dart`), wired to the court editor's
  app bar via `Printing.layoutPdf`. `flutter analyze` clean; 25/25 tests
  passing (5 new: PDF header validity, page-count-matches-frame-count,
  all six `PathType`s render without throwing, degenerate zero-length
  path doesn't throw, export button present in the app bar).

**Carried forward:**

- CXP.18 — PNG/SVG export
- CXP.19 — Full path-style fidelity parity between the live editor and
  the PDF export
- CXP.13, CXP.14, CXP.12, CXP.17 (unchanged)

**v0.1 MVP status:** all four `CXP-OVERVIEW.md` pillars (court editor,
frame animation, play database, PDF export) now have a working
prototype. Nothing here has been tried on a real device, and per the
"first milestone" discussion, the honest next step is trying this on web
with a real coach before adding more scope.

---

### Phase 8 — First real coach validation (2026-07-10)

**Goal:** Get the v0.1 prototype in front of an actual coach (15 years
AAU boys basketball + community ed) and act on real feedback instead of
continuing to build blind. This is the first genuine external validation
this project has had.

**How it was done:** `flutter run -d web-server --web-port=8765`, the
coach opened `http://localhost:8765` in their own browser directly — no
`chromium-cli` available in this environment (checked; not installed,
not discoverable as a public package here, likely bundled only in
certain cloud/sandboxed Claude Code container images). Attempted headless
Edge screenshots for my own verification; `--screenshot` mode fires
before Flutter's debug web bootstrap actually paints, so this didn't
produce a usable image on repeated attempts — real proportions debugging
had to go back to code review plus the coach's own screenshots, not a
self-service screenshot loop. Logged so a future pass doesn't re-attempt
the same broken approach; Playwright (a real, installable, well-
documented tool) was identified as the correct fix if reliable automated
verification is needed again, but not installed without confirming first.

**Feedback received (verbatim substance) and what was done about each:**

1. *"Court is disproportionate and lines are misplaced, but the export
   is sized good and lines and key are right."* — Real bug, root-caused
   via code review: the free-throw circle radius was tied to
   `laneWidth / 2` (16% of court width) instead of a real court's ~12%
   (6ft circle / 50ft-wide half-court) — a third too large. The
   three-point arc used two hand-guessed radian constants (`3.4`, `2.6`)
   with no actual geometric derivation behind them. Fixed: free-throw
   circle now uses an explicit `0.12 * width` constant; the arc's start/
   sweep angles are now derived from where the arc should meet the
   baseline (`math.asin`), correct regardless of aspect ratio, replacing
   the magic numbers. **The PDF export's free-throw circle was
   deliberately left unchanged** — the coach confirmed it already looks
   right; "more mathematically consistent" is not a reason to touch code
   a real user already validated.
2. *"A lite or web version with limited tools could use the mode
   feature maybe."* — Acknowledged as a legitimate simpler variant for a
   future lighter-weight SKU tier, not acted on now; the full tool rail
   (see CXP.20 below) is the primary experience going forward.
3. *"When building frames, players who had been drawn to cut or screen
   are in the same position, making it hard to build the next step."* —
   Real, high-value workflow gap. Fixed as CXP.21: adding a frame now
   advances any actor with a drawn path to that path's endpoint, not
   their pre-move position — a coach draws a cut, adds a frame, and the
   player is already where the arrow pointed. An actor with no drawn
   path is unaffected (same as before).
4. *"No way to designate the basketball or its movement from dribbling
   or passing directions."* — Real, high-value gap. Added as CXP.21:
   `PlayFrameData.ballHolderId` (one designated holder per frame, not a
   free-floating ball position — matches how coaches actually diagram
   it), a `Ball` tool in the rail (tap a player to give/clear the ball),
   a small orange badge rendered on the holder's token in both the live
   editor and the PDF export. When a frame is added, if the current
   holder's last path was a `pass`, the ball automatically follows the
   pass to whichever player is nearest the pass's landing point — dribble/
   cut/screen/shot/defense paths leave the ball with the same player.
   Playback (`FramePlaybackScreen`) does not yet render the ball marker —
   deferred as CXP.23, not silently dropped.

**Also fixed during implementation, not part of the coach's report:** a
real bug the test suite itself caught — the ball-transfer logic initially
searched for the nearest receiver among *already-advanced* actor
positions, but a passer who also has a cut/path of their own gets
advanced to their path's endpoint, which can land almost exactly on top
of the actual receiver, causing the passer to match themself as
"nearest" and the ball to never transfer. Fixed by searching the
*original* (pre-advance) positions and excluding the passer from
candidates — receiver identification is about who was standing at the
landing spot *at the time of the pass*, not where everyone ends up after
their own paths are applied.

**Interaction model change (CXP.20):** replaced the Select/Move-vs-
Draw-Route segmented toggle + separate path-type dropdown (CXP.06) with
a persistent side tool rail — Select/Move, Ball, then one icon per
`PathType` (Pass/Dribble/Cut/Screen/Shot/Defense) — after the coach's
direct comparison to Photoshop/Illustrator/LibreCAD: "a sidebar of tools
that knows what you're doing." One click both switches the active tool
and (for draw tools) picks what it draws, instead of two separate
actions. Stated as the current answer, not necessarily final — still the
same select-vs-move-vs-draw interaction problem `ux-philosophy.md`
already flagged as the hardest one in this editor.

**Also logged, not built:** two Future Vision ideas from a second,
separate strategic-direction pasted conversation — an "Instruction
Engine" (`Teach Play`: eco.ai-generated multi-day installation plans,
player-specific responsibility sheets, age-appropriate variants — needs
no new technical capability beyond what's already in `ai-model.md`,
flagged as the stronger near-term differentiator) and "Game Intelligence"
(computer-vision video-to-play conversion — explicitly deferred as a
later-stage capability per the source material's own reality check, not
a v1 dependency). Both appended to `CXP-OVERVIEW.md`'s Future Vision
section.

**Completed:**

- CXP.20 — Tool rail replaces mode toggle + dropdown
  (`_Tool` enum, `_ToolRail`, `_ToolButton` in `court_editor_screen.dart`)
- CXP.21 — Frame-add advances actors to drawn path endpoints; ball
  marker (`PlayFrameData.ballHolderId`, Ball tool, badge rendering in
  editor + PDF, pass-triggered ball transfer with the original-positions
  bug fix above)
- CXP.22 — Court geometry fix: free-throw circle radius corrected to a
  real proportion; three-point arc angles now geometrically derived
  instead of hand-guessed constants
- Future Vision additions: Instruction Engine, Game Intelligence

**Test coverage:** `flutter analyze` clean; 29/29 tests passing (4 new:
frame-add advances an actor with a path to its endpoint, frame-add
leaves an actor with no path unchanged, Ball tool assigns/clears the
badge on tap, a pass transfers the ball to the receiver on the next
frame — this last test is what caught the original-vs-advanced-positions
bug above).

**Carried forward:**

- CXP.23 — Ball marker in `FramePlaybackScreen` (not rendered during
  animated playback yet)
- CXP.24 — "Lite" tool-mode variant for a future lighter-weight SKU tier
  (coach's suggestion #2 above, not acted on now)
- CXP.13, CXP.14, CXP.17, CXP.18, CXP.19, CXP.12, CXP.11 (unchanged)

---

## TASK REGISTRY

| ID | Name | Status | Phase | Notes |
| --- | --- | --- | --- | --- |
| CXP.00 | Capture scoping conversation | done | 0 | See `CXP-OVERVIEW.md` |
| CXP.01 | Scaffold repo + GC bootstrap | done | 0 | AGENTS.md, DEV-PATH/PLAN/RELEASE, projects.yaml entry |
| CXP.02 | Architecture week | done | 1 | `docs/architecture/*.md` — domain model, module boundaries, security, AI, plugin, UX |
| CXP.03 | Flutter `CustomPainter` performance spike | done (functional only) | 1 | `lib/features/court_editor/animation_perf_spike_screen.dart` — see `docs/architecture/perf-spike-cxp03.md`; real-device/release-mode profiling still outstanding |
| CXP.04 | Basketball court editor prototype | done | 1 | `lib/features/court_editor/` — single frame, 5v5 drag-and-drop, tap-to-select; `flutter analyze`/`flutter test` clean |
| CXP.05 | Flutter project skeleton | done | 1 | web+windows targets, org com.twentyamplabs, `flutter analyze` clean |
| CXP.06 | Route/path drawing on court editor | done | 4 | `ActorPath`/`PathType`, `BasketballPathsPainter`, mode toggle, undo; `flutter analyze`/`flutter test` clean (7/7) |
| CXP.07 | Multi-frame sequencing | planned | 1 | Frame list + generated transitions |
| CXP.07 | Multi-frame sequencing | done | 5 | `PlayFrameData`, `FramePlaybackScreen`, frame chip row; `flutter analyze`/`flutter test` clean (14/14) |
| CXP.13 | Curved path rendering | planned | 4 | Straight-line only today; `ActorPath.points` shape allows this later |
| CXP.14 | Per-path delete/edit | planned | 4 | Only whole-list undo/clear exists today |
| CXP.15 | Local play persistence (play database) | done | 6 | `SavedPlay`, `PlayRepository`, `PlayLibraryScreen`, Save dialog; `flutter analyze`/`flutter test` clean (20/20) |
| CXP.16 | PDF playbook export | done | 7 | `buildPlaybookPdf()` + `Printing.layoutPdf`; `flutter analyze`/`flutter test` clean (25/25) |
| CXP.17 | Play search/tags/folders | planned | 6 | Library is a flat list today |
| CXP.18 | PNG/SVG export | planned | 7 | Deferred — PDF is the MVP-critical format |
| CXP.19 | Path-style fidelity parity (editor vs. PDF) | planned | 7 | PDF export has reduced styling fidelity today |
| CXP.08 | Add macOS/Linux/Android/iOS platform targets | done | 2 | Folders scaffolded; only web currently buildable on this machine |
| CXP.09 | Domain-agnostic Core / Vertical Pack split | done | 2 | `domain-model.md`, `module-boundaries.md` revised |
| CXP.10 | SKU model | done | 2 | `sku-model.md`, `sku-inheritance.yaml` |
| CXP.11 | Wire SKU enforcement into Core's authorization layer | planned | — | Blocked on Core module implementation existing at all |
| CXP.12 | Real-device/release-mode profiling of animation perf spike | planned | 3 | Blocked on an actual device or working desktop toolchain |
| CXP.20 | Tool rail (replaces mode toggle + dropdown) | done | 8 | Real coach feedback; `_Tool`/`_ToolRail` in `court_editor_screen.dart` |
| CXP.21 | Frame-add path-endpoint advance + ball marker | done | 8 | Real coach feedback; `flutter analyze`/`flutter test` clean (29/29) |
| CXP.22 | Court geometry fix (free-throw circle, 3PT arc) | done | 8 | Real coach feedback; PDF export intentionally left unchanged (already confirmed correct) |
| CXP.23 | Ball marker in `FramePlaybackScreen` | planned | 8 | Not rendered during animated playback yet |
| CXP.24 | "Lite" tool-mode variant for a future SKU tier | planned | 8 | Coach's suggestion, not acted on now |
| CXP.25 | Configurable basketball courts | done | 9 | NBA/NCAA/high-school/middle-school/FIBA/custom boundaries; half/full; hardwood/blacktop; persisted and exported |

Status values: `planned` · `in_progress` · `blocked` · `done` · `deferred` · `unknown_needs_audit`

---

## CHANGELOG LINKS

- No handoff log or public CHANGELOG.md yet — scaffold stage.

---

## NORMALIZATION NOTES

- Registry pointer: `planning.path` in portfolio `projects.yaml`
- Current plan file: `DEV-PLAN.md`
- Tracks file required: no (single-track scaffold; add `DEV-TRACKS.md` if
  parallel workstreams emerge)

---

### Phase 9 — Configurable basketball playing surfaces (2026-07-10)

**Goal:** Replace the prototype's single hard-coded NBA-like half court
with a saved, regulation-aware court configuration that supports the
environments coaches actually use.

**Key decisions:**

- Court standard, extent, and surface are separate choices. Outdoor
  blacktop is a surface treatment, not a competing regulation standard,
  so it can be paired with NBA, NCAA, high-school, middle-school, FIBA,
  or custom boundaries.
- Regulation presets store measurements in feet and rendering derives
  proportions from the selected boundary. Presets: NBA (94×50), NCAA
  (94×50), US high school (84×50), representative US middle school
  (74×42), and FIBA/European (28×15m represented in feet).
- Custom configuration exposes full length and width while retaining NBA
  line measurements as an explicit prototype default. A later refinement
  may expose every individual marking measurement.
- Court configuration belongs to `SavedPlay`, not individual frames: a
  play uses one surface while player and path coordinates remain normalized
  and therefore survive configuration changes without migration.
- Full-court rendering draws both basket ends, midcourt line, and center
  circle. The same configuration drives editor, playback, persistence,
  and PDF export.

**Completed:**

- CXP.25 — `CourtConfiguration`, regulation presets, half/full and
  hardwood/blacktop selection, custom boundary entry, regulation-aware
  painter, saved-play compatibility, playback/PDF propagation, and tests.

**Validation:** 35/35 Flutter tests passing, including preset dimensions,
custom JSON round-trip, UI selection/save, legacy save compatibility, and
the existing editor/persistence/export regression suite.
