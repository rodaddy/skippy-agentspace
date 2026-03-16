---
name: autopilot
description: Full autonomous execution from idea to working code. Handles expansion, planning, implementation, QA, and validation in a multi-phase pipeline.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
  absorbed_from: oh-my-claudecode/autopilot
---

# autopilot -- Autonomous Lifecycle Execution

Takes a brief product idea and autonomously handles the full lifecycle: requirements analysis, technical design, planning, parallel implementation, QA cycling, and multi-perspective validation.

## When to Use

- End-to-end autonomous execution from an idea to working code
- User says "autopilot", "build me", "create me", "make me", "full auto", "handle it all"
- Task requires multiple phases: planning, coding, testing, and validation
- User wants hands-off execution

## When NOT to Use

- Exploration or brainstorming -- respond conversationally or use `/skippy:plan`
- Single focused code change -- use `/drive` or direct agent delegation
- Quick fix or small bug -- delegate directly

## Phases

### Phase 0 -- Expansion

Turn the user's idea into a detailed spec.

- **If a planning swarm plan exists** (`.planning/phases/*/PLAN.md`): Skip Phase 0 and Phase 1 -- jump to Phase 2. The plan is already researcher/planner/critic validated.
- **If input is vague** (no file paths, function names, or concrete anchors): Ask clarifying questions before expanding.
- **Otherwise**: Spawn a HIGH complexity analyst agent to extract requirements, then a HIGH complexity architect agent for technical specification.
- Output: `.skippy/autopilot/spec.md`

### Phase 1 -- Planning

Create an implementation plan from the spec.

- Spawn a MEDIUM complexity planner agent (direct mode, no interview)
- Spawn a HIGH complexity critic agent to validate the plan
- Output: `.skippy/autopilot/plan.md`

### Phase 2 -- Execution

Implement the plan using drive pattern (persistence loop + parallel dispatch).

- LOW complexity agents: simple tasks (type exports, config changes)
- MEDIUM complexity agents: standard implementation
- HIGH complexity agents: complex refactoring, multi-file changes
- Fire independent tasks simultaneously
- Track story completion via `.skippy/drive/prd.json`

### Phase 3 -- QA

Cycle until all tests pass.

1. Build, lint, typecheck
2. Run test suite
3. Fix failures
4. Repeat up to 5 cycles
5. If the same error persists 3 times, stop and report (fundamental issue)

### Phase 4 -- Validation

Multi-perspective review in parallel:

| Reviewer | Complexity | Focus |
|----------|------------|-------|
| Architect | HIGH | Functional completeness, design quality |
| Security reviewer | HIGH | Vulnerability check, OWASP patterns |
| Code quality reviewer | MEDIUM | Code quality, patterns, maintainability |

All must approve. Fix and re-validate on rejection.

### Phase 5 -- Cleanup

Delete all state files on successful completion:
- `.skippy/autopilot/` directory
- `.skippy/drive/` directory (if used)

## Execution Policy

- Each phase must complete before the next begins
- Parallel execution within phases where possible (Phase 2 and Phase 4)
- QA cycles repeat up to 5 times; same error 3 times = stop and report
- Validation requires all reviewers to approve

## Escalation

- Stop when same QA error persists 3 cycles (fundamental issue)
- Stop when validation fails after 3 re-validation rounds
- Stop on "stop", "cancel", or "abort"
- If requirements too vague, pause and ask for clarification

## State Files

All state lives in `.skippy/autopilot/`:
- `spec.md` -- expanded requirements specification
- `plan.md` -- implementation plan
- `state.json` -- current phase and progress

## Final Checklist

- [ ] All 5 phases completed
- [ ] All validators approved in Phase 4
- [ ] Tests pass (fresh output)
- [ ] Build succeeds (fresh output)
- [ ] State files cleaned up
