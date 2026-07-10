# CXP Domain Model

**Status:** draft — architecture week output, precedes any implementation
**Updated:** 2026-07-10

Scope: the v1 (CXP Coach) domain. Finance, Travel, Marketplace, and Coach
Development entities are sketched at the end for forward-compatibility but
are not built in v1.

---

## Design disciplines (apply to every entity below)

1. **Multi-tenant from the first table.** Every row that isn't a global
   reference table carries `organization_id`. There is no query path that
   can return cross-organization data by accident — see
   `security-model.md`.
2. **Event-sourced where it matters.** Statistics and audit-relevant
   mutations store the raw event plus its source; derived values are
   recalculated, never hand-edited in place. See "Statistics" below.
3. **Versioned, not overwritten.** Plays, practice plans, and rosters keep
   prior versions. A coach can always see what a play looked like last
   season.
4. **Soft ownership on every coaching asset.** Plays, drills, and practice
   plans carry an explicit owner/license record from day one, even before
   the Marketplace exists — retrofitting ownership onto years of assets
   later is much harder than starting with the field.

---

## Core entities (v1)

### Organization
The tenant boundary. A volunteer team and a multi-team club are both an
`Organization` — the difference is how many `Team`s and `User`s hang off
it, not a different schema.

```yaml
Organization:
  id: uuid
  name: string
  tier: community | coach_pro | team | club | enterprise
  verified: bool            # Verified Organization status (Communications gate)
  created_at: timestamp
```

### Season
```yaml
Season:
  id: uuid
  organization_id: uuid
  label: string              # "2026-27"
  start_date: date
  end_date: date
  archived: bool             # seasons are archived, never deleted
```

### Team
```yaml
Team:
  id: uuid
  organization_id: uuid
  season_id: uuid
  name: string
  sport: enum                # basketball | football | ... (sport pack key)
  age_group: string
```

### User / Coach
```yaml
User:
  id: uuid
  organization_id: uuid      # primary org; a user can be invited into others
  name: string
  email: string
  auth: passkey | password | oauth

Membership:                  # join table: which teams, which role
  user_id: uuid
  team_id: uuid
  role: owner | admin | head_coach | assistant_coach | treasurer | parent | player
```

Role definitions and the permission matrix live in `security-model.md` —
this file only defines the join shape.

### Player
```yaml
Player:
  id: uuid
  organization_id: uuid
  team_id: uuid
  name: string
  jersey_number: string
  positions: [string]
  class_year: string
  dominant_hand: string?
  attributes: map            # custom, sport-pack-defined attributes

PlayerSensitive:              # separated table, tighter permission scope
  player_id: uuid
  emergency_contacts: [...]
  medical_notes: text?
  academic_notes: text?
```

`PlayerSensitive` is a distinct table/permission boundary, not a set of
columns on `Player` — this is a hard requirement from the scoping
conversation (health/academic/minor data must not be casually joined into
the base roster record).

### PositionGroup
```yaml
PositionGroup:
  id: uuid
  team_id: uuid
  name: string
  player_ids: [uuid]
```

### Play
```yaml
Play:
  id: uuid
  organization_id: uuid
  team_id: uuid
  sport: string               # sport pack key — determines editor/validation rules
  name: string
  family: string?             # e.g. "Horns", "Motion"
  formation: string?
  personnel: string?
  tags: [string]
  frames: [PlayFrame]         # ordered — see Sport Pack interface for frame schema
  version: int
  owner: OwnershipRecord
  created_at: timestamp
  superseded_by: uuid?        # version chain, never overwritten in place
```

### PlayFrame
Sport-neutral shell; the sport pack defines what a "position" and "path"
mean geometrically.

```yaml
PlayFrame:
  index: int
  positions: [{ actor_id, x, y }]
  paths: [{ actor_id, type, points, style }]   # type: pass|cut|screen|route|...
  annotations: [string]
```

### Drill
```yaml
Drill:
  id: uuid
  organization_id: uuid
  name: string
  sport: string
  duration_minutes: int
  equipment: [string]
  skill_tags: [string]
  linked_plays: [uuid]
  owner: OwnershipRecord
```

### Practice / PracticeSegment
```yaml
Practice:
  id: uuid
  team_id: uuid
  date: date
  duration_minutes: int
  segments: [PracticeSegment]

PracticeSegment:
  start_offset_minutes: int
  duration_minutes: int
  label: string
  linked_drill_id: uuid?
  linked_play_ids: [uuid]
  position_group_id: uuid?
  coach_assignments: [uuid]
```

### DevelopmentGoal / SkillRating
```yaml
DevelopmentGoal:
  id: uuid
  player_id: uuid
  skill: string
  target: string
  due_date: date
  progress_notes: [{ date, note, coach_id }]
  linked_drills: [uuid]

SkillRating:
  player_id: uuid
  skill: string
  rubric_level: int
  comment: text
  date: date
  coach_id: uuid
```

### OwnershipRecord (embedded on Play/Drill/Practice-template/etc.)
```yaml
OwnershipRecord:
  owner_type: coach | organization | shared | purchased_license | public_domain | marketplace_license
  owner_id: uuid
  license: string
  contributors: [uuid]
  ai_use_permission: none | retrieval_only | recommendation | adaptation | training
```

`ai_use_permission` exists from v1 even though the Marketplace doesn't
ship until later — it is the field that lets eco.ai's retrieval layer
respect creator intent later without a painful migration.

### Statistics (versioned event layer)
```yaml
GameStatEvent:
  id: uuid
  game_id: uuid
  player_id: uuid?
  lineup_id: uuid?
  event_type: string          # sport-pack-defined
  value: number
  source: manual | csv_import | api
  imported_at: timestamp
  superseded_by: uuid?        # corrections create a new event, never edit in place

Metric:                       # governed semantic layer
  id: string                  # e.g. "basketball.defensive_rebound_percentage"
  version: string
  formula: string
  required_inputs: [string]
  minimum_sample: map
  supported_levels: [player, lineup, team]
  default_visibility: coaches_only | team | public
```

### Communication
```yaml
Message:
  id: uuid
  team_id: uuid
  channel: announcement | team_chat | position_group | direct
  sender_id: uuid
  draft: bool                 # AI-drafted messages start here
  sent_at: timestamp?
  requires_approval: bool
```

### AuditRecord (cross-cutting)
```yaml
AuditRecord:
  id: uuid
  organization_id: uuid
  actor_id: uuid
  entity_type: string
  entity_id: uuid
  action: string
  previous_value: json?
  new_value: json?
  device: string?
  timestamp: timestamp
```

---

## Forward-compatible sketches (not built in v1)

These exist here only so v1 tables don't have to be reshaped later — no
implementation obligation attaches to them yet.

```yaml
Budget: { id, team_id, category, planned, committed, paid }
Expense: { id, budget_id, submitted_by, approved_by, status, receipt_ref }
Trip: { id, team_id, itinerary, roster_ids, lodging, transportation }
MarketplaceListing: { id, asset_ref, price, creator_id, permission_scope }
CoachProfile: { id, user_id, certifications, philosophy, ce_completed }
```

---

## Relationship summary

```text
Organization
  └── Season
        └── Team
              ├── Membership (User × role)
              ├── Player ── PlayerSensitive
              │     └── DevelopmentGoal, SkillRating
              ├── PositionGroup
              ├── Play (versioned, owned)
              ├── Drill (owned)
              ├── Practice ── PracticeSegment
              ├── GameStatEvent ── Metric (governed)
              └── Message
AuditRecord references any entity, cross-cutting, append-only
```

## Open questions carried from CXP-OVERVIEW.md

- Exact `PlayFrame` path geometry schema is sport-pack-owned — needs a
  concrete basketball pack schema before the editor prototype (see
  `plugin-architecture.md`).
- Whether `PlayerSensitive` needs field-level (not just table-level)
  permission granularity is unresolved — deferred until Roster module
  design.
