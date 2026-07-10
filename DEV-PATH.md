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
- CXP.02 — Architecture week (domain model, module boundaries, UX
  philosophy, design language, plugin architecture, security model, AI
  model) — recommended before any implementation starts, per the same
  discipline used for Governance Commons.

---

## TASK REGISTRY

| ID | Name | Status | Phase | Notes |
| --- | --- | --- | --- | --- |
| CXP.00 | Capture scoping conversation | done | 0 | See `CXP-OVERVIEW.md` |
| CXP.01 | Scaffold repo + GC bootstrap | done | 0 | AGENTS.md, DEV-PATH/PLAN/RELEASE, projects.yaml entry |
| CXP.02 | Architecture week | planned | 0 | Domain model, module boundaries, security model, AI model — not started |

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
