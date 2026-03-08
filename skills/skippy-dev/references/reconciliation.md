# Mandatory Reconciliation -- Plan vs Actual

Adapted from PAUL's verification-protocol.md. Run after phase execution, before marking a phase complete.

## When to Reconcile

- After phase execution completes
- Before verification (reconcile first, then verify)
- When `/skippy:reconcile` is invoked directly
- After any significant implementation session

## Protocol

### Step 1: Gather Planned State

Read the phase's `PLAN.md` (see `plan-structure.md` for expected format) and extract:
- Task list with acceptance criteria
- Files expected to be modified
- Boundaries / scope limits (if defined)
- Dependencies between tasks

### Step 2: Gather Actual State

From `SUMMARY.md`, execution logs, and git history:
- Which tasks were completed?
- Which files were actually modified? (`git diff --name-only` against pre-phase commit)
- Were any tasks skipped or added mid-flight?
- Did acceptance criteria pass?

### Step 3: Compare

For each planned task:
- **DONE** -- completed as planned, AC met
- **MODIFIED** -- completed but approach changed (explain why)
- **SKIPPED** -- not done (explain why, capture as tech debt if needed)
- **ADDED** -- wasn't in plan, done anyway (justify)

For each planned AC:
- **PASS** -- verified
- **FAIL** -- not met (blocking or non-blocking?)
- **UNTESTED** -- not verified (why?)

### Step 4: Check for Drift

- Files changed that weren't in the plan? Flag them.
- Files in the plan that weren't touched? Why not?
- State files (STATE.md, PROJECT.md) still consistent? (See `state-consistency.md`)

## Report Template

```markdown
# Reconciliation Report -- Phase [N]: [Title]

**Date:** YYYY-MM-DD
**Plan commit:** [hash]
**Completion commit:** [hash]

## Task Results

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | [task description] | DONE | -- |
| 2 | [task description] | MODIFIED | Changed approach because... |
| 3 | [task description] | SKIPPED | Blocked by..., captured as TODO |

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| [criterion] | PASS | [test output / manual check] |
| [criterion] | FAIL | [what went wrong] |
| [criterion] | UNTESTED | [why not tested] |

## Deviations

### Unplanned Changes
- `path/to/file.ts` -- [why this was touched]

### Scope Drift
- [anything that expanded beyond plan boundaries]

## State Consistency
- STATE.md current_phase: [correct? y/n]
- PROJECT.md phase status: [correct? y/n]
- ROADMAP.md: [consistent? y/n]

## Verdict

[CLEAN | MINOR_DRIFT | MAJOR_DRIFT | BLOCKED]

[If MAJOR_DRIFT or BLOCKED: what needs to happen before proceeding]
```

## Severity Levels

- **CLEAN** -- plan matched reality, all ACs pass. Proceed freely.
- **MINOR_DRIFT** -- small deviations, all ACs pass. Note and proceed.
- **MAJOR_DRIFT** -- significant unplanned changes or failed ACs. Review before next phase.
- **BLOCKED** -- critical ACs failed or state is inconsistent. Fix before proceeding.

## Related

- `phased-execution.md` -- where reconciliation fits in the execution cycle (runs after phase execution, before phase transition)
- `plan-structure.md` -- the plan format that reconciliation compares against
- `state-consistency.md` -- cross-file alignment checks referenced in Step 4

---
*Source: Adapted from PAUL verification-protocol.md*
*Last reviewed: 2026-03-08*
