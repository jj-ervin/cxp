# CXP Domain Model

**Status:** draft — architecture week output, precedes any implementation
**Updated:** 2026-07-10 (revised: domain-agnostic Core / Coaching Vertical Pack split)

---

## Layering decision

CXP's core is **domain-agnostic**, mirroring this portfolio's existing
`eco` SKU model (`eco-core` → verticals like `eco-edu`, `eco-health`,
`eco-finance`, each inheriting core and extending it — see
`.eco/sku-inheritance.yaml`). CXP applies the same shape:

```text
cxp-core (domain-agnostic)
  Organization, Cycle, Group, Member, Calendar, Communication,
  Files, Search, Offline Sync, Audit
    ↓ inherits, extends
cxp-coaching (the first Vertical Pack — everything built so far)
  Team (extends Group), Player (extends Member), Roster, Play,
  Practice, Development, Statistics, ...
    ↓ inherits, extends
Sport Packs (Basketball, Football, ...) — see plugin-architecture.md
```

**Why this matters now, not later:** the Future Vision section of
`CXP-OVERVIEW.md` already names other verticals (music directors, debate
teams, robotics clubs) as later possibilities. Drawing the Core/Vertical
line now — while there's still only one vertical to design against —
costs a naming decision. Drawing it after a second vertical exists would
cost a migration. This mirrors the precedent already set by `eco`.

**Naming approach:** tables are not renamed away from coaching-familiar
terms (`Team`, `Player`) purely for genericity — that would make the only
vertical CXP actually has harder to read for no present benefit. Instead,
`Team extends Group` and `Player extends Member`: the generic entity is
real and defined in Core, and the coaching vertical adds coaching-specific
columns/tables on top of it rather than duplicating the generic shape. A
future vertical (say, a music program) would define its own extension of
`Group`/`Member` without touching the coaching vertical at all.

---

## Design disciplines (apply to every entity below)

1. **Multi-tenant from the first table.** Every row that isn't a global
   reference table carries `organization_id`. There is no query path that
   can return cross-organization data by accident — see
   `security-model.md`.

2. **Event-sourced where it matters.** Statistics and audit-relevant
   mutations store the raw event plus its source; derived values are
   recalculated, never hand-edited in place.

3. **Versioned, not overwritten.** Plays, practice plans, and rosters keep
   prior versions.

4. **Soft ownership on every vertical-defined asset.** Plays, drills, and
   practice plans carry an explicit owner/license record from day one —
   this lives in Core (`OwnershipRecord`) precisely because ownership and
   licensing are not coaching-specific concerns; any future vertical's
   assets need the same shape.

---

## cxp-core (domain-agnostic)

### Organization

The tenant boundary, and the point where a vertical is selected.

```yaml
Organization:
  id: uuid
  name: string
  vertical: string           # "coaching" (only value that exists today)
  tier: string                # SKU key — see sku-model.md; not hardcoded to coaching's tiers
  verified: bool              # Verified Organization status (Communications gate)
  created_at: timestamp
```

### Cycle

Generic time-boxed grouping. The coaching vertical's "Season" *is* a
Cycle — not a separate table.

```yaml
Cycle:
  id: uuid
  organization_id: uuid
  label: string               # coaching vertical labels this "2026-27 Season"
  start_date: date
  end_date: date
  archived: bool               # cycles are archived, never deleted
```

### Group

Generic collection of members with a role structure. The coaching
vertical's "Team" *is* a Group with `sport` and coaching-specific fields
attached via the vertical extension table.

```yaml
Group:
  id: uuid
  organization_id: uuid
  cycle_id: uuid
  name: string
  vertical_type: string        # coaching vertical sets this to a sport key
```

```yaml
# Coaching vertical extension — same id as the Group row it extends.
CoachingGroupExtension:        # conceptually "Team"
  group_id: uuid               # = Group.id
  sport: string                 # sport pack key
  age_group: string
```

### Member

Generic participant. The coaching vertical's "Player" *is* a Member with
coaching-specific fields attached via extension, exactly like Group/Team.

```yaml
Member:
  id: uuid
  organization_id: uuid
  group_id: uuid
  name: string
  attributes: map              # vertical-defined custom attributes
```

```yaml
# Coaching vertical extension.
CoachingMemberExtension:       # conceptually "Player"
  member_id: uuid              # = Member.id
  jersey_number: string
  positions: [string]
  class_year: string
  dominant_hand: string?

MemberSensitive:                # Core-level — separate table/permission
  member_id: uuid               # scope regardless of vertical
  emergency_contacts: [...]
  medical_notes: text?
  academic_notes: text?
```

`MemberSensitive` lives in Core, not the coaching vertical, because
"don't casually join sensitive personal data into the base record" is a
domain-agnostic requirement, not a coaching-specific one — the same
protection applies whether the participant is a basketball player or a
robotics-club member.

### User / Membership (roles)

```yaml
User:
  id: uuid
  organization_id: uuid
  name: string
  email: string
  auth: passkey | password | oauth

Membership:                    # join table: which groups, which role
  user_id: uuid
  group_id: uuid
  role: string                  # role vocabulary is vertical-defined;
                                 # see security-model.md for the coaching
                                 # vertical's role set
```

### OwnershipRecord (Core value object, embedded on vertical assets)

```yaml
OwnershipRecord:
  owner_type: member | organization | shared | purchased_license | public_domain | marketplace_license
  owner_id: uuid
  license: string
  contributors: [uuid]
  ai_use_permission: none | retrieval_only | recommendation | adaptation | training
```

### Communication (Core)

```yaml
Message:
  id: uuid
  group_id: uuid
  channel: announcement | group_chat | subgroup | direct
  sender_id: uuid
  draft: bool                   # AI-drafted messages start here
  sent_at: timestamp?
  requires_approval: bool
```

### AuditRecord (Core, cross-cutting)

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

## cxp-coaching (Vertical Pack — the only vertical built so far)

Everything below extends or references Core entities above; nothing here
is itself domain-agnostic.

### PositionGroup

```yaml
PositionGroup:
  id: uuid
  group_id: uuid                # = Team (Group.id)
  name: string
  member_ids: [uuid]
```

### Play

```yaml
Play:
  id: uuid
  organization_id: uuid
  group_id: uuid                 # = Team
  sport: string                   # sport pack key — see plugin-architecture.md
  name: string
  family: string?
  formation: string?
  personnel: string?
  tags: [string]
  frames: [PlayFrame]
  version: int
  owner: OwnershipRecord          # Core value object
  created_at: timestamp
  superseded_by: uuid?
```

### PlayFrame

Sport-neutral shell; the sport pack (a layer *under* the coaching
vertical, per `plugin-architecture.md`) defines what a position/path
means geometrically.

```yaml
PlayFrame:
  index: int
  positions: [{ actor_id, x, y }]
  paths: [{ actor_id, type, points, style }]
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
  group_id: uuid                  # = Team
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
  member_id: uuid                  # = Player
  skill: string
  target: string
  due_date: date
  progress_notes: [{ date, note, coach_id }]
  linked_drills: [uuid]

SkillRating:
  member_id: uuid
  skill: string
  rubric_level: int
  comment: text
  date: date
  coach_id: uuid
```

### Statistics (versioned event layer)

```yaml
GameStatEvent:
  id: uuid
  game_id: uuid
  member_id: uuid?
  lineup_id: uuid?
  event_type: string                # sport-pack-defined
  value: number
  source: manual | csv_import | api
  imported_at: timestamp
  superseded_by: uuid?

Metric:                             # governed semantic layer
  id: string                        # e.g. "basketball.defensive_rebound_percentage"
  version: string
  formula: string
  required_inputs: [string]
  minimum_sample: map
  supported_levels: [member, lineup, group]
  default_visibility: coaches_only | group | public
```

---

## Forward-compatible sketches (not built in v1)

```yaml
Budget: { id, group_id, category, planned, committed, paid }
Expense: { id, budget_id, submitted_by, approved_by, status, receipt_ref }
Trip: { id, group_id, itinerary, member_ids, lodging, transportation }
MarketplaceListing: { id, asset_ref, price, creator_id, permission_scope }
CoachProfile: { id, user_id, certifications, philosophy, ce_completed }
```

---

## Relationship summary

```text
Organization (vertical: coaching)
  └── Cycle                                    [Core]
        └── Group ── CoachingGroupExtension    [Core ── Vertical]  ("Team")
              ├── Membership (User × role)      [Core]
              ├── Member ── CoachingMemberExtension   ("Player")
              │     ├── MemberSensitive          [Core]
              │     └── DevelopmentGoal, SkillRating   [Vertical]
              ├── PositionGroup                  [Vertical]
              ├── Play (versioned, owned)         [Vertical, owner: Core]
              ├── Drill (owned)                   [Vertical, owner: Core]
              ├── Practice ── PracticeSegment      [Vertical]
              ├── GameStatEvent ── Metric           [Vertical]
              └── Message                          [Core]
AuditRecord references any entity, cross-cutting, append-only    [Core]
```

## Open questions carried from CXP-OVERVIEW.md

- Exact `PlayFrame` path geometry schema is sport-pack-owned — needs a
  concrete basketball pack schema before further editor features land
  (see `plugin-architecture.md`).
- Whether `MemberSensitive` needs field-level (not just table-level)
  permission granularity is unresolved — deferred until Roster module
  implementation.
- Whether `Group`/`Member` should be physical tables with vertical
  extension tables (as modeled here) or a single wide table with
  vertical-owned nullable columns is an implementation detail deferred to
  schema/migration design — this document fixes the *conceptual*
  boundary, not the storage strategy.
