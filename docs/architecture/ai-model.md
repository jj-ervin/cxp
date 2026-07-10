# CXP AI Model — eco.ai Integration Contract

**Status:** draft — architecture week output
**Updated:** 2026-07-10

---

## Governing principle

> **eco.ai augments the coaching workflow. It does not replace the coach.**

Same precedent as Niji. The play editor, roster, and practice planner are
deterministic. eco.ai is a copilot with context, not an autonomous actor.

## What eco.ai is given (context, not authority)

Per organization/team scope, through the same permission layer a human
actor would use (see `security-model.md`):

- Roster, attendance, availability
- Installed plays, practice history
- Development goals and skill ratings
- Coach-declared philosophy/doctrine (if configured)
- Statistics (governed metrics only — never raw `PlayerSensitive` data)

eco.ai never receives `PlayerSensitive` fields (medical, academic,
emergency contact) as retrieval context. If a future feature needs that
(e.g. an injury-aware substitution suggestion), it must be an explicit,
separately-scoped grant — not inherited from general roster access.

## Action boundary: retrieval/draft vs. write/send

| eco.ai can | eco.ai cannot |
| --- | --- |
| Draft a practice plan | Publish it without coach approval |
| Draft a parent/team announcement | Send it without coach approval |
| Suggest a substitution/rotation | Make the substitution |
| Explain a stat trend with evidence | Assert causation as fact |
| Categorize a receipt, draft a budget | Approve spend or move money |
| Summarize scouting tendencies | Autonomously message a minor privately |

Every write eco.ai produces lands in a `draft: true` state (see `Message`
in the domain model) or an equivalent staging state for other entities.
A human approval action is what flips it live.

## Required response shape

Every eco.ai recommendation surfaced in the product must expose:

```yaml
Recommendation:
  text: string
  why: string
  confidence: low | medium | high
  evidence: [ { source_type, ref, date_range, sample_size } ]
  approval_required: bool     # true for anything that mutates state
  limitations: string?         # explicit caveat when data is incomplete/small-sample
```

This is not a UI nicety — it is the mechanism that keeps eco.ai from
presenting an inference as a recorded fact (the domain model's
raw-event / derived-metric / AI-interpretation / coach-decision
separation depends on this contract being honored at the API boundary,
not just in prompt wording).

## Hard guardrails (enforced, not just prompted)

- No injury diagnosis or unsupervised return-to-play advice
- No public ranking or comparison that could humiliate a child
- No unsupervised private messages to minors
- No eligibility determinations
- No unsafe conditioning-load recommendations
- No autonomous financial actions (approval, transfer, ledger edit)

These need to be enforced at the tool/action layer eco.ai calls into CXP
through — not solely as instructions to the model. A tool that can send a
message or approve an expense must itself refuse an AI-originated caller
without a human approval token attached, regardless of what the model
was told to do.

## Build order (from `CXP-OVERVIEW.md`, restated as an implementation
sequence)

1. **Prompting/rules** — define behavior, terminology, response format
   (the `Recommendation` shape above), and the guardrail list as literal
   enforcement code, not just system prompt text.
2. **Retrieval** — connect the vetted knowledge base and team context;
   every answer must be able to cite what it retrieved.
3. **Tools** — play search, practice drafting, development-record
   queries, diagram generation — each tool call goes through the same
   permission layer as a human request.
4. **Evaluation** — qualified coaches grade responses for correctness,
   age-appropriateness, clarity, and philosophical consistency before any
   tool is trusted with broader defaults.
5. **Fine-tuning** — deferred until there's a body of high-quality,
   licensed interaction examples. Not a v1 concern.

## Basketball domain pack (post-MVP, not v1)

A layered knowledge model — general LLM + curated basketball canon (RAG,
cited) + philosophy profiles (explicitly separating philosophy from fact)
+ coach doctrine + team context + deterministic tools. Full detail in
`CXP-OVERVIEW.md` → AI Strategy. Nothing here is built in v1; the MVP's
eco.ai surface is limited to practice generation, play search, and
draft-only communications.

## Open questions

- Which model/provider eco.ai runs on for CXP specifically is not decided
  here — that's an eco.ai platform decision, not a CXP one.
- Whether tool-level guardrail enforcement lives in CXP's API layer or in
  eco.ai's tool-calling harness is unresolved; leaning CXP-side since CXP
  is the system of record and must not trust the caller.
