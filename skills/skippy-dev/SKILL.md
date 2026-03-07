---
name: skippy-dev
description: Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
---

# skippy-dev -- Development Workflow Enhancements

Additive rules and tools that sharpen GSD's planning and execution. No GSD files modified -- everything here is referenced guidance that agents and main context can load on demand.

## 5 Enhancements

| # | Enhancement | Reference | When It Applies |
|---|-------------|-----------|-----------------|
| 1 | Context Brackets | `references/context-brackets.md` | Every session -- self-monitor context usage |
| 2 | Mandatory Reconciliation | `references/reconciliation.md` | After phase execution, before marking complete |
| 3 | Task Anatomy | `references/task-anatomy.md` | During plan creation (plan-phase) |
| 4 | Plan Boundaries | `references/plan-boundaries.md` | During plan creation -- define what NOT to touch |
| 5 | State Consistency | `references/state-consistency.md` | Before/after phase execution -- cross-file alignment |

## Commands

### `/skippy:reconcile`

Compare what was planned vs what was actually done for the most recent phase.

**Workflow:**

1. Identify the current project's `.planning/` directory
2. Find the most recently completed phase (check STATE.md or scan `phases/` dirs)
3. Read the phase's `PLAN.md` for planned tasks and acceptance criteria
4. Read the phase's `SUMMARY.md` (or execution output) for actual results
5. Compare:
   - Which tasks completed vs skipped vs added mid-flight?
   - Which acceptance criteria passed vs failed vs untested?
   - Any files changed that weren't in the plan?
6. Output a reconciliation report (see `references/reconciliation.md` for template)
7. If STATE.md or PROJECT.md have drifted, flag the misalignment

**Output:** Reconciliation report printed to terminal. Optionally saved to `.planning/phases/<phase>/RECONCILIATION.md`.

### `/skippy:update`

Check GSD and PAUL repos for upstream changes worth absorbing.

**Workflow:**

1. Run `${CLAUDE_SKILL_DIR}/scripts/skippy-update.sh`
2. Review the diff report
3. Human decides what to absorb -- no auto-merge

### `/skippy:cleanup`

Manage ephemeral files (debug logs, telemetry, session history).

**Workflow:**

1. Run `${CLAUDE_SKILL_DIR}/scripts/skippy-cleanup.sh [--quarantine|--nuke]`
2. Default is `--quarantine` (moves to a configurable quarantine directory)
3. Reports space freed

## For Agents

When spawning GSD agents (planner, executor, verifier), you can enhance their prompts:

```
Read ${CLAUDE_SKILL_DIR}/references/task-anatomy.md
# Include when the agent is creating plans

Read ${CLAUDE_SKILL_DIR}/references/plan-boundaries.md
# Include when the plan needs scope protection

Read ${CLAUDE_SKILL_DIR}/references/state-consistency.md
# Include when the agent touches state files
```

Don't load all references into every agent -- pick the relevant one.
