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


## 2026-10-06 reconciliation delta

Local main b7ae78aa668e243a435c45dc9c3dcdda19caa5fe matches private jj-ervin/cxp main. README's no-implementation claim was stale: editor/route tools, configurable basketball surfaces, frame actor playback, local play save/load/delete and PDF playbook export are implemented prototypes. Court configuration persists with the play and is passed to playback/export. Platform scaffolds exist for web/Windows/Linux/macOS/Android/iOS; scaffolding is not target-machine validation.

pubspec declares 1.0.0+1 with publish_to:none, while planning calls the product pre-v0.1. Treat this as a package/build metadata versus product-release discrepancy, not evidence of a shipped 1.0 product or permission to choose a new version. No tags/releases/application CI or new coach feedback were established. Existing four draft release criteria remain unchecked. Search/tag/folder storage, PNG/SVG export, playback ball marker, real-device profiling and coach retest remain open as already scoped.

Local storage is one SharedPreferences JSON list, not the intended versioned/multi-tenant backend. Main launches the court editor directly; org/team/practice onboarding, authorization/SKU enforcement, AI services, backend sync and future game/stat operations are not implemented by the architecture documents. Test repository fixtures do not certify real-browser persistence or coach usability. No youth/team record or existing user preference store was accessed.

Fresh exact-HEAD proof uses the installed Flutter 3.41.6/Dart 3.11.4 toolchain and locked dependencies in a disposable copy. Native Windows plugin setup requires symlink support unavailable in this session; its platform files are preserved outside the temporary web proof's detected platform path. No Developer Mode/system setting or SDK upgrade was made. Web/test proof is distinct from native installation/device/profile proof. Detailed results and limits are recorded in the reconciliation report.

Next: obtain the already-requested coach retest, establish one supported release/installation target, then scope open usability/performance/export/storage work. Do not build the queued architecture/SKU/game-operations brainstorms automatically. No feature, version bump, checkbox clearance, release, commit, push or deployment occurred.
