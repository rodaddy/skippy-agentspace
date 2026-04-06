# Ambiguity Scoring -- Requirements Clarity Gate

Adapted from OMC's deep-interview skill. A quantitative framework for measuring whether requirements are clear enough to start planning. Complements structured deliberation (PDOC) -- this answers "do we know WHAT to build?" while PDOC answers "is our plan for HOW to build it sound?"

## When to Apply

- Before entering GSD plan-phase on a new feature or project
- When a user describes something they want but the scope feels fuzzy
- As a self-check before committing to a plan direction
- When multiple interpretations of a requirement seem equally valid

## Scoring Formula

Rate each dimension 0-10, apply weights, sum to get a clarity score (0-100):

### Greenfield Projects

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| **Goal Clarity** | 40% | Can you state the desired outcome in one sentence? |
| **Constraint Clarity** | 30% | Are boundaries, limitations, and non-goals explicit? |
| **Success Criteria** | 30% | Will you know when it's done? How will you verify? |

**Score = (Goal * 4) + (Constraints * 3) + (Criteria * 3)**

### Brownfield Projects (existing codebase)

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| **Goal Clarity** | 35% | What changes and why? |
| **Constraint Clarity** | 25% | What must NOT change? What's off-limits? |
| **Success Criteria** | 25% | How do you verify the change works? |
| **Context Clarity** | 15% | Do you understand the existing system enough to change it safely? |

**Score = (Goal * 3.5) + (Constraints * 2.5) + (Criteria * 2.5) + (Context * 1.5)**

## Thresholds

| Score | Verdict | Action |
|-------|---------|--------|
| **80-100** | Clear | Proceed to planning |
| **60-79** | Mostly clear | Ask 2-3 targeted questions on the weakest dimension |
| **40-59** | Unclear | Structured interview needed -- work through each dimension |
| **0-39** | Vague | Step back -- the user may not know what they want yet. Explore, don't plan. |

## Targeted Questioning

Always question the **weakest dimension first**. Example questions by dimension:

### Goal Clarity (low score)
- "What does success look like when this is done?"
- "Who benefits from this and how?"
- "If you could only ship one thing, what would it be?"

### Constraint Clarity (low score)
- "What should this NOT do?"
- "Are there performance/cost/time constraints?"
- "What existing behavior must be preserved?"

### Success Criteria (low score)
- "How will you test this?"
- "What's the simplest way to verify it works?"
- "What would a failing test look like?"

### Context Clarity (low score, brownfield only)
- "Which parts of the existing system does this touch?"
- "Have similar changes been made before? What happened?"
- "Are there known landmines in this area?"

## Challenge Modes

When clarity stalls (score unchanged after 2+ questions), shift perspective with a challenge mode:

| Mode | When to Deploy | What It Does |
|------|---------------|--------------|
| **Contrarian** | Score plateaued at 50-65 | Challenge assumptions: "What if [assumed constraint] isn't actually required?" |
| **Simplifier** | Score plateaued at 65-75 | Reduce scope: "What's the simplest version that delivers value?" |
| **Ontologist** | Score plateaued at any level | Redefine terms: "When you say [X], do you mean [A], [B], or [C]?" |

Deploy one mode at a time. If the mode doesn't move the score after 2 questions, try a different one or accept the current clarity level and proceed with documented assumptions.

## Quick Assessment (Mental Checklist)

Before entering plan-phase, answer these quickly:

1. Can I explain the goal to a colleague in one sentence? (Goal)
2. Can I list 3 things this should NOT do? (Constraints)
3. Can I describe how to verify it works? (Criteria)
4. (Brownfield) Do I know which files/systems are involved? (Context)

If you can't answer 2+ of these confidently, run the scoring before planning.

## Investigation-to-Requirements Pipeline

When an investigation phase (trace, debug, explore) precedes requirements gathering, inject findings at 3 points:
1. **Enriched starting context** -- Investigation findings become the interview's background context
2. **System context** -- Structural discoveries (dependencies, constraints found during investigation) set interview constraints
3. **Seeded questions** -- Investigation reveals specific unknowns that become the first interview questions

This eliminates redundant re-exploration. The interview starts with knowledge from the investigation, not from zero.

Source: OMC v4.10 deep-dive skill (trace -> deep-interview pipeline).

## Integration Prompt

When evaluating requirements before planning:

```
Score the requirements across clarity dimensions: Goal (can you state the outcome
in one sentence?), Constraints (what's off-limits?), Success Criteria (how to verify?).
Rate each 0-10, apply weights (40/30/30 greenfield, 35/25/25/15 brownfield).
If total score is below 60, ask targeted questions on the weakest dimension before
proceeding to planning.
```

---
*Source: Adapted from OMC deep-interview skill. Enriched with OMC v4.10 investigation-to-requirements pipeline.*
*Last reviewed: 2026-04-06*
