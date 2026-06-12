---
phase: 14-audit-swarm
plan: 01
subsystem: workflow
tags: [subagents, audit, code-review, multi-agent, orchestration]

requires:
  - phase: 13-gsd-pattern-absorption
    provides: Reference docs (verification-loops.md, model-routing.md) that agents reference

provides:
  - 6 subagent definitions for the audit swarm (security, code-quality, architecture, consistency, fix, eval)
  - audit-swarm.md reference doc defining the orchestration protocol

affects: [14-02, skippy]

tech-stack:
  added: [claude-code-subagents]
  patterns: [subagent-definition-pattern, findings-board-protocol, sandbox-layering]

key-files:
  created:
    - skills/skippy/agents/security-reviewer.md
    - skills/skippy/agents/code-quality-reviewer.md
    - skills/skippy/agents/architecture-reviewer.md
    - skills/skippy/agents/consistency-reviewer.md
    - skills/skippy/agents/fix-agent.md
    - skills/skippy/agents/eval-agent.md
    - skills/skippy/references/audit-swarm.md
  modified: []

key-decisions:
  - "Reviewers + eval agent use permissionMode: plan (read-only); fix agent uses bypassPermissions with worktree isolation"
  - "Architecture reviewer gets opus model (HIGH complexity per model-routing.md); all others use sonnet (MEDIUM)"
  - "3-layer sandbox protocol: HOME override in system prompt, worktree isolation for fix agents, tool restrictions for reviewers"
  - "Sequential reviewer spawning (not parallel) to prevent context overflow and findings board write conflicts"

patterns-established:
  - "Subagent definition pattern: YAML frontmatter (name, description, tools, model, permissionMode) + system prompt body"
  - "Findings board protocol: shared markdown file at .reports/skippy-review/ with per-reviewer sections"
  - "Sandbox layering: HOME override + worktree isolation + tool restrictions as defense-in-depth"

requirements-completed: [SWARM-01, SWARM-02, SWARM-05]

duration: 2min
completed: 2026-03-08
---

# Phase 14 Plan 01: Agent Definitions & Audit Swarm Protocol Summary

**6 subagent definitions (4 reviewers + fix + eval) and audit-swarm.md orchestration protocol for /skippy:review command**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T20:58:19Z
- **Completed:** 2026-03-08T21:00:47Z
- **Tasks:** 2
- **Files created:** 7

## Accomplishments

- Created 6 subagent definition files with proper YAML frontmatter, sandbox rules, and tool restrictions
- Created audit-swarm.md reference doc (124 lines) defining the complete 8-step orchestration protocol
- Established 3-layer sandbox protocol (HOME override, worktree isolation, tool restrictions) to prevent another 71-skill nuke incident

## Task Commits

Each task was committed atomically:

1. **Task 1: Create 6 subagent definition files** - `ff217b0` (feat)
2. **Task 2: Create audit-swarm.md reference doc** - `e202e2f` (feat)

## Files Created/Modified

- `skills/skippy/agents/security-reviewer.md` - Security audit specialist (injection, exposure, traversal, unsafe ops)
- `skills/skippy/agents/code-quality-reviewer.md` - Code quality reviewer (DRY, error handling, dead code, complexity)
- `skills/skippy/agents/architecture-reviewer.md` - Architecture reviewer (portability, conventions, dependencies, SoC) -- uses opus
- `skills/skippy/agents/consistency-reviewer.md` - Consistency reviewer (SKILL.md accuracy, INDEX.md staleness, state alignment)
- `skills/skippy/agents/fix-agent.md` - Fix agent with atomic commits, worktree isolation, and escalation rules
- `skills/skippy/agents/eval-agent.md` - Evaluator agent with cycling protocol, regression checks, and PASS/FAIL verdicts
- `skills/skippy/references/audit-swarm.md` - Orchestration protocol: flow, findings board, severity, sandbox, roster, exit conditions

## Decisions Made

- Reviewers + eval agent use `permissionMode: plan` (read-only); fix agent uses `bypassPermissions` with `isolation: worktree`
- Architecture reviewer assigned opus model (HIGH complexity reasoning); all others use sonnet (MEDIUM)
- Sequential reviewer spawning chosen over parallel to prevent context overflow and findings board write conflicts
- 3-layer sandbox protocol established as defense-in-depth against destructive operations

## Deviations from Plan

None -- plan executed exactly as written. Five of the six agent files already existed as untracked files from a prior session; they met all plan requirements and were committed as-is. The missing eval-agent.md was created fresh.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- All 6 agent definitions and the orchestration protocol are ready for Plan 02 (the `/skippy:review` command itself)
- The command can reference `agents/*.md` for subagent spawning and `references/audit-swarm.md` for the orchestration protocol
- SKILL.md will need updating to list the new audit-swarm.md reference doc (likely in Plan 02)

---
*Phase: 14-audit-swarm*
*Completed: 2026-03-08*
