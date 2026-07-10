# CXP SKU Model

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## Why a formal SKU model

`CXP-OVERVIEW.md` already defines pricing tiers (Community, Coach Pro,
Team, Club, Enterprise). Those were pricing decisions. This document
turns them into **SKUs** — machine-checkable feature/module entitlements
— using the same inheritance pattern this portfolio already runs for
`eco` (`.eco/sku-inheritance.yaml`: `eco-core` → `eco-pro` → `eco-enterprise`,
plus verticals like `eco-edu`/`eco-health` that also inherit from core).

Without this, "a volunteer team never sees Finance/Travel/Marketplace"
(from `module-boundaries.md`'s module contract) is just a sentence in a
doc. With it, module visibility is a lookup against
`Organization.tier` → SKU definition → module list, enforced the same way
in every client and on the server — not reimplemented per screen.

## SKU inheritance

```yaml
cxp-community:                    # free
  inherits_from: []
  provides:
    - core                        # Organization, Cycle, Group, Member, Calendar, Audit
    - roster
    - plays
    - practice
    - drills
    - basic_export                # CSV/PDF, no branding controls

cxp-coach-pro:
  inherits_from: [cxp-community]
  extends:
    - player_development
    - eco_ai_assistant
    - advanced_export
    - custom_branding
    - advanced_statistics

cxp-team:
  inherits_from: [cxp-coach-pro]
  extends:
    - assistant_coaches
    - parent_portal
    - communications            # Verified Org gate still applies within this
    - shared_calendars
    - shared_playbooks

cxp-club:
  inherits_from: [cxp-team]
  extends:
    - multi_team_administration
    - coach_development
    - marketplace
    - finance
    - travel
    - organization_reporting
    - power_bi_bridge

cxp-enterprise:
  inherits_from: [cxp-club]
  extends:
    - dedicated_tenant
    - custom_semantic_models
    - regional_reporting
    - advanced_integrations
    - custom_retention_and_governance
```

This is the conceptual shape; the machine-readable version lives in
`sku-inheritance.yaml` at the repo root (same filename/location
convention as `.eco/sku-inheritance.yaml`).

## How a SKU maps to module visibility

Per `module-boundaries.md`'s module contract ("independently toggleable
per organization... toggle state lives on `Organization`"):

1. `Organization.tier` names a SKU (e.g. `cxp-team`).
2. The SKU's resolved `provides` set (its own `provides`/`extends` plus
   everything inherited) is the organization's enabled-module list.
3. Every module in the inventory table (`module-boundaries.md`) maps to
   exactly one SKU capability key (e.g. the Finance module requires the
   `finance` capability, first granted at `cxp-club`).
4. A module the organization's SKU doesn't grant is not merely
   read-only — it does not appear in navigation, does not accept API
   calls, and does not get a row in that organization's tables. This is
   what keeps the Community tier genuinely simple rather than a Club UI
   with everything grayed out.

## Capability-to-module mapping

| Capability key | Module | First granted at |
| --- | --- | --- |
| `core` | Core | cxp-community |
| `roster` | Roster | cxp-community |
| `plays` | Plays | cxp-community |
| `practice`, `drills` | Practice, Drills | cxp-community |
| `basic_export` | CSV/PDF export, unbranded | cxp-community |
| `player_development` | Player Development | cxp-coach-pro |
| `eco_ai_assistant` | eco.ai integration | cxp-coach-pro |
| `advanced_export`, `custom_branding` | Export/branding upgrades | cxp-coach-pro |
| `advanced_statistics` | Statistics (beyond basic totals) | cxp-coach-pro |
| `assistant_coaches`, `parent_portal` | Roster/Membership role expansion | cxp-team |
| `communications` | Communications | cxp-team |
| `shared_calendars`, `shared_playbooks` | Calendar, Plays (multi-user) | cxp-team |
| `multi_team_administration` | Organization-level admin | cxp-club |
| `coach_development` | Coach Development | cxp-club |
| `marketplace` | Marketplace | cxp-club |
| `finance` | Finance | cxp-club |
| `travel` | Travel | cxp-club |
| `organization_reporting`, `power_bi_bridge` | Analytics, Power BI bridge | cxp-club |
| `dedicated_tenant`, `custom_semantic_models`, `regional_reporting`, `advanced_integrations`, `custom_retention_and_governance` | Enterprise-only concerns | cxp-enterprise |

## Relationship to Verticals

SKU tiers and Verticals (`domain-model.md`'s `cxp-core`/`cxp-coaching`
split) are orthogonal. A future music-program vertical would define its
own SKU ladder (`cxp-music-community`, `cxp-music-pro`, ...) that also
inherits `cxp-core`'s base capabilities — it does not inherit
`cxp-coaching`'s tiers. The `Organization.vertical` field selects which
Vertical Pack is active; `Organization.tier` selects which SKU within
that vertical's ladder is active. Both fields exist on `Organization`
today (see `domain-model.md`) even though only the coaching vertical and
its five tiers are implemented.

## What this doesn't decide

- Billing/subscription mechanics (Stripe integration, proration,
  trials) — that's an implementation detail of the Finance/Payments
  connector, not a SKU-model concern.
- Whether SKU capability checks are enforced client-side, server-side,
  or both — `security-model.md`'s Zero Trust principle implies
  server-side is authoritative regardless of what the client does.
- The "Earn Pro" contribution-based unlock mechanic from
  `CXP-OVERVIEW.md` — that would grant a temporary `cxp-coach-pro`
  entitlement without payment; the granting mechanism isn't designed
  here.
