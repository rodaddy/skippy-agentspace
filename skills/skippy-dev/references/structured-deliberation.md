# Structured Deliberation -- Best-of-Breed Synthesis

Multi-perspective plan review with bounded iteration and structured decision records. Synthesized from OMC and GSD.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC (ralplan) | Planner + Architect + Critic consensus (max 5 iterations) with RALPLAN-DR structured output: Principles, Decision Drivers, Viable Options, ADR | Multi-perspective review, bounded iteration, structured decision record format, deliberate mode for high-risk work | Requires OMC's multi-agent Task runtime, overkill for small tasks |
| OMC (deep-interview) | Ambiguity scoring with weighted clarity dimensions, challenge agent modes (Contrarian, Simplifier, Ontologist) | Forces clarity before execution, mathematical gating prevents vague requests from proceeding | Heavy infrastructure, domain-specific scoring weights |
| GSD | `plan-check` -- single checker agent reviews plans against criteria | Automated, integrated into workflow, catches issues before execution | Single reviewer perspective, no structured deliberation format, no iteration on feedback |

## Why This Version

GSD's plan-check is efficient but one-dimensional -- a single reviewer applying a checklist. OMC's insight is that DIFFERENT PERSPECTIVES catch different problems: a planner thinks about feasibility, an architect thinks about structure, a critic thinks about risk. You don't need three separate agents to get this benefit -- you need the DISCIPLINE of reviewing from multiple angles. This synthesis provides a structured deliberation framework that a single reviewer (or human) can apply sequentially.

## The Pattern

### When to Deliberate

Not every task needs multi-perspective review. Use this decision guide:

| Task Scope | Review Approach | Why |
|------------|----------------|-----|
| Single file change, clear requirements | No deliberation -- just do it | Overhead exceeds value |
| Standard feature, known patterns | Single-pass review (GSD plan-check) | One perspective sufficient |
| Cross-cutting change, multiple tradeoffs | Structured deliberation (this pattern) | Multiple concerns need explicit balancing |
| High-risk change (auth, data, public API) | Deliberate mode with pre-mortem | Stakes justify thorough analysis |

### Structured Deliberation Framework (PDOC)

Before committing to a plan for any non-trivial change, work through these four elements:

1. **Principles** (3-5): What non-negotiable constraints guide this decision? Examples: "No breaking API changes," "Must work offline," "Security over convenience."

2. **Decision Drivers** (top 3): What factors most influence the choice? Rank by importance. Examples: "Migration complexity," "Runtime performance," "Team familiarity."

3. **Options** (2+ viable): List at least two genuinely viable approaches. For each:
   - Brief description
   - Pros (bounded: max 3)
   - Cons (bounded: max 3)
   - If only one option seems viable, explicitly state why alternatives were invalidated

4. **Commitment** (the decision record): Which option, why it was chosen, what tradeoffs were accepted, what follow-ups are needed.

### Perspective Roles

When reviewing a plan or decision, cycle through these perspectives sequentially:

| Role | Focus | Key Question |
|------|-------|-------------|
| **Planner** | Feasibility, scope, sequencing | "Can this actually be built in the proposed order?" |
| **Architect** | Structure, patterns, system impact | "Does this fit the existing architecture? What does it break?" |
| **Critic** | Risk, gaps, testability | "What could go wrong? How would we know it's working?" |

You don't need three agents -- one reviewer cycling through these lenses catches most issues.

### Deliberate Mode (High-Risk Only)

For changes flagged as high-risk (auth/security, migrations, destructive operations, public API changes):

- Add a **pre-mortem**: "Assume this failed. List 3 plausible reasons why."
- Expand test planning: unit, integration, e2e, and observability checks
- Require explicit sign-off on accepted risks before proceeding

### Bounded Iteration

If review surfaces issues, iterate -- but cap it:

- **Max 3 iterations** for standard deliberation
- **Max 5 iterations** for deliberate mode
- If no consensus after max iterations, present the best version with documented dissent
- Same issue appearing 3 times = stop iterating, escalate the disagreement

## Integration Points

- **GSD plan-check:** Enhance the checker agent's prompt with PDOC framework. Instead of freeform review, the checker evaluates whether Principles, Drivers, Options, and Commitment are adequately addressed.
- **GSD plan-phase:** Planners can use the PDOC structure when drafting plans with significant architectural choices.
- **Pre-execution gate:** Before major execution phases, verify the plan has been deliberately reviewed -- not just checked.

## When to Apply

- Planning any change that touches 3+ files or crosses module boundaries
- Making architectural decisions with long-term consequences
- Resolving disagreements between approaches
- Reviewing plans before high-risk execution phases
- NOT for routine implementation, bug fixes, or well-understood patterns

---
*Sources: OMC `skills/ralplan/SKILL.md` (RALPLAN-DR structure, iteration bounds), OMC deep-interview (perspective challenge modes), GSD `plan-check` phase*
*Last reviewed: 2026-03-07*
