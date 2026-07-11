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

**Active phase:** Phase 7 — v0.1 MVP prototype complete (editor side)
**Active tracks:** none yet (single-track)
**Current version:** pre-v0.1 — all four MVP pillars (court editor, frame
animation, play database, PDF export) have a working prototype, but
nothing has been tried on a real device or by a real coach yet
**Next release target:** none committed — see Open Questions in
`CXP-OVERVIEW.md` and the "first milestone" discussion in session history

**P0 blockers — must resolve before any new feature work:**

- *(none)* — but the honest next step per the milestone conversation is
  trying the app on web with a real coach before adding more scope, not
  continuing to build unvalidated features.

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
| PNG/SVG export | v0.2 | — | ⬜ |

Status key: ✅ Done · 🔄 In progress · ⬜ Planned · ❌ Blocked

---

## PRIORITY WORK ITEMS

| ID | Task | Track | Priority |
| --- | --- | --- | --- |
| — | Try the app on web with a real coach (validation, not a build task) | — | P0 |
| CXP.12 | Real-device/release-mode profiling of animation perf spike | — | P1 (blocked on device/toolchain access) |
| CXP.17 | Play search/tags/folders | — | P1 |
| CXP.18 | PNG/SVG export | — | P2 |
| CXP.19 | Path-style fidelity parity (editor vs. PDF) | — | P2 |
| CXP.13 | Curved path rendering | — | P2 |
| CXP.14 | Per-path delete/edit | — | P2 |
| CXP.11 | Wire SKU enforcement into Core's authorization layer | — | P2 (blocked on Core existing) |

---

## RECENTLY COMPLETED

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

- (Nothing queued yet beyond what's captured in `CXP-OVERVIEW.md` — that
  document is the holding area for all brainstormed scope until the
  architecture week promotes items into this file's priority queue.)

---

## NORMALIZATION NOTES

- Registry pointer: `planning.canonical` in portfolio `projects.yaml`
- Companion history file: `DEV-PATH.md`
- Tracks file required: no
