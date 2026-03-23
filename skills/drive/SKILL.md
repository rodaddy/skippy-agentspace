---
name: drive
description: Persistence loop with PRD-driven story tracking, acceptance criteria verification, and architect sign-off. Keeps working until ALL stories pass.
allowed-tools: "Read,Write,Edit,Bash,Grep,Glob,Agent"
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
  absorbed_from: oh-my-claudecode/ralph
---

# drive -- Persistent Execution Loop

Keeps working on a task until ALL acceptance criteria pass and an architect verifies the result. PRD-driven story tracking prevents silent partial completion.

## When to Use

- Task requires guaranteed completion with verification (not "do your best")
- User says "drive", "don't stop", "must complete", "finish this", or "keep going until done"
- Work may span multiple iterations and needs persistence across retries
- Task benefits from structured story tracking with architect sign-off

## When NOT to Use

- Full autonomous lifecycle from idea to code -- use `/autopilot` instead
- Quick one-shot fix -- delegate directly to an agent
- Exploration or planning -- use `/skippy:plan`

## Execution

### Step 1: PRD Setup (first iteration only)

Create `.skippy/drive/prd.json` if it doesn't exist:

```json
{
  "stories": [
    {
      "id": "US-001",
      "title": "Story title",
      "acceptanceCriteria": [
        "Function X returns Y when given Z",
        "Test file exists at path P and passes"
      ],
      "passes": false
    }
  ]
}
```

**CRITICAL:** Replace generic criteria ("Implementation is complete") with task-specific, testable criteria. Generic criteria = PRD theater.

### Step 2: Pick Next Story

Read `prd.json`, select the highest-priority story with `passes: false`.

### Step 3: Implement

Delegate to agents using complexity routing:

| Complexity | Task Type | Model |
|------------|-----------|-------|
| LOW | Simple lookups, type exports | haiku |
| MEDIUM | Standard implementation | sonnet |
| HIGH | Complex analysis, debugging | opus |

Fire independent agent calls simultaneously -- never serialize independent work. Use `run_in_background: true` for long operations (builds, tests, installs).

### Step 4: Verify Story

For EACH acceptance criterion:
1. Run relevant checks (test, build, lint, typecheck)
2. Read output as fresh evidence
3. If any criterion NOT met, continue working -- do NOT mark complete

### Step 5: Mark Story Complete

When ALL criteria pass:
1. Set `passes: true` in `prd.json`
2. Record progress in `.skippy/drive/progress.md`: what was implemented, files changed, learnings

### Step 6: Check PRD Completion

All stories `passes: true`? If not, loop to Step 2. If yes, proceed to verification.

### Step 7: Architect Verification

Spawn a read-only architect agent (complexity: HIGH) to verify against the specific acceptance criteria from `prd.json`. The architect verifies against SPECIFIC criteria, not vague "is it done?"

Verification tiers:
- <5 files, <100 lines with full tests: MEDIUM minimum
- Standard changes: MEDIUM
- >20 files or security/architectural changes: HIGH
- Drive floor: always at least MEDIUM

### Step 8: On Approval

Clean up state files in `.skippy/drive/`.

### Step 9: On Rejection

Fix the issues raised, re-verify, loop back to check if stories need to be marked incomplete.

## Escalation

- Stop and report when a fundamental blocker requires user input
- Stop when the user says "stop", "cancel", or "abort"
- If the same issue recurs across 3+ iterations, report it as a potential fundamental problem

## State Files

All state lives in `.skippy/drive/`:
- `prd.json` -- stories and acceptance criteria
- `progress.md` -- implementation log and learnings

## Final Checklist

- [ ] All prd.json stories have `passes: true`
- [ ] Acceptance criteria are task-specific (not generic boilerplate)
- [ ] All requirements from the original task are met (no scope reduction)
- [ ] Fresh test run output shows all tests pass
- [ ] Fresh build output shows success
- [ ] Architect verification passed against specific criteria
- [ ] State files cleaned up
