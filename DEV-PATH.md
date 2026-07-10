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

## TASK REGISTRY

| ID | Name | Status | Phase | Notes |
| --- | --- | --- | --- | --- |
| CXP.00 | Capture scoping conversation | done | 0 | See `CXP-OVERVIEW.md` |
| CXP.01 | Scaffold repo + GC bootstrap | done | 0 | AGENTS.md, DEV-PATH/PLAN/RELEASE, projects.yaml entry |
| CXP.02 | Architecture week | done | 1 | `docs/architecture/*.md` — domain model, module boundaries, security, AI, plugin, UX |
| CXP.03 | Flutter `CustomPainter` performance spike | done (functional only) | 1 | `lib/features/court_editor/animation_perf_spike_screen.dart` — see `docs/architecture/perf-spike-cxp03.md`; real-device/release-mode profiling still outstanding |
| CXP.04 | Basketball court editor prototype | done | 1 | `lib/features/court_editor/` — single frame, 5v5 drag-and-drop, tap-to-select; `flutter analyze`/`flutter test` clean |
| CXP.05 | Flutter project skeleton | done | 1 | web+windows targets, org com.twentyamplabs, `flutter analyze` clean |
| CXP.06 | Route/path drawing on court editor | planned | 1 | Pass/cut/screen/shot on top of existing drag-and-drop |
| CXP.07 | Multi-frame sequencing | planned | 1 | Frame list + generated transitions |
| CXP.08 | Add macOS/Linux/Android/iOS platform targets | done | 2 | Folders scaffolded; only web currently buildable on this machine |
| CXP.09 | Domain-agnostic Core / Vertical Pack split | done | 2 | `domain-model.md`, `module-boundaries.md` revised |
| CXP.10 | SKU model | done | 2 | `sku-model.md`, `sku-inheritance.yaml` |
| CXP.11 | Wire SKU enforcement into Core's authorization layer | planned | — | Blocked on Core module implementation existing at all |
| CXP.12 | Real-device/release-mode profiling of animation perf spike | planned | 3 | Blocked on an actual device or working desktop toolchain |

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
