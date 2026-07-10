# CXP Security Model

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## Principles

1. **Zero Trust.** Every request is authorized against the caller's
   membership/role for the specific organization/team it targets — there
   is no implicit trust from "already logged in."
2. **Organization isolation.** No query path may return rows from an
   `organization_id` the caller isn't a member of. This is enforced at the
   data-access layer, not just in UI routing.
3. **Least privilege by role**, not by user judgment. A role's permission
   set is defined once, centrally, and every module consults it.
4. **Audit everything that mutates state.** See `AuditRecord` in
   `domain-model.md` — actor, timestamp, device, previous/new value.
5. **Finance gets stricter rules than the rest of the app** — see
   segregation-of-duties below.

## Roles

| Role | Scope | Can |
| --- | --- | --- |
| `owner` | Organization | Everything within the org, including billing |
| `admin` | Organization | Manage teams, users, roles; cannot change billing |
| `head_coach` | Team | Full read/write on Roster, Plays, Practice, Development, Communications for their team |
| `assistant_coach` | Team | Same as head_coach minus role/permission management, scoped further by head_coach if configured |
| `treasurer` | Organization or Team | Approve Finance transactions; cannot submit and approve the same transaction |
| `parent` | Player (their own child only) | View approved summaries; RSVP; receive communications |
| `player` | Self | View their own approved development data, if the org enables player visibility |

Role definitions live centrally (`Membership.role` in the domain model);
no module invents its own role enum.

## Permission evaluation

Every API call resolves to: `(actor, organization_id, team_id?, resource,
action)`. The authorization check is:

1. Does `actor` have a `Membership` in `organization_id` (or `team_id`)?
2. Does that `Membership.role` include `action` on `resource` per the
   central permission table?
3. For `PlayerSensitive` reads specifically: is there an explicit
   additional grant (not just team membership)? Base team membership does
   not imply access to medical/academic/emergency-contact data.

## Segregation of duties (Finance)

No single actor may both submit and approve the same transaction above a
per-organization configured threshold. This is enforced at the write
layer: an `Expense.approved_by` cannot equal `Expense.submitted_by` for
transactions where `amount > organization.approval_threshold`.

## Privacy by design (minors)

- `PlayerSensitive` is a separate table/permission boundary from `Player`
  (see domain model) — coach notes, ratings, and development observations
  do not automatically surface to parent or player views.
- Parent consent and coach/organization verification are Core-level
  workflows, not bolted onto Roster later.
- Data minimization: modules request only the fields they need; a module
  that doesn't touch medical data should never receive it in a payload.
- Configurable retention per organization; download-your-data and
  delete-your-data are Core capabilities, not per-module reimplementations.

## AI action boundary (cross-reference: `ai-model.md`)

eco.ai calls into CXP through the same permission layer as a human actor
— it is never given a privileged bypass. If eco.ai drafts a communication
or a practice plan, the draft is written by an actor identity scoped the
same way a coach's own write would be, and anything that would require
approval from a human still requires it when AI-originated.

## What's deferred

- Field-level (not table-level) permission granularity on
  `PlayerSensitive` — open question, see `domain-model.md`.
- Session/device management UI and account-recovery workflow — not
  designed yet, flagged for Phase 1 implementation planning, not this
  architecture pass.
- Encryption-at-rest specifics depend on the eventual hosting choice
  (see `CXP-OVERVIEW.md` Azure Architecture) — not finalized here.
