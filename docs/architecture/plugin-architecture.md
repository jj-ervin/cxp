# CXP Plugin Architecture — Sport Packs

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## Why this exists

The play/practice engine must be sport-neutral from the start so
basketball → football (and beyond) is adding a module, not rewriting the
core. This document defines the interface a **Sport Pack** must
implement; the core engine (canvas, selection, frame/timeline, database,
export) never contains sport-specific logic.

```text
CXP Core Engine
├── Diagram canvas
├── Object and selection engine
├── Path and route engine
├── Frame/timeline engine
├── Play database
├── Search and tagging
├── Playbook builder
├── Export engine
└── Sport Packs (plugins)
    ├── Basketball (v1)
    └── Football (later)
```

## Sport Pack interface

A sport pack must provide:

```yaml
SportPack:
  key: string                       # "basketball"
  playing_surface:
    dimensions: { width, height, unit }
    markings: [svg_or_path_spec]    # court/field lines, hashes, etc.
  actors:
    offense_count: int
    defense_count: int
    numbering_scheme: string
  symbols:
    player_marks: [style_spec]      # offense/defense visual distinction
    path_types: [ { key, style, arrowhead } ]   # pass|cut|screen|route|block|...
  formation_templates: [ { name, actor_positions } ]
  validation_rules: [rule_spec]     # e.g. "exactly 5 offense, 5 defense" for basketball
  terminology: map                  # sport-specific labels for UI strings
  export_layout:
    page_template: spec
    diagram_scale_rules: spec
```

## What the core engine guarantees to every sport pack

- A `PlayFrame` (see `domain-model.md`) is sport-neutral: `positions` and
  `paths` are generic `{actor_id, x, y}` / `{actor_id, type, points,
  style}` shapes. The sport pack interprets `type` and supplies the
  symbol/style; the core engine never branches on sport.
- The frame/timeline engine (frames + generated transitions, not full
  keyframe animation in v1) is shared — a sport pack cannot opt into a
  different animation model.
- Export pipeline (PDF/PNG/SVG/JSON) is shared; a sport pack supplies only
  its `export_layout` spec, not its own renderer.

## Basketball Pack (v1 — the only pack actually built)

- 5 offense + 5 defense actors, auto-numbered
- Path types: pass, dribble, cut, screen, shot, defensive-move (curved and
  straight variants, arrowheads)
- Formation templates: five-out, four-out-one-in, horns, motion, etc.
  (seed set, expandable)
- Validation: exactly 5v5 unless explicitly overridden for drills

## Football Pack (later — not built, interface must not preclude it)

Flagged complexity the core engine must not assume away when basketball
is built:
- 22 actors, not 10
- Formation/personnel validation is materially more complex
- Route trees, blocking assignments, motion/shifts
- Presnap vs. postsnap state — the frame model may need a "phase" concept
  a basketball play never needs; if so, that phase concept must be added
  to the *core* frame schema as an optional field now, rather than
  reshaping `PlayFrame` when football is actually built.

**Action item carried to domain model review:** confirm `PlayFrame`
either already supports an optional `phase` tag or explicitly defer it
with a documented migration path — do not silently assume football will
"just fit."

## Marketplace interaction (later)

A sport pack also defines what marketplace categories make sense for it
(play families, formation packs, drill packs) — this is a thin mapping,
not new architecture, deferred to the Marketplace module design.

## Non-goals for this document

This is not a general third-party plugin/extension SDK. Per
`CXP-OVERVIEW.md`, built-in modules with optional per-organization
activation is the v1 approach; a public extension marketplace SDK is
explicitly deferred until the built-in module set is proven.
