# Verification Loops -- Best-of-Breed Synthesis

Cycle verification with bounded iterations and early exit on repeated failures. Synthesized from OMC, PAUL, and phased execution patterns.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC | UltraQA -- autonomous cycling (test-diagnose-fix-repeat, max 5 iterations) with architect diagnosis and same-failure detection (3x = early exit) | Automated cycling with hard caps, multi-perspective diagnosis, observability output per cycle | Heavy runtime dependency on OMC's agent infrastructure |
| PAUL | Verification protocol with explicit pass/fail criteria per task (4-field task anatomy) | Clear success criteria defined upfront, testable outcomes | No automation -- relies on manual checking against criteria |
| Phased Execution | `verify-work` -- single-pass verification agent runs after each plan execution | Structured, tied to phase lifecycle, automatic trigger | Single pass only -- if verification fails, manual intervention needed |

## Why This Version

Each upstream solves one piece: PAUL defines WHAT to verify (explicit criteria), phased execution defines WHEN to verify (phase-tied), and OMC defines HOW to verify iteratively (cycling with bounds). No single source has the complete picture. This synthesis combines PAUL's upfront criteria with the phased execution lifecycle trigger and OMC's cycling strategy -- producing a verification approach that knows what success looks like, runs at the right time, and retries intelligently.

## The Pattern

### 1. Define Pass/Fail Criteria Before Execution

Every task needs explicit, testable success criteria before work begins. Borrowed from PAUL's task anatomy:

- **Automated check:** A command that returns 0 on success (test suite, build, typecheck, lint)
- **Done condition:** A human-readable statement of what "done" means
- **Both required.** A passing build with wrong behavior is not done. Correct behavior that doesn't build is not done.

### 2. Choose Single-Pass vs Cycling

| Situation | Strategy | Why |
|-----------|----------|-----|
| Simple verification (does it build?) | Single pass | One command, pass/fail, no diagnosis needed |
| Complex verification (do tests pass after changes?) | Cycle (max 3-5 iterations) | Failures may need diagnosis and incremental fixes |
| Exploratory verification (does it work end-to-end?) | Cycle with human checkpoint | May need visual/functional confirmation between cycles |

### 3. Cycling Protocol (When Chosen)

```
Cycle N (max 5):
  1. RUN: Execute verification command(s)
  2. CHECK: Did all criteria pass?
     - YES -> Exit with success
     - NO  -> Continue
  3. DIAGNOSE: Analyze the failure output
     - What specific check failed?
     - Is this the same failure as last cycle? (track failure signatures)
  4. FIX: Apply targeted fix based on diagnosis
  5. REPEAT: Go to step 1
```

### 4. Exit Conditions

| Condition | Action |
|-----------|--------|
| All criteria pass | Exit: success |
| Max iterations reached (5) | Exit: report remaining failures and diagnosis |
| Same failure 3 consecutive times | Exit early: the fix approach is wrong, escalate |
| Environment error (not a code issue) | Exit: report infrastructure problem |
| Issue count plateaus across iterations | Exit early: stall detected -- the approach isn't converging, re-plan |

Stall detection: Track the issue count between revision cycles. If the count stops decreasing for 2+ consecutive iterations, the current fix strategy isn't converging. Escalate or re-plan rather than burning remaining iterations. (Source: GSD v1.34 plan-checker revision loop)

### 5. Same-Failure Detection

Track a failure signature each cycle (error message + file + line). If the same signature appears 3 times, the current fix strategy is not working. Stop cycling and escalate rather than burning iterations on a dead-end approach.

### 6. Severity-Rated Review (from OMC code-review)

When verification includes code review, rate findings by severity:

| Severity | Action Required |
|----------|----------------|
| **CRITICAL** | Must fix before merge -- security vulnerabilities, data loss risks |
| **HIGH** | Should fix -- logic errors, missing error handling |
| **MEDIUM** | Recommended -- code quality, maintainability concerns |
| **LOW** | Optional -- style, naming, minor improvements |

Only CRITICAL and HIGH findings should trigger fix cycles. MEDIUM and LOW are logged for future cleanup.

### 7. Diagnostic Failure Routing

Before attempting a fix, classify the failure:

| Failure Type | Meaning | Action |
|---|---|---|
| **Intent** | The requirement itself is wrong or unclear | Escalate to user -- don't fix code for a bad spec |
| **Spec** | The spec/plan doesn't match the intent | Revise the plan, then re-execute |
| **Code** | The implementation doesn't match the spec | Fix the code (normal fix cycle) |

The common mistake: treating all failures as code failures. If the spec is wrong, fixing code is wasted work.

Source: PAUL v1.2 diagnostic routing.

### 8. Evidence-Before-Claims

Anti-rationalization table -- cognitive override checklist:

| If you're thinking... | Instead do... |
|---|---|
| "This probably works" | Run the verify command |
| "The test is wrong" | Re-read the test. Re-read the requirement. THEN decide. |
| "This is close enough" | Check the done criteria literally |
| "I'll fix this later" | Fix it now or log it as a deviation |
| "The failure is environmental" | Reproduce it twice before blaming environment |

Source: PAUL v1.2 anti-rationalization enforcement.

### 9. Audit-to-Fix Pipeline

Pattern for autonomous audit->classification->fix workflows:

1. Run audit (tests, lints, security scan)
2. Classify each finding: auto-fixable vs manual-required
3. Auto-fix the auto-fixable ones with test verification per fix
4. Report manual-required findings for human review
5. Cycle: re-run audit to check for regressions from fixes

Key: classify BEFORE fixing. Don't attempt to auto-fix everything -- some findings require human judgment. The classification step prevents wasted fix attempts and ensures manual-required items get surfaced rather than silently skipped.

Source: GSD v1.34 audit-to-fix pipeline.

### 10. DX Boomerang Verification

Score developer experience dimensions at plan time (e.g., time-to-hello-world, friction points, error clarity). After implementation, re-score with live testing. Diff the two scores. If post-implementation scores are lower than planned, something went wrong -- the implementation degraded DX despite intending to improve it.

This forces honesty about whether changes actually improved DX. Planning-time optimism gets checked against implementation-time reality.

Source: gstack v0.15 devex-review skill.

## Integration Points

- **Task execution:** After each task, run the task's `verify` command. If it fails, enter a cycling loop (max 3 iterations for task-level, max 5 for plan-level).
- **Plan verification:** The verify-work step becomes the trigger for plan-level cycling.
- **Task anatomy:** The `verify` and `done` fields from `plan-structure.md` provide the criteria this pattern cycles against.
- **Phased execution:** See `phased-execution.md` for how verification cycling is invoked after wave execution.
- **Checkpoints:** See `checkpoints.md` for checkpoint types that trigger verification (human-verify, decision, human-action).
- **Context brackets:** In DEEP/CRITICAL brackets, reduce max iterations to 2 to conserve context.

## When to Apply

- After any task with automated verification commands
- After plan completion (plan-level verification pass)
- When debugging a failing test suite (cycle until green or give up bounded)
- NOT for exploratory/research work with no clear pass/fail criteria

---
*Sources: OMC `skills/ultraqa/SKILL.md`, PAUL verification protocol (via `plan-structure.md`). Adapted from GSD `verify-work` phase. PAUL v1.2 (diagnostic routing, anti-rationalization), GSD v1.34 (stall detection, audit-to-fix), gstack v0.15 (DX boomerang).*
*Last reviewed: 2026-04-06*
