# CXP Module Boundaries

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## The three-layer split

```text
eco.ai   → intelligence, retrieval, governed AI behavior (external dependency)
Cockpit  → domain-neutral experience shell (external dependency, genericized)
CXP      → the coaching domain (this repo)
```

CXP does not implement navigation shells, command palettes, or prompt
surfaces — those are Cockpit's job. CXP does not implement retrieval or
model orchestration — that's eco.ai's job. CXP owns the coaching domain
model and the deterministic tools that operate on it.

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

| Module | v1? | Depends on | Notes |
| --- | --- | --- | --- |
| Core (org/team/season/user/roles/calendar/search/sync/audit) | yes | — | Everything else depends on Core |
| Roster | yes | Core | Includes `PlayerSensitive` split |
| Plays | yes | Core, Sport Pack | See `plugin-architecture.md` |
| Practice | yes | Core, Plays, Drills | |
| Drills | yes | Core | Ships alongside Practice |
| Player Development | phase 2 | Core, Roster | |
| Statistics | phase 2 | Core, Roster | Governed semantic layer required before any dashboard |
| Communications | phase 2 | Core | Verified Org gate before SMS/email limits unlock |
| Coach Development | phase 3 | Core | Certifications tracked, not issued |
| Travel | phase 3 | Core, Calendar, Finance | Operational only |
| Finance | phase 3 | Core | Connector to accounting systems, never the ledger of record |
| Marketplace | phase 3 | Plays, Drills, Practice, ownership model | Needs `ai_use_permission` field from day one (see domain model) |
| Analytics (native) | phase 4 | Statistics | |
| Power BI/Fabric bridge | phase 4 | Analytics | Optional, org/enterprise only |
| Scouting | unscoped | — | Not designed yet |

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
module in isolation. That connective tissue lives in Core's relationship
model (see `domain-model.md`) — if Core's foreign keys and permission
model are wrong, every module built on top inherits the mistake. This is
the concrete reason the architecture week happens before any module code.

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
