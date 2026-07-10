# DEV-RELEASE — CXP (Coach Experience Platform)

**AUTHORITY LEVEL: AL:2**
**Status:** Scaffold — no release gates yet, no code exists
**Created:** 2026-07-10
**Authority:** Owned by this repo. Sequencing and cross-repo dependencies,
if any emerge, defer to [`docs/DEV-RELEASE.md`](../docs/DEV-RELEASE.md)
(portfolio master).

---

## Current State Summary

CXP is in **Phase 0 — Scoping** (see `DEV-PATH.md`). A full scoping
conversation has been captured in `CXP-OVERVIEW.md`. Nothing has been
built. This file exists so the repo has a GC-conformant release doc from
day one — it intentionally has no release contract yet.

---

## What "release-ready" will require

Per this portfolio's gap-closure principle (see
`docs/DEV-RELEASE.md`), a release is not real until:

1. **Mechanism exists** — not a document, working code/schema/spec
2. **Mechanism is tested** — a test would fail if it broke
3. **Mechanism is observable** — some signal is emitted when it runs
4. **Mechanism is discoverable** — a stranger can find and understand it

None of the four apply yet — there is no mechanism.

---

## Release v0.1 — Basketball MVP (not started)

**Status:** Planned — blocked on the architecture week (CXP.02 in
`DEV-PLAN.md`)

### What would ship

- Drag-and-drop basketball court editor
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
