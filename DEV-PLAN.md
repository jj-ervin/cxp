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

**Active phase:** Phase 1 — Flutter skeleton + editor prototype
**Active tracks:** none yet (single-track)
**Current version:** pre-v0.1 (architecture documented, no app code yet)
**Next release target:** none committed — see Open Questions in `CXP-OVERVIEW.md`

**P0 blockers — must resolve before any new feature work:**

- *(none)* — architecture week (CXP.02) is done; proceeding to CXP.05
  (Flutter skeleton) and CXP.04 (court editor prototype).

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
| Basketball MVP (routes, frames, play DB, PDF export) | v0.1 | — | ⬜ |

Status key: ✅ Done · 🔄 In progress · ⬜ Planned · ❌ Blocked

---

## PRIORITY WORK ITEMS

| ID | Task | Track | Priority |
| --- | --- | --- | --- |
| CXP.06 | Route/path drawing (pass, cut, screen, shot) on the court editor | — | P0 |
| CXP.03 | Flutter `CustomPainter` performance spike for multi-frame animated plays | — | P1 |
| CXP.07 | Multi-frame sequencing (frame list + generated transitions) | — | P1 |
| CXP.11 | Wire SKU enforcement into Core's authorization layer | — | P2 (blocked on Core existing) |

---

## RECENTLY COMPLETED

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
