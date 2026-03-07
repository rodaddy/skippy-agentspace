# State Consistency -- Cross-File Alignment

GSD maintains state across multiple files. When they disagree, bad things happen -- agents work on the wrong phase, verifiers check the wrong criteria, progress reports lie. This checklist catches misalignment before it propagates.

## When to Check

- Before starting a new phase execution
- After completing a phase (before marking done)
- When `/skippy:reconcile` runs
- Whenever something "feels off" about project state

## Alignment Checklist

### 1. Current Phase Agreement

All of these should point to the same phase:

| Source | Field | Location |
|--------|-------|----------|
| STATE.md | `current_phase` | `.planning/STATE.md` |
| ROADMAP.md | First non-completed phase | `.planning/ROADMAP.md` |
| Phase directory | Most recent `phases/*/PLAN.md` | `.planning/phases/` |

**Mismatch = BLOCKING.** Fix STATE.md to match reality before proceeding.

### 2. Phase Status Agreement

| Source | Shows | Location |
|--------|-------|----------|
| STATE.md | Phase status (planning/executing/done) | `.planning/STATE.md` |
| ROADMAP.md | Phase status markers | `.planning/ROADMAP.md` |
| Phase dir | Presence of PLAN.md / SUMMARY.md | `.planning/phases/<N>/` |

Expected consistency:
- Status "planning" = PLAN.md should NOT exist yet (or be in draft)
- Status "executing" = PLAN.md exists, SUMMARY.md does NOT
- Status "done" = Both PLAN.md and SUMMARY.md exist

### 3. PROJECT.md Alignment

| Field | Should Match |
|-------|-------------|
| Project name | Directory name / repo name |
| Current milestone | ROADMAP.md milestone header |
| Tech stack | Actual dependencies in package.json / pyproject.toml |

### 4. Roadmap Phase Count

- Number of phases in ROADMAP.md should match number of phase directories (planned + completed)
- Phase numbers should be sequential (no gaps unless phases were removed via `/gsd:remove-phase`)

### 5. Git State

- Working directory clean? Uncommitted changes from a previous phase?
- On the correct branch? (Not accidentally on main)
- No merge conflicts pending?

## Quick Validation Script

Run mentally or have an agent check:

```
1. Read .planning/STATE.md -> note current_phase and status
2. Read .planning/ROADMAP.md -> find first incomplete phase
3. ls .planning/phases/ -> check directory matches
4. Do they agree? If yes, PASS. If no, STOP.
```

## Fixing Misalignment

1. **Identify truth:** Git history is the source of truth. What actually happened?
2. **Update STATE.md** to match reality (not the other way around)
3. **Update ROADMAP.md** phase statuses to match what's actually done
4. **Don't delete evidence** -- if a phase was partially done, note it, don't erase it
5. **Then proceed** with the corrected state

## Severity

- **Phase number mismatch:** BLOCKING -- agents will work on the wrong phase
- **Status mismatch:** HIGH -- verifiers may skip checks or re-verify done work
- **PROJECT.md drift:** LOW -- informational, fix when convenient
- **Git state issues:** BLOCKING -- resolve before any execution
