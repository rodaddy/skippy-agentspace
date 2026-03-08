# Verification Loops -- Best-of-Breed Synthesis

Cycle verification with bounded iterations and early exit on repeated failures. Synthesized from OMC, PAUL, and GSD.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC | UltraQA -- autonomous cycling (test-diagnose-fix-repeat, max 5 iterations) with architect diagnosis and same-failure detection (3x = early exit) | Automated cycling with hard caps, multi-perspective diagnosis, observability output per cycle | Heavy runtime dependency on OMC's agent infrastructure |
| PAUL | Verification protocol with explicit pass/fail criteria per task (4-field task anatomy) | Clear success criteria defined upfront, testable outcomes | No automation -- relies on manual checking against criteria |
| GSD | `gsd:verify-work` -- single-pass verification agent runs after each plan execution | Structured, tied to phase lifecycle, automatic trigger | Single pass only -- if verification fails, manual intervention needed |

## Why This Version

Each upstream solves one piece: PAUL defines WHAT to verify (explicit criteria), GSD defines WHEN to verify (phase-tied), and OMC defines HOW to verify iteratively (cycling with bounds). No single source has the complete picture. This synthesis combines PAUL's upfront criteria with GSD's lifecycle trigger and OMC's cycling strategy -- producing a verification approach that knows what success looks like, runs at the right time, and retries intelligently.

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

## Integration Points

- **GSD task execution:** After each task, run the task's `verify` command. If it fails, enter a cycling loop (max 3 iterations for task-level, max 5 for plan-level).
- **GSD plan verification:** The `gsd:verify-work` phase becomes the trigger for plan-level cycling.
- **Task anatomy:** The `verify` and `done` fields from `task-anatomy.md` provide the criteria this pattern cycles against.
- **Context brackets:** In DEEP/CRITICAL brackets, reduce max iterations to 2 to conserve context.

## When to Apply

- After any task with automated verification commands
- After plan completion (plan-level verification pass)
- When debugging a failing test suite (cycle until green or give up bounded)
- NOT for exploratory/research work with no clear pass/fail criteria

---
*Sources: OMC `skills/ultraqa/SKILL.md`, PAUL verification protocol (via `task-anatomy.md`), GSD `verify-work` phase*
*Last reviewed: 2026-03-07*
