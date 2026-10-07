# DEV-PLAN — CXP (Coach Experience Platform)

**AUTHORITY LEVEL: AL:2**
**Status:** SCAFFOLD
**Updated:** 2026-07-10

---

## CANONICAL DOC RULE

`DEV-PLAN.md` owns: current execution state, active milestones, priority work queue, release targets.
`DEV-PATH.md` owns: phase history, design decisions, and task registry.

Do not create competing root planning files with alternate names (`devplan`, `DEV-PLAN`, etc.).

---

## CURRENT POSITION

**Active phase:** Phase 9 — configurable basketball playing surfaces
**Active tracks:** none yet (single-track)
**Current version:** pre-v0.1 — first real coach (15 years AAU boys
basketball + community ed) tried the web build directly and gave
concrete feedback; four items acted on same-session (tool rail, court
geometry fix, frame-add path-endpoint advance, ball marker)
**Next release target:** none committed — see Open Questions in
`CXP-OVERVIEW.md`

**P0 blockers — must resolve before any new feature work:**

- *(none)* — next step is getting the same coach to re-test the fixes
  live, not building further ahead of feedback.

---

## RELEASE STATUS

| Item | Target | Track | Status |
| --- | --- | --- | --- |
| Scoping capture (`CXP-OVERVIEW.md`) | — | — | ✅ |
| Repo scaffold + GC bootstrap | — | — | ✅ |
| Architecture week (`docs/architecture/*.md`) | pre-v0.1 | — | ✅ |
| Flutter project skeleton (web + windows) | pre-v0.1 | — | ✅ |
| All six Flutter platform targets scaffolded | pre-v0.1 | — | ✅ |
| Court editor prototype (single frame, drag-and-drop) | pre-v0.1 | — | ✅ |
| Domain-agnostic Core / Vertical Pack split | pre-v0.1 | — | ✅ |
| SKU model | pre-v0.1 | — | ✅ |
| Animation perf spike (functional; real-device profiling outstanding) | pre-v0.1 | — | 🔄 |
| Route/path drawing (straight lines, 6 types) | pre-v0.1 | — | ✅ |
| Multi-frame sequencing + playback | pre-v0.1 | — | ✅ |
| Local play persistence (play database) | v0.1 | — | ✅ |
| PDF playbook export | v0.1 | — | ✅ |
| First real coach validation pass (tool rail, geometry fix, path-endpoint advance, ball marker) | pre-v0.1 | — | ✅ |
| PNG/SVG export | v0.2 | — | ⬜ |

Status key: ✅ Done · 🔄 In progress · ⬜ Planned · ❌ Blocked

---

## PRIORITY WORK ITEMS

| ID | Task | Track | Priority |
| --- | --- | --- | --- |
| — | Get the coach to re-test the fixes live (validation, not a build task) | — | P0 |
| CXP.23 | Ball marker in `FramePlaybackScreen` | — | P1 |
| CXP.12 | Real-device/release-mode profiling of animation perf spike | — | P1 (blocked on device/toolchain access) |
| CXP.17 | Play search/tags/folders | — | P1 |
| CXP.18 | PNG/SVG export | — | P2 |
| CXP.19 | Path-style fidelity parity (editor vs. PDF) | — | P2 |
| CXP.13 | Curved path rendering | — | P2 |
| CXP.14 | Per-path delete/edit | — | P2 |
| CXP.24 | "Lite" tool-mode variant for a future SKU tier | — | P2 |
| CXP.11 | Wire SKU enforcement into Core's authorization layer | — | P2 (blocked on Core existing) |

---

## RECENTLY COMPLETED

- CXP.25 — Court configuration: NBA, NCAA, high-school, middle-school,
  FIBA/European, and custom boundaries; half/full court; indoor hardwood
  and outdoor blacktop; saved with the play and propagated through editor,
  playback, and PDF export. 35/35 tests passing (2026-07-10)
- CXP.20/21/22 — First real coach feedback pass: tool rail replacing the
  mode toggle + dropdown, frame-add now advances actors to their drawn
  path's endpoint, ball marker (`ballHolderId`, Ball tool, pass-triggered
  transfer), and a real court-geometry bug fix (free-throw circle radius,
  three-point arc angles) — the PDF export's already-correct proportions
  were deliberately left untouched. `flutter analyze` clean, 29/29 tests
  passing (2026-07-10)
- CXP.16 — PDF playbook export: `buildPlaybookPdf()` + `Printing.layoutPdf`
  wiring; PNG/SVG explicitly deferred (CXP.18); `flutter analyze` clean,
  25/25 tests passing. **This completes all four v0.1 MVP pillars named
  in `CXP-OVERVIEW.md`** (court editor, frame animation, play database,
  PDF export) at prototype level (2026-07-10)
- CXP.15 — Local play persistence: `SavedPlay`/`PlayRepository`/
  `PlayLibraryScreen`, Save dialog with new-vs-overwrite semantics;
  identity-provider federation (SSO/MFA) SKU boundary decided and
  documented; `flutter analyze` clean, 20/20 tests passing (2026-07-10)
- CXP.07 — Multi-frame sequencing: `PlayFrameData`, frame chip row
  (add/delete/select), `FramePlaybackScreen` (play/pause/restart); paths
  deliberately not carried forward when a frame is duplicated;
  `flutter analyze` clean, 14/14 tests passing (2026-07-10)
- CXP.06 — Route/path drawing: pass/dribble/cut/screen/shot/defense path
  types with distinct styling, mode-toggle interaction (Select/Move vs.
  Draw Route), undo-last-path; `flutter analyze` clean, 7/7 tests passing
  (2026-07-10)
- CXP.03 — Animation perf spike: functional pass, `docs/architecture/
  perf-spike-cxp03.md` documents findings and what's still unvalidated
  (2026-07-10)
- CXP.08 — Added macOS/Linux/Android/iOS Flutter platform targets;
  all six now scaffolded (2026-07-10)
- CXP.09 — Domain-agnostic Core / Coaching Vertical Pack split —
  `domain-model.md`, `module-boundaries.md` revised (2026-07-10)
- CXP.10 — SKU model: `sku-model.md`, `sku-inheritance.yaml`, formalizing
  pricing tiers as inheritable SKUs (2026-07-10)
- CXP.04 — Basketball court editor prototype: 5v5 drag-and-drop,
  tap-to-select vs. pan-to-move, `flutter analyze`/`flutter test` clean
  (2026-07-10)
- CXP.05 — Flutter project skeleton: web+windows targets, org
  com.twentyamplabs, placeholder shell, `flutter analyze` clean (2026-07-10)
- CXP.02 — Architecture week: domain model, module boundaries, security
  model, AI model, plugin architecture, UX philosophy (2026-07-10)
- CXP.00 — Scoping conversation captured to `CXP-OVERVIEW.md` (2026-07-10)
- CXP.01 — Repo scaffolded, registered in portfolio `projects.yaml` (2026-07-10)

---

## DEFERRED / OUT OF SCOPE

- Football module — deferred until basketball core engine + MVP ships
  (see `CXP-OVERVIEW.md` Roadmap)
- Marketplace, Finance, Travel, Coach Development, CXP Club/Network —
  deferred past v1 (`CXP-OVERVIEW.md` Roadmap Phase 3+)
- Power BI/Fabric integration — deferred past initial build
  (`CXP-OVERVIEW.md` Azure Architecture)

---

## QUEUED IDEAS

- **Game Operations / Stat Keeper extension** — one live, auditable game
  state with role-specific workspaces for scorekeeper/stat crew, coaching
  staff, clock operator, PR staff, announcers, press, and parents/fans.
  Candidate capabilities: score/period/possession/team-foul state; player
  events and box score; lineup and substitution tracking; timeout and clock
  coordination; coach-only notes; announcer/PR fact cards and milestones;
  press-safe live feed; and a simplified parent-facing game view. Authority
  must be explicit: official table roles write canonical game events,
  coaching staff annotate without rewriting official statistics, and
  press/parents receive read-only delayed or approved projections. Queue for
  architecture and workflow validation before implementation; do not fold
  it into the current court-editor prototype ad hoc.

---

## NORMALIZATION NOTES

- Registry pointer: `planning.canonical` in portfolio `projects.yaml`
- Companion history file: `DEV-PATH.md`
- Tracks file required: no


## 2026-10-06 reconciliation delta

Local main b7ae78aa668e243a435c45dc9c3dcdda19caa5fe matches private jj-ervin/cxp main. README's no-implementation claim was stale: editor/route tools, configurable basketball surfaces, frame actor playback, local play save/load/delete and PDF playbook export are implemented prototypes. Court configuration persists with the play and is passed to playback/export. Platform scaffolds exist for web/Windows/Linux/macOS/Android/iOS; scaffolding is not target-machine validation.

pubspec declares 1.0.0+1 with publish_to:none, while planning calls the product pre-v0.1. Treat this as a package/build metadata versus product-release discrepancy, not evidence of a shipped 1.0 product or permission to choose a new version. No tags/releases/application CI or new coach feedback were established. Existing four draft release criteria remain unchecked. Search/tag/folder storage, PNG/SVG export, playback ball marker, real-device profiling and coach retest remain open as already scoped.

Local storage is one SharedPreferences JSON list, not the intended versioned/multi-tenant backend. Main launches the court editor directly; org/team/practice onboarding, authorization/SKU enforcement, AI services, backend sync and future game/stat operations are not implemented by the architecture documents. Test repository fixtures do not certify real-browser persistence or coach usability. No youth/team record or existing user preference store was accessed.

Fresh exact-HEAD proof uses the installed Flutter 3.41.6/Dart 3.11.4 toolchain and locked dependencies in a disposable copy. Native Windows plugin setup requires symlink support unavailable in this session; its platform files are preserved outside the temporary web proof's detected platform path. No Developer Mode/system setting or SDK upgrade was made. Web/test proof is distinct from native installation/device/profile proof. Detailed results and limits are recorded in the reconciliation report.

Next: obtain the already-requested coach retest, establish one supported release/installation target, then scope open usability/performance/export/storage work. Do not build the queued architecture/SKU/game-operations brainstorms automatically. No feature, version bump, checkbox clearance, release, commit, push or deployment occurred.
