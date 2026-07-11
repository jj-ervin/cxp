# DEV-RELEASE — CXP (Coach Experience Platform)

**AUTHORITY LEVEL: AL:2**
**Status:** Prototype implementation — no public release gate committed
**Created:** 2026-07-10
**Authority:** Owned by this repo. Sequencing and cross-repo dependencies,
if any emerge, defer to [`docs/DEV-RELEASE.md`](../docs/DEV-RELEASE.md)
(portfolio master).

---

## Current State Summary

CXP is in **Phase 9 — configurable basketball playing surfaces** (see
`DEV-PATH.md`). The basketball editor, frame playback, local persistence,
and PDF export exist as tested prototypes. No public release target or
distribution gate has been committed yet.

---

## What "release-ready" will require

Per this portfolio's gap-closure principle (see
`docs/DEV-RELEASE.md`), a release is not real until:

1. **Mechanism exists** — not a document, working code/schema/spec
2. **Mechanism is tested** — a test would fail if it broke
3. **Mechanism is observable** — some signal is emitted when it runs
4. **Mechanism is discoverable** — a stranger can find and understand it

The prototype mechanisms and regression tests exist. Public packaging,
installation evidence, support posture, and release observability remain
unproven.

---

## Release v0.1 — Basketball MVP (prototype in progress)

**Status:** In progress — architecture week is complete; prototype MVP
pillars exist, but release/admission criteria are not yet satisfied.

### What would ship

- Drag-and-drop basketball court editor
- Regulation-aware court configuration (NBA/NCAA/high school/middle
  school/FIBA/custom; half/full; hardwood/blacktop)
- Frame-based play animation
- Searchable play database
- PDF/PNG/SVG playbook export

### Admission criteria (draft — will be revised after architecture week)

- [ ] The Five-Minute Rule holds: create org → team → players → tomorrow's
      practice in under 5 minutes
- [ ] Court editor distinguishes select/move/draw-route/pan without user
      confusion (usability check, not just functional correctness)
- [ ] Play database supports search by tag/formation/family
- [ ] PDF export produces a print-safe, vector-quality playbook page

This section is a placeholder for planning purposes only and is not a
commitment to build v0.1 as described — see Open Questions in
`CXP-OVERVIEW.md`.

---

## Related Documents

- [`CXP-OVERVIEW.md`](CXP-OVERVIEW.md) — vision, architecture, full scoping capture
- [`DEV-PATH.md`](DEV-PATH.md) — phase history and design decisions
- [`DEV-PLAN.md`](DEV-PLAN.md) — current execution state and work queue
- [`../docs/DEV-RELEASE.md`](../docs/DEV-RELEASE.md) — portfolio release master
