# CXP UX Philosophy

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## The acceptance bar: the Five-Minute Rule

A brand-new volunteer coach must be able to create an organization,
create a team, add players, and build tomorrow's practice — all in under
five minutes, with no prior training. Every design decision below is in
service of that bar. If a proposed feature makes the five-minute path
slower for the free-tier coach, it does not belong in that path — gate it
behind progressive disclosure instead.

## Interaction modes

CXP supports three interaction modes side by side, per the same
philosophy already established for Cockpit/eco.ai elsewhere in this
portfolio:

1. **Click-driven** — drag players, draw routes, build a practice
   timeline by hand. Always available; never requires AI.
2. **Prompt-driven** — "Build a 90-minute practice focused on transition
   defense." eco.ai drafts; the coach reviews and approves (see
   `ai-model.md`).
3. **Hybrid** — AI drafts, coach edits visually. This is expected to be
   the most common mode once eco.ai ships.

No essential coaching task may require the prompt-driven mode. AI is an
accelerant, never a gate (see Pricing in `CXP-OVERVIEW.md` — "don't gate
essential coaching behind AI").

## Command vocabulary

A unified command layer, surfaced through Cockpit's command palette:
`/play`, `/practice`, `/roster`, `/stats`, `/message`, `/develop`. These
are CXP-defined commands registered into a domain-neutral Cockpit
surface — Cockpit does not hardcode coaching vocabulary (see
`module-boundaries.md` dependency-direction rule).

## Workspace shape (illustrative, not a UI spec)

```text
┌──────────────────────────────────────────────┐
│ CXP · Varsity Basketball · 2026–27           │
├──────────────┬───────────────────────────────┤
│ Dashboard    │                               │
│ Team         │      Active workspace         │
│ Plays        │                               │
│ Practice     │   Play editor / roster /      │
│ Development  │   stats / communications      │
│ Stats        │                               │
│ Messages     │                               │
├──────────────┴───────────────────────────────┤
│ Ask eco.ai…   /practice   /play   /message   │
└──────────────────────────────────────────────┘
```

Custom workspace presets (Game Night, Practice Planning, Player
Development, Club Admin) are a later refinement, not a v1 requirement —
the base nav above must work first.

## Progressive disclosure by module activation

A solo volunteer coach's workspace shows Core + Roster + Plays +
Practice. Travel, Finance, Marketplace, Coach Development, and Club-tier
modules are invisible until the organization enables them (see
`module-boundaries.md` — module toggles live on `Organization`). This is
a UX requirement, not just a backend feature flag: an unused module must
not appear as a grayed-out upsell cluttering the five-minute path.

## Editor interaction discipline (play/practice canvas)

Per the feasibility analysis in `CXP-OVERVIEW.md`, the hardest UX problem
in CXP is not the data model — it's disambiguating, on the same canvas:

- select vs. move-player
- draw-route vs. edit-route
- pan/zoom vs. select
- multi-select
- touch/stylus gestures vs. mouse

This disambiguation is treated as roughly half the engineering effort of
the play editor and must be prototyped and user-tested before the editor
is considered done — functional correctness alone is not the bar.

## Accessibility

Dark mode, high contrast, screen reader support, keyboard navigation,
dyslexia-friendly font option, multiple languages, large text, and
color-blind-safe diagram palettes are v1-adjacent requirements (not a
Phase 4 afterthought) specifically because CXP explicitly differentiates
on this — most existing coaching software does it poorly.

## What this document does not cover

Visual identity, logo, color tokens, and brand voice are out of scope
here — CXP has no real brand input yet. Per this portfolio's Product
Identity Kit doctrine, do not invent brand decisions prematurely; adopt
PIK only once real brand/token input exists.
