# Gates Taxonomy -- 4 Canonical Validation Checkpoint Types

Four gate types that cover every validation checkpoint in a workflow lifecycle. Each gate has a distinct trigger, recovery path, and placement. Together they form a complete validation lattice -- any checkpoint you add to a workflow is one of these four.

**Source:** GSD v1.34 (gates.md)
**Cherry-picked:** 2026-04-06

## The Four Gates

### 1. Pre-flight Gate

Validates preconditions before starting work. Dependencies met, state clean, permissions verified. Blocks start if not passed.

- **Trigger:** Start of any workflow or phase
- **On failure:** Do not start. Report which precondition failed.
- **Recovery:** Fix the precondition (install dependency, clean state, get permission), then retry
- **Example:** Check branch is clean, required tools installed, plan file exists

### 2. Revision Gate

Quality check within an iteration loop. Triggers re-work if standards not met. Has bounded iterations to prevent infinite cycling.

- **Trigger:** End of each iteration within a fix/improve cycle
- **On failure:** Re-enter the loop for another iteration (up to max)
- **Recovery:** Apply targeted fix based on failure diagnosis, re-run verification
- **Example:** Tests must pass after code change; lint must be clean after refactor

### 3. Escalation Gate

Detects when automated fixing is not converging and escalates to human or higher authority. Prevents burning cycles on dead-end approaches.

- **Trigger:** Stall detection (same failure N times) or severity threshold crossed
- **On failure:** Stop automated retries. Surface diagnosis to human or senior agent.
- **Recovery:** Human provides new direction, or senior agent re-plans the approach
- **Example:** Same test fails 3 consecutive cycles; security finding rated CRITICAL

### 4. Abort Gate

Hard stop that prevents damage when state is corrupt, context exhausted, or safety violated. No retry -- immediate halt.

- **Trigger:** Corrupt state, safety violation, context exhaustion (CRITICAL bracket)
- **On failure:** Halt immediately. Preserve current state for diagnosis.
- **Recovery:** Manual intervention only. Checkpoint what was in progress, restart fresh.
- **Example:** Secrets detected in staged files; context at CRITICAL with uncommitted work

## Gate Matrix

| Workflow Stage | Pre-flight | Revision | Escalation | Abort |
|----------------|:----------:|:--------:|:----------:|:-----:|
| **Planning** | Branch clean, plan exists | Plan review pass | Spec ambiguity unresolvable | Contradictory requirements |
| **Execution** | Dependencies installed, state clean | Tests pass after change | Same failure 3x in fix loop | State corruption detected |
| **Verification** | Build succeeds before test run | Verification cycle iteration | Stall: issue count not decreasing | Context exhausted mid-verify |
| **Review** | Spec compliance before quality review | Review finding fix cycle | CRITICAL finding, human must decide | Secrets in diff |

## Recovery Paths Summary

| Gate | Automated Recovery? | Max Retries | Escalates To |
|------|:-------------------:|:-----------:|:------------:|
| Pre-flight | Yes (fix precondition) | 1-2 | Human if env broken |
| Revision | Yes (diagnose + fix) | 3-5 | Escalation gate |
| Escalation | No | 0 | Human / senior agent |
| Abort | No | 0 | Manual restart |

## Integration Points

- **verification-loops.md** -- Revision gates are the cycling mechanism in verification loops. The exit conditions (max iterations, same-failure detection) map directly to escalation and abort gates.
- **audit-swarm.md** -- Escalation gates trigger when the review swarm cannot resolve a CRITICAL finding autonomously.
- **hard-gate.md** -- `<HARD-GATE>` tags in skills are a specific syntax for encoding pre-flight and abort gates in skill definitions.
- **pre-execution-gate.md** -- The vague-prompt interceptor is a pre-flight gate specialized for execution requests.

## When to Apply

- When designing any workflow that has failure modes (all of them)
- When adding checkpoints to existing skills -- classify which gate type it is
- When a workflow keeps cycling without progress (you need an escalation gate)
- When debugging why a workflow ran when it should not have (missing pre-flight gate)

---
*Sources: GSD v1.34 gates.md. Gate matrix adapted from PAI workflow patterns.*
*Last reviewed: 2026-04-06*
