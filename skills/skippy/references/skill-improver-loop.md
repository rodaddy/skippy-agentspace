# Skill Improver Loop -- Iterative Refinement Protocol

Automated fix-review cycle for iterating on skill quality until a defined bar is
met. Adapted from Trail of Bits' skill-improver methodology.

## Core Loop

```
Review -> Categorize -> Fix -> Evaluate -> Repeat (until bar met)
```

Each iteration: run a review pass, categorize by severity, fix what must be fixed,
evaluate what might be noise, then re-review to verify fixes landed.

## Issue Severity Tiers

| Tier | Examples | Action |
|------|----------|--------|
| **Critical** | Missing required fields, invalid syntax, broken paths | Fix immediately -- blocks functionality |
| **Major** | Vague triggers, wrong voice, missing required sections, oversized files | Must fix -- degrades effectiveness |
| **Minor** | Style preferences, "nice to have" additions, formatting nits | Evaluate individually before fixing |

## Minor Issue Evaluation

Before implementing ANY minor fix, answer: (1) Is this a genuine improvement or
just a preference? (2) Could the reviewer be misunderstanding context? (3) Would
this actually help the skill work better? Only implement clearly beneficial minors.
Reviewers produce false positives -- especially on style opinions.

## Completion Criteria

The loop terminates when ALL hold:
- Zero critical issues remain
- Zero major issues remain
- Remaining minors have been individually evaluated
- Fixes verified by a re-review pass (not assumed correct)

## Integration with /skippy:eval

This loop is the inner engine of eval. When `/skippy:eval` runs assertions:
1. **Failed assertions** = critical/major issues (skill doesn't do what it claims)
2. **Weak assertions** = minor issues (evaluate whether tightening helps)
3. **Each eval iteration** = one trip through the fix-review loop
4. **Eval terminates** when all assertions pass AND re-review confirms

Key insight: don't just fix until tests pass. Re-review after fixing to catch
regressions introduced by the fixes themselves.

## Anti-Rationalizations

| Rationalization | Why It's Wrong |
|-----------------|----------------|
| "I'll come back later" | Deferred fixes are forgotten fixes |
| "Skip all minors" | Batch dismissal hides real issues -- evaluate each |
| "Reviewer is too strict" | Push back on specifics, not the quality bar itself |
| "It's good enough" | If major issues remain, it's not -- by definition |

Pairs with `verification-loops.md`, `hard-gate.md`, `reconciliation.md`.

## Attribution

Adapted from [trailofbits/skills -- skill-improver](https://github.com/trailofbits/skills/tree/main/plugins/skill-improver).
License: CC BY-SA 4.0. Original methodology by Trail of Bits.
