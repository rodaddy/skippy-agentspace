# Variant Analysis -- 5-Step Methodology

Systematic process for finding pattern variants across a codebase after an initial
instance is identified. Adapted from Trail of Bits' variant-analysis skill.

## The 5 Steps

### 1. Understand the Root Instance

Before searching, formulate a root cause statement:
> "[THING] reaches [OPERATION] without [REQUIRED PROTECTION]."

Not the symptom -- the structural WHY. What conditions are required? What makes it
a problem? This statement IS the search pattern.

### 2. Create an Exact Match

Write a pattern that matches ONLY the known instance. One hit, zero false positives.
This is the baseline -- if your exact match returns zero or multiple, you don't
understand the instance well enough yet.

### 3. Identify Abstraction Points

For each element, decide: keep specific or abstract?

| Element | Keep Specific | Can Abstract |
|---------|---------------|--------------|
| Function/method name | If unique to the issue | If the pattern applies to a family |
| Variable names | Never | Always (use wildcards) |
| Literal values | If the value itself matters | If any value triggers the issue |
| Arguments/params | If position matters | Use wildcards for flexible matching |

### 4. Iteratively Generalize

Change ONE element at a time. After each change: run, review ALL new matches,
classify true/false positives. If FP rate is acceptable, generalize next element.
If FP rate exceeds ~50%, revert and try a different abstraction.

The abstraction ladder: exact match -> variable abstraction -> structural
abstraction -> semantic abstraction. Climb one rung at a time.

### 5. Triage Results

For each match, document: location, confidence (high/med/low), whether the
context makes it a real issue or a false positive, and priority based on impact.

## When to Apply in Our Review Swarm

Use this pattern when the **review swarm** (see `audit-swarm.md`) identifies an
initial finding. Instead of stopping at "found one," the reviewer should:

1. Run the 5-step process to search for variants of the same root cause
2. Report the variant count alongside the initial finding
3. Classify each variant independently -- context may differ

This pairs with `verification-loops.md` (verify each variant) and
`two-stage-review.md` (initial scan finds seeds, deep pass runs variant analysis).

## Key Anti-Patterns

- **Narrow scope**: Searching only the module where the issue was found. Always
  search the entire codebase.
- **Pattern too specific**: Only matching the exact attribute/function from the
  original. Enumerate semantically related constructs.
- **Single manifestation**: One root cause often has multiple manifestations.
  Expand to related issue classes before concluding.
- **Skipping edge cases**: Test with null/empty/boundary values, not just
  happy-path scenarios.

## Attribution

Adapted from [trailofbits/skills -- variant-analysis](https://github.com/trailofbits/skills/tree/main/plugins/variant-analysis).
License: CC BY-SA 4.0. Original methodology by Trail of Bits.
