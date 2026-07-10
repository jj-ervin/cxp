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

**Active phase:** Phase 0 — Scoping
**Active tracks:** none yet (single-track)
**Current version:** pre-v0.1 (no code)
**Next release target:** none committed — see Open Questions in `CXP-OVERVIEW.md`

**P0 blockers — must resolve before any new feature work:**

- *(none)* — nothing has started yet; the blocker is deciding whether to
  run the architecture week (CXP.02) before writing any code.

---

## RELEASE STATUS

| Item | Target | Track | Status |
| --- | --- | --- | --- |
| Scoping capture (`CXP-OVERVIEW.md`) | — | — | ✅ |
| Repo scaffold + GC bootstrap | — | — | ✅ |
| Architecture week | pre-v0.1 | — | ⬜ |
| Basketball MVP (court editor, frames, play DB, PDF export) | v0.1 | — | ⬜ |

Status key: ✅ Done · 🔄 In progress · ⬜ Planned · ❌ Blocked

---

## PRIORITY WORK ITEMS

| ID | Task | Track | Priority |
| --- | --- | --- | --- |
| CXP.02 | Architecture week: domain model, module boundaries, UX philosophy, design language, plugin architecture, security model, AI model | — | P0 |
| CXP.03 | Flutter `CustomPainter` performance spike for multi-frame animated plays | — | P1 |
| CXP.04 | Basketball court editor prototype (drag-and-drop players, single frame) | — | P1 |

---

## RECENTLY COMPLETED

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
