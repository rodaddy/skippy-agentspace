# FP-Check Gates -- 6-Gate Verification System

Systematic false positive elimination. Every suspected issue must pass all six
gates -- any single failure produces a FALSE POSITIVE verdict. Adapted from
Trail of Bits' fp-check skill.

## Pre-Gate: Restate the Claim

Before analysis, restate the finding in your own words. If you can't do this
clearly, the claim is too vague to verify. Half of false positives collapse at
this step -- the claim doesn't make coherent sense when restated precisely.

## The 6 Gates

| Gate | Criterion | Pass | Fail |
|------|-----------|------|------|
| **1. Process** | All steps completed with evidence | Documented evidence exists | Steps lack concrete evidence |
| **2. Reachability** | Issue can be triggered via a real path | Reachable, controllable path shown | Cannot demonstrate reachability |
| **3. Real Impact** | Triggering it has meaningful consequences | Direct impact with concrete scenarios | Only cosmetic or theoretical |
| **4. PoC Validation** | Sketch/test demonstrates trigger path | Shows control, trigger, and outcome | Cannot show path or outcome |
| **5. Bounds Check** | Condition is actually possible | Proof shows condition can occur | Logic/constraints prevent it |
| **6. Environment** | No protections fully prevent it | Protections don't eliminate the issue | Environment blocks it entirely |

## Devil's Advocate Spot-Check (5 + 2)

Before issuing a verdict, answer these. Against the finding:
1. Am I flagging this because the pattern "looks bad" rather than IS bad?
2. Am I assuming external control over trusted data?
3. Have I proven the condition can actually occur?
4. Am I confusing defense-in-depth failure with a primary issue?
5. Am I hallucinating this? (LLM self-check)

For the finding (false-negative protection):
6. Am I dismissing something real because the trigger seems complex?
7. Am I inventing mitigations I haven't verified in the source?

## Review Swarm Integration

Before any finding reaches the final report:
1. Run the 6-gate check against each finding independently
2. Verdict format: `CONFIRMED -- [desc]` or `REJECTED -- [reason, failed gate]`
3. For batch reviews, restate all claims first -- bulk restatement collapses FPs

Pairs with `anti-rationalization.md`, `verification-loops.md`, `hard-gate.md`.

## Quick FP Checklist

If any apply, the finding is likely false positive:
- Analyzing code in isolation without tracing the full validation chain
- Claiming a race without proving concurrent access is possible
- Assuming external data reaches an operation without tracing the path
- Ignoring conditional logic that makes the path unreachable
- Missing framework/language guarantees that prevent the condition

## Attribution

Adapted from [trailofbits/skills -- fp-check](https://github.com/trailofbits/skills/tree/main/plugins/fp-check).
License: CC BY-SA 4.0. Original methodology by Trail of Bits.
