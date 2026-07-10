# CXP Module Boundaries

**Status:** draft — architecture week output
**Updated:** 2026-07-10 (revised: added the Core / Vertical Pack / Sport Pack layering)

---

## The three-layer split (external dependencies)

```text
eco.ai   → intelligence, retrieval, governed AI behavior (external dependency)
Cockpit  → domain-neutral experience shell (external dependency, genericized)
CXP      → this repo — see internal layering below
```

CXP does not implement navigation shells, command palettes, or prompt
surfaces — those are Cockpit's job. CXP does not implement retrieval or
model orchestration — that's eco.ai's job. CXP owns the domain model
and the deterministic tools that operate on it.

## CXP's internal layering (Core / Vertical Pack / Sport Pack)

CXP itself is not "the coaching domain" — it's a domain-agnostic core
with coaching as its first vertical, mirroring `eco`'s
`eco-core → eco-edu/eco-health/...` SKU model (see `.eco/sku-inheritance.yaml`
and this repo's `sku-model.md` / `sku-inheritance.yaml`):

```text
cxp-core         → Organization, Cycle, Group, Member, Communication,
                    Calendar, Files, Search, Offline Sync, Audit
                    (domain-agnostic — see domain-model.md)
      ↓
cxp-coaching     → Team (extends Group), Player (extends Member), Roster,
                    Plays, Practice, Development, Statistics, ...
                    (the only Vertical Pack built so far)
      ↓
Sport Packs      → Basketball (v1), Football (later)
                    (see plugin-architecture.md)
```

A future vertical (music program, debate team, robotics club — see
`CXP-OVERVIEW.md` Future Vision) would sit beside `cxp-coaching`, both
inheriting `cxp-core`, neither depending on the other. Nothing below
`cxp-core` in this diagram may be assumed by Core; the dependency only
flows downward.

**Dependency direction rule:** CXP may depend on Cockpit and eco.ai
interfaces. Neither Cockpit nor eco.ai may depend on CXP-specific types.
If a Cockpit concept doesn't make sense without CXP loaded, it's not
actually domain-neutral yet — fix Cockpit, don't leak CXP into it.

## Portability

Per this portfolio's modularity-by-default rule: CXP must remain
self-contained. It may consume Cockpit and eco.ai as optional
integrations, but it must be able to run in a degraded standalone mode
(no Cockpit shell, no eco.ai) for local dev, testing, and for any future
deployment context that doesn't have those dependencies available. Never
hard-couple CXP's core domain logic to a sibling repo's runtime
assumptions.

---

## Module inventory and v1 boundary

| Module | Layer | v1? | Depends on | Notes |
| --- | --- | --- | --- | --- |
| Core (org/cycle/group/member/roles/calendar/search/sync/audit) | cxp-core | yes | — | Everything else depends on Core |
| Roster | cxp-coaching | yes | Core | Includes `MemberSensitive` split (Core-level) |
| Plays | cxp-coaching | yes | Core, Sport Pack | See `plugin-architecture.md` |
| Practice | cxp-coaching | yes | Core, Plays, Drills | |
| Drills | cxp-coaching | yes | Core | Ships alongside Practice |
| Player Development | cxp-coaching | phase 2 | Core, Roster | |
| Statistics | cxp-coaching | phase 2 | Core, Roster | Governed semantic layer required before any dashboard |
| Communications | cxp-core | phase 2 | Core | Verified Org gate before SMS/email limits unlock; core because messaging isn't coaching-specific |
| Coach Development | cxp-coaching | phase 3 | Core | Certifications tracked, not issued |
| Travel | cxp-coaching | phase 3 | Core, Calendar, Finance | Operational only |
| Finance | cxp-core | phase 3 | Core | Budgets/approvals aren't coaching-specific; connector to accounting systems, never the ledger of record |
| Marketplace | cxp-core | phase 3 | Ownership model | Needs `ai_use_permission` field from day one (see domain model); asset types are vertical-defined, the marketplace mechanics are not |
| Analytics (native) | cxp-core | phase 4 | Statistics | Governed metrics are vertical-defined; the metrics engine/visualization shell is not |
| Power BI/Fabric bridge | cxp-core | phase 4 | Analytics | Optional, org/enterprise only |
| Scouting | cxp-coaching | unscoped | — | Not designed yet |

Layer assignment matters: a module marked `cxp-core` must not import any
`cxp-coaching` type (`Team`, `Player`, `Play`, ...). If a "core" module's
code can't compile without a coaching-specific type, it isn't core yet —
that's a signal to either move it to `cxp-coaching` or generalize the
type it's reaching for.

A module being "phase 2/3/4" means its tables and API surface are *not*
built yet — not that they're disabled-by-default features sitting in the
codebase. Don't build ahead of the phase.

## Module contract

Every module (once built) must:

1. **Own its own tables.** No module reads another module's tables
   directly — it calls that module's API. This is what makes "a team
   enables only what it needs" actually true instead of aspirational.
2. **Declare its Core dependencies explicitly.** A module that needs
   `Roster` says so; it does not assume `Player` rows exist without
   checking Roster is enabled for that organization.
3. **Be independently toggleable per organization.** A volunteer team
   never sees Finance/Travel/Marketplace tables or routes; a Club-tier
   org does. Toggle state lives on `Organization`, not in client-side
   feature flags only.
4. **Emit audit records through Core**, not its own bespoke logging.

## Why Core matters more than any single feature module

The scoping conversation's strongest recurring point was that the
connective tissue (Roster → Position Groups → Drills → Practice →
Installed Plays → Game Plan) is the actual product advantage, not any one
module in isolation. That connective tissue is a `cxp-coaching` concern,
but it only works because it's built on `cxp-core`'s `Group`/`Member`
relationship model (see `domain-model.md`) — if Core's foreign keys and
permission model are wrong, every vertical built on top (coaching today,
others later) inherits the mistake. This is the concrete reason the
architecture week happens before any module code.

## What is explicitly out of CXP's authority

Per `CXP-OVERVIEW.md`'s closing principle — CXP owns operational context,
specialized platforms retain authoritative responsibility:

| Concern | System of record |
| --- | --- |
| Accounting / bookkeeping | QuickBooks / Xero / Business Central |
| Payment processing | Stripe |
| Advanced BI | Power BI / Fabric |
| Coach certifications (SafeSport, CPR, etc.) | Approved third-party training providers |

CXP tracks completion/status and integrates via connector interfaces. It
never becomes the ledger, the payment processor, or the certifying body.
