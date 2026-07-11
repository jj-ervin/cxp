# CXP — Coach Experience Platform

**Status:** SCOPING — vision and architecture capture, no implementation yet
**Owner:** 20Amp Labs
**Updated:** 2026-07-10

This document is the canonical capture of the CXP scoping conversation. It
does not represent committed engineering scope — see `DEV-PLAN.md` for what
is actually being built next. Everything below is directional.

---

## Vision

> **A visual operating workspace for coaches and teams.**

Not a play-diagram tool. Not "TeamSnap with AI." Not "Hudl Lite." CXP is
being scoped as a **Coach Operating System** — the system of record for a
season, a team, and (eventually) an organization — built the same way this
portfolio approaches DXP: one coherent core, modular capabilities layered on
top, AI as an assistant rather than the product.

## Mission

> **Help every coach coach better — regardless of budget.**

A volunteer coach should be able to download CXP, create a team in five
minutes, and run an entire season for free without the product feeling like
a crippled demo. Organizations and competitive programs pay for
collaboration, communication, administration, player development,
analytics, and AI productivity — not because basic coaching tools are
locked away.

**The Five-Minute Rule:** a brand-new volunteer coach should be able to
create an organization, create a team, add players, and build tomorrow's
practice — all in under five minutes. If CXP can't clear that bar, nothing
else about the platform matters yet.

**Tagline candidates:**
- "Plan. Coach. Develop. Grow."
- "Everything your team needs. One platform."
- "Built for coaches. Powered by experience."
- "Create the play. Teach it in practice. Organize the team."

---

## Architecture

### The core split

> **eco provides intelligence and governance. Cockpit provides the operating
> experience. CXP provides the coaching system.**

```text
eco.ai            → intelligence, retrieval, governed AI behavior
Cockpit           → domain-neutral experience shell (nav, command palette,
                     prompt surface, workspaces, extensions, sync/status)
CXP               → the coaching domain: teams, rosters, plays, practice,
                     development, comms, stats, finance, travel, marketplace
```

Cockpit must stay a **domain-neutral shell**, not a developer tool awkwardly
reused for coaches. Concepts borrowed from DXP-flavored Cockpit usage need to
be genericized before CXP relies on them:

| Developer-flavored concept | CXP-neutral equivalent |
| --- | --- |
| Repository | Workspace / Organization |
| Build status | Activity status |
| Terminal panel | Command / assistant panel |
| Project context | Domain context |
| Developer shortcuts | Domain commands |

This keeps CXP portable and not secretly coupled to DXP's assumptions —
consistent with this portfolio's modularity-by-default rule: every product
must stay self-contained and not depend on a sibling repo's shared
environment.

### Sport-neutral play/practice engine

The play editor and practice tooling are the most technically demanding
part of CXP, so the core must be built sport-neutral from day one rather
than basketball-only with football bolted on later:

```text
CXP Application
├── Diagram canvas
├── Object and selection engine
├── Path and route engine
├── Frame/timeline engine
├── Play database
├── Search and tagging
├── Playbook builder
├── Export engine
└── Sport modules
    ├── Basketball
    └── Football (later)
```

Each sport module defines its own playing surface, player counts, symbols,
route styles, formation templates, validation rules, terminology, and
export layouts. The canvas, selection engine, frame engine, database, and
export pipeline are shared. This is what prevents CXP from becoming two
unrelated applications when football (22 players, formation/personnel
validation, route trees, blocking assignments, motion/shifts, defensive
fronts, presnap/postsnap state) is added.

**Difficulty estimate:** basketball editor ~6/10, football editor ~8/10,
both sports polished in one application ~9/10. Basketball is the right
starting sport — fewer players, fewer formation rules, smaller surface.

**Where the real difficulty lives:**
1. **Interaction design**, not data modeling. The editor must disambiguate
   select vs. move-player vs. draw-route vs. edit-route vs. pan/zoom vs.
   multi-select vs. touch gesture. A technically correct editor can still
   feel terrible — polished interaction is roughly half the project.
2. **Movement/animation model.** Decide early: static diagram, frame
   sequence, full timeline, or frames + interpolation. **Frames are the
   right v1 choice** — place players in Frame 1, add Frame 2, move them,
   let the app generate the transition. Full timeline animation is a later
   upgrade, not a v1 requirement.
3. **Export quality.** PNG is trivial; a genuinely good PDF playbook needs
   consistent page layout, headers/footers, play numbering, coaching notes,
   multi-diagram pages, branding, a table of contents, print-safe scaling,
   and vector-quality diagrams. v1 export formats: **PDF, PNG, SVG, JSON**
   (possibly PowerPoint). Do not attempt to export into competitors'
   proprietary formats without a documented API.

### Domain data model (illustrative)

```text
Player
  ├── Attendance
  ├── Development
  ├── Stats
  ├── Practice
  ├── Games
  ├── Communication
  └── Video
```

The connective thread across modules:

```text
Roster → Position groups → Drills → Practice plan → Installed plays → Game plan
```

Player Development is the intended long-term connective spine: every drill,
practice, game observation, evaluation, and coach note should feed one
continuous player growth record instead of sitting in isolated modules.

---

## Modules

```text
CXP
├── Core
│   ├── Teams and seasons
│   ├── Coaches and users
│   ├── Roles and permissions
│   ├── Calendar
│   ├── Files and exports
│   ├── Notifications
│   ├── Search
│   ├── Offline sync
│   └── Audit / version history
├── Cockpit (shell — see Architecture)
├── eco.ai (assistant layer — see AI Strategy)
├── Teams
├── Organizations
├── Roster
│   ├── Players, jersey numbers, positions
│   ├── Height/class/eligibility
│   ├── Contact and emergency info
│   ├── Availability status
│   ├── Depth chart / rotation groups
│   └── Season-to-season roster history
│       (health/academic/minor-player data separated behind tighter
│        permissions, not mixed into the base roster record)
├── Player Development
│   ├── Development plans (goals, target, progress, due date, linked drills)
│   ├── Skill matrix (rubric + coach comments, not bare 1–10 ratings)
│   ├── Progress timeline (evaluations, highlights, milestones)
│   ├── Video integration (clips tagged to skills; eco.ai summarizes
│   │   recurring themes, never replaces coach judgment)
│   └── Team dashboard (attendance, goal completion, skills needing focus)
├── Practice
│   ├── Practice-plan builder, timed segments
│   ├── Drill library
│   ├── Linked plays, position groups, equipment
│   ├── Attendance, coaching assignments, notes
│   └── Practice Intelligence (flags when practice-time distribution
│       drifts from the coach's stated philosophy)
├── Plays / Playbook
│   ├── Play creator, play database
│   ├── Formations, sets, play families
│   ├── Animation (frame-based, see Architecture)
│   └── Playbook builder, PDF/image export
├── Statistics
│   ├── Import (CSV/Excel/manual/bulk, reusable field-mapping templates)
│   ├── Versioned event-based data layer (store the game record + source,
│   │   not just editable totals)
│   ├── Governed semantic layer (every metric has a canonical, versioned
│   │   formula, required inputs, minimum sample size, visibility default)
│   ├── Derived metrics and trends
│   └── Export (CSV/Excel/PDF/JSON, field-level include/exclude control)
├── Communications
│   ├── Announcements, RSVP/availability, messaging, shared resources
│   ├── Verified Organizations (identity/trust unlock for schools/clubs)
│   └── Community Communications tier (limited free SMS/email for
│       verified volunteer orgs; paid tiers raise the limits)
├── Travel (CXP Club — operational, not a booking engine)
│   ├── Trip planning, travel roster, itinerary
│   ├── Room/transportation/meal assignments
│   ├── Travel documents, equipment checklist
│   └── Auto-syncs to Calendar, Communications, Budget, Analytics
├── Finance (CXP Club — operations, not accounting)
│   ├── Season budgets, planned vs. actual, fees, fundraising
│   ├── Purchase/reimbursement approval workflow
│   │   (submit ≠ approve; segregation of duties above a threshold)
│   └── Connector interface to QuickBooks/Xero/Business Central;
│       Stripe for payment processing — CXP is never the ledger of record
├── Marketplace
│   ├── Plays, drills, practice plans, player-development programs,
│   │   club templates (handbooks, registration packets, evaluation forms)
│   └── Creator permission model: viewable / searchable / usable for
│       recommendations / AI-retrievable / adaptable / trainable — set
│       per asset by the creator
├── Coach Development (CXP Club)
│   ├── Coach profile: experience, certifications, licenses, specialties,
│   │   philosophy, continuing education
│   ├── Coaching agreements (code of conduct, background check ack,
│   │   concussion protocol ack, etc. — tracked, not enforced by CXP)
│   └── eco.ai as coaching mentor (age-group-appropriate suggestions,
│       common new-coach mistakes)
├── Scouting
├── Analytics
│   ├── CXP Metrics (calculates, governed definitions)
│   ├── CXP Analytics (native, offline-capable visualization)
│   └── Power BI / Fabric (optional org/enterprise BI expansion layer —
│       never a core dependency)
└── Administration
```

Every team/org enables only the modules it needs; the free/volunteer tier
never sees Travel, Finance, Coach Development, or the Club-tier modules
unless they opt in.

---

## Security — Zero Trust

- MFA, passkeys, role-based access control
- Every request verified (Zero Trust authorization), least-privilege
  permissions
- Organization isolation — clubs cannot see another club's data
- Device/session management, audit logs on every mutating action:
  actor, timestamp, device, previous value, new value
- Encryption at rest and in transit, secure backups, account recovery
- Finance module gets stricter controls than general team management:
  no single actor both submits and approves a transaction above a
  configured threshold

## Privacy by design (minors)

- Parent consent workflows, coach/organization verification
- Child privacy controls, data minimization, configurable retention
- Download-your-data / delete-your-data
- Fine-grained sharing permissions
- Coach notes, ratings, and development observations do not automatically
  surface in parent or player views

## Governance

Borrowed directly from this portfolio's Governance Commons patterns:
- Every season archived, every roster/practice/play versioned
- Every communication logged, nothing silently disappears
- Provenance on every asset (owner, license, version history, contributors)

---

## AI Strategy

**Guiding principle (same as Niji):**
> **eco.ai should augment the coaching workflow — not replace the coach.**

The play editor, roster, and practice planner remain deterministic. eco.ai
sits beside the coach as a copilot with context: roster, attendance,
philosophy, practice history, installed plays, and development goals.

### What eco.ai should do
- Draft plays from a prompt ("half-court offense vs. 2-3 zone, one
  dominant post player")
- Semantic play-database search
- Build a practice from the drill library, weighted toward recent weak
  areas
- Suggest substitutions/rotations based on foul trouble, fatigue,
  availability
- Summarize scouting reports and tendencies
- Draft parent/team communications (draft-first, never auto-sent)
- Explain statistical trends with evidence, sample size, and confidence —
  and explicitly separate correlation from causation

### Hard guardrails
- No diagnosing injuries or giving unsupervised return-to-play advice
- No public ranking/humiliation of children
- No unsupervised private AI-initiated messages to minors
- No eligibility decisions
- No presenting subjective evaluations as objective fact
- No unsafe conditioning-load recommendations
- No autonomous spend approval, transfers, or accounting-record changes
- AI-generated communications and practice plans require coach approval
  before sending/adopting

### Layered knowledge model (post-MVP)
A "basketball domain pack" for eco.ai, built on an existing LLM rather than
trained from scratch:

```text
General LLM
  + Curated basketball knowledge (canon, RAG-backed, cited)
  + Philosophy profiles (motion, pace-and-space, pack-line, etc. —
    structured, explicitly separating philosophy from fact)
  + Coach doctrine (this coach's terminology, rules, priorities)
  + Team-specific context (roster, plays, history, goals)
  + Deterministic play/practice tools
  = Basketball coaching assistant
```

Build order: prompting/rules → retrieval (with citations) → tools
(search, draft, query) → evaluation by qualified coaches → fine-tuning
only once enough high-quality, licensed interaction examples exist.
Content sourcing must avoid copied books/paid clinics/proprietary
playbooks without permission — prefer public resources, licensed
material, commissioned original content, and marketplace content whose
creators have explicitly granted AI-use rights.

### Transparent AI (every recommendation)
Every AI output should expose: **Recommendation → Why? → Confidence →
Evidence used → Coach approval required.**

---

## Data Model

See Architecture → Domain data model. Key disciplines carried through every
module:

- **Versioned, event-based, not editable totals.** Store the raw event and
  its source; recalculate derived metrics rather than overwriting them.
- **Governed semantic layer** for every metric (id, version, formula,
  required inputs, minimum sample, supported levels, default visibility).
- **Explicit ownership/licensing model** for every coaching asset (play,
  drill, practice plan, curriculum): owner, copyright holder, license,
  version history, contributors — same discipline as GitHub repo
  ownership/licensing.
- **Raw data / derived metric / AI interpretation / coach decision** are
  kept as four distinct, separately-labeled layers so eco.ai never
  presents an inference as a recorded fact.

---

## Roadmap

### Phase 1 — Foundation (4–6 weeks)
Cockpit shell, nav, command palette, eco.ai prompt surface, auth,
organizations, teams. Basketball: roster, practice planner, play creator,
play library, basic player profiles. No marketplace, finance, travel, or
analytics engine yet.

### Phase 2
Player Development, Statistics, Communications, Calendar, Attendance.
Enough to run a full season.

### Phase 3
Coach Development, Organization Management, Travel, Budgets, Marketplace.
This is where clubs start buying.

### Phase 4
Power BI/Fabric, deeper Azure AI integration, public APIs, Coach Network,
certification tracking.

### Versioned module rollout
```text
v0.1  Play Designer
v0.2  Practice Planner
v0.3  Player Development
v0.4  Communications
v0.5  Statistics
v0.6  Club Management
v0.7  Marketplace
v0.8  Coach Development
v1.0  CXP Platform
```

### Effort reality-check (solo dev + AI assistance, part-time/uneven pace)

| Milestone | Approximate scope |
| --- | --- |
| Clickable UI prototype | several days – 2 weeks |
| Basic basketball diagram editor | 4–8 weeks |
| Useful basketball MVP with database/export | 2–4 months |
| Polished commercial basketball product | 6–12 months |
| Football module (reuses core engine) | +4–8 months |
| Full collaborative coaching platform | 12–24+ months |

The core editor is built reusable so football does not mean starting over.

**Recommended one-week pre-work before any code:** the same discipline
applied to Governance Commons — architecture, domain model, module
boundaries, UX philosophy, design language, plugin architecture, security
model, AI model. Good architecture compounds; skipping this step tends to
cost more later than it saves now.

---

## MVP

Strongest v0.1 framing: **basketball only, offline-first**, and make four
things exceptional rather than many things mediocre:

1. Drag-and-drop court editor
2. Frame-based play animation
3. Searchable play database
4. Beautiful PDF playbook export

Four-week compressed cut (if aiming for a fast public MVP):

- **Week 1** — Cockpit shell, auth, organizations, teams, dashboard, app
  shell, local storage + sync architecture, permissions
- **Week 2** — Interactive play designer: court canvas, drag-and-drop
  players, routes/screens/passes, save/library, PNG/PDF export
- **Week 3** — Practice planner, drill library, calendar, attendance,
  basic roster, basic development notes
- **Week 4** — eco.ai: practice generation, play search, AI summaries,
  AI-drafted parent announcements, coaching assistant

MVP feature list (basketball editor specifics):
- Drag five offense + five defense onto a court, auto numbering/labels
- Draw passes, dribble paths, cuts, screens, shots, defensive movement
  (curved and straight, arrowheads)
- Multiple sequential frames per play
- Play metadata: name, description, tags, personnel, coaching notes
- Searchable folders/playbooks
- Undo/redo/duplicate/mirror/reset
- Export: PNG, PDF, SVG, printable playbook pages
- Presentation/animation mode

**The Five-Minute Rule is the MVP acceptance bar** (see Mission).

---

## Pricing

| Tier | Target | Price |
| --- | --- | ---: |
| 🟢 Community | Volunteer coaches, rec leagues | Free |
| 🔵 Coach Pro | Individual coaches | ~$12/mo or $99/yr |
| 🟣 Team | Team with assistants | ~$29–40/mo |
| 🟠 Club | Youth clubs and schools | ~$149–500+/mo |
| ⚫ Enterprise | Districts, colleges, associations | Custom |

**Community (free) includes, genuinely usable for a full season:**
one team, play creator, play database, basic playbook export, practice
planner, basic roster, limited storage, CSV import/export, basic team
dashboard, basic fee tracking, one team budget with manual entry.

**Do not gate essential coaching behind AI.** A coach can always build a
practice manually; AI is a time-saver, not the only path.

**Earn Pro:** volunteer coaches can unlock Pro time by contributing —
sharing drills, publishing plays, moderating, reporting bugs, translating,
writing articles.

## Business Model

- Workflow consolidation is the pitch, not AI novelty: "one workspace, one
  team, one season" replacing TeamSnap + Hudl/stat software + Calendar +
  Word docs + paper + YouTube + GroupMe + Drive + whiteboard.
- **B2B (clubs/organizations) is likely the real revenue driver**, not
  individual coach subscriptions — a club with 18 teams/36 coaches doesn't
  blink at $200–300/mo if it saves real coordination time.
- Marketplace take rate (~20%) on creator-sold plays/drills/curricula —
  eventually an economy, not just a feature.
- **North-star metric: Weekly Active Coaches (WAC)**, not signups or
  downloads. A coach opening CXP Sunday night, Monday/Wednesday practice,
  and Friday game is evidence CXP is part of the routine.
- Three-product staging for the wider vision (not v1 scope):
  - **CXP Coach** (the business, start here): plays, practice, roster,
    player development, communications, stats, eco.ai
  - **CXP Club** (2–4 yrs): org management, coach management,
    certifications, marketplace, safety, reporting
  - **CXP Network** (long-term): coach profiles, portfolios, mentorship,
    recruiting, community, continuing education

## Technical Stack

**Client:** Flutter — cross-platform (Windows, macOS, web, Android, iPad),
strong touch/stylus support, custom canvas via `CustomPainter`,
offline-first, local storage with optional cloud sync. Leverages existing
Kinjuu experience with the same stack.

Possible stack:
- **Flutter** — UI and canvas
- **Riverpod** — application state
- **Drift/SQLite** — local storage
- **Supabase or Firebase** — optional account sync
- **CustomPainter** — court/field, players, routes
- **PDF/SVG export libraries**
- **Versioned JSON** as the canonical play representation (not a
  proprietary binary format)

**Backend (initial build):**
- Azure Container Apps or App Service
- Azure Database for PostgreSQL
- Azure Blob Storage (files, video)
- Microsoft Entra External ID (identity)
- Azure Functions (imports, exports, scheduled jobs)
- Application Insights (telemetry)
- Power BI export templates for advanced users

## Azure Architecture

### Initial build
See Technical Stack → Backend above.

### Growth stage
- Event Grid or Service Bus for domain events
- Fabric Lakehouse/Warehouse for analytical history
- Power BI Embedded for club dashboards (row-level security scoping
  club director → head coach → assistant → parent visibility; CXP's own
  application authorization remains authoritative as defense-in-depth)
- Key Vault for secrets
- API Management for external integrations
- Microsoft Foundry for governed eco.ai deployment

### Later, at real scale
- Fabric Real-Time Intelligence for live event streams
- Eventstream-based stat feeds
- Automated anomaly detection
- Organization benchmarking (privacy-preserving, opt-in, cohort-level
  only — e.g. "72nd percentile attendance," never child-level disclosure)
- Streaming game/wearable data
- Azure Data Explorer for large event/telemetry/time-series workloads,
  connected to Power BI

**Discipline throughout:** CXP owns operational context; specialized
platforms retain authoritative responsibility elsewhere — QuickBooks/
Xero/Business Central for accounting, Stripe for payments, Power BI/
Fabric for advanced BI, approved training providers for certifications.
CXP integrates; it does not reinvent those industries.

---

## Future Vision

- **CXP Network**: coach professional profiles, published-content
  reputation (drills/plays/practice plans, downloads, mentorship),
  searchable by specialty ("zone defense expert," "U12 girls basketball")
- **Coaching Portfolio**: a living record (certifications, teams coached,
  seasons, philosophy, published resources, marketplace earnings, awards,
  CE) a coach can carry to a new club instead of rebuilding from scratch
- **Sport-agnostic core**: roster/calendar/communication/player-development
  patterns don't care which sport; only the play engine, drill library,
  and stat schema change per sport (Basketball → Football → Baseball →
  Soccer → Volleyball → Hockey → ...)
- **Beyond sports**: the core architecture (modules, AI assistance,
  governance, user-centered workflows) could eventually generalize to
  music directors, debate teams, robotics clubs, marching bands, and other
  activity-leader contexts — sports is the first vertical, not the ceiling
- **"System of record for coaching"**: the GitHub analogy — GitHub won by
  becoming the system of record for software development, not just a code
  host. CXP's equivalent bet is becoming where a season lives, where
  player development lives, where club knowledge and coaching philosophy
  persist across coach turnover instead of leaving with the coach.
- **Instruction Engine ("Teach Play")**: eco.ai generates a full teaching
  plan from a drawn play — coach briefing, player-by-player responsibility
  sheet, multi-day installation progression, drills, common mistakes,
  coaching cues, a printable handout, age-appropriate variants. Needs no
  new technical capability beyond what's already scoped in `ai-model.md`
  — it's structured generation over the existing Play/Practice/Drill/
  DevelopmentGoal data. The stronger near-term differentiator of the two
  ideas below: most competitors help coaches store or communicate
  information; almost none help them *teach* it. A real `cxp-coach-pro`
  candidate once the editor MVP settles, not research.
- **Game Intelligence / video-to-play (vision AI)**: computer vision
  pipeline (player/ball tracking → possession detection → movement graph
  → play recognition → editable diagram) that could turn uploaded practice
  or game video into an editable play, plus the reverse (overlay an
  animated diagram on video for teaching) and automated practice analysis
  (closeout speed, pass counts, drill duration). Explicitly a later-stage
  capability, not a v1 dependency — reliable tracking across youth gyms,
  bad camera angles, and crowded sidelines is a hard, separate engineering
  problem. Framed as a fourth AI engine alongside Language (eco.ai),
  Analytics, and Knowledge, each pluggable (Azure AI Vision, OpenCV, YOLO,
  Roboflow, etc.) rather than a custom-trained model CXP owns. Get the
  play editor, practice planner, and data model right first — that's the
  infrastructure that makes plugging in vision easier later, not a
  prerequisite for it.

---

## Open Questions

- Naming: "CXP" (Coach Experience Platform) is the working name — final
  brand name, and whether it lives under 20Amp Labs as a named product,
  still open.
- How much of Cockpit is actually reusable today vs. needs
  genericizing first — has not been audited against CXP's actual UI needs.
- Where the real Sport 2 (football vs. something else) lands in priority
  once basketball MVP ships.
- Whether Flutter's `CustomPainter` performance holds up for animated
  multi-frame plays with many simultaneous paths — a debug-session
  functional spike ran clean (CXP.03, 2026-07-10; see
  `docs/architecture/perf-spike-cxp03.md`), but true release-mode,
  real-device profiling has not happened yet and is still required before
  v0.1 relies on this.
- **CXP-edge (queued idea, not scoped):** a Raspberry Pi-class device as
  a delivery target — candidates raised: (a) a local offline-sync hub for
  gyms with unreliable wifi, extending the offline-first requirement in
  `docs/architecture/ux-philosophy.md`; (b) a gym-mounted kiosk/scoreboard
  display; (c) a video-capture appliance feeding Player Development's
  video integration. Would follow the same HAL-adapter pattern `eco-edge`
  already uses elsewhere in this portfolio. Explicitly not designed or
  scheduled — CXP has no shipped MVP yet, and `module-boundaries.md`'s
  "don't build ahead of the phase" rule applies here directly. Logged so
  the idea isn't lost, not because it's next.
- Marketplace legal/IP model (licensing terms, revenue share mechanics,
  dispute handling) is directional only — no terms drafted.
- Whether Verified Organization status requires any real-world
  verification partner, or is self-attested at first.
- SafeSport / background-check / concussion-protocol acknowledgment
  tracking: CXP tracks completion, but has not decided whether/how it
  integrates with actual third-party certification providers.
- Data residency and retention defaults for minors' data — not yet
  specified beyond "configurable."
- No committed timeline exists yet — the 4-week MVP and phase estimates
  above are planning inputs, not commitments, pending the architecture
  week described in Roadmap.

---

## Source

This document synthesizes a single extended scoping conversation
(2026-07-10) covering: module structure, eco.ai philosophy, communications
scope, player development, pricing/tiers, verified organizations and
marketplace, basketball domain AI strategy, statistics import/export,
platform naming (CXP), full security/privacy/governance checklist,
finance/travel modules, business viability and pricing math, analytics
architecture (Power BI/Fabric split), and technical feasibility/stack for
the play editor. Nothing here has been engineered or committed — see
`DEV-PLAN.md` for actual next steps.
