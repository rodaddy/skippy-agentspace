---
name: prd
description: Create bulletproof Product Requirements Documents with machine-verifiable acceptance criteria, gap analysis, and antagonistic review. USE WHEN user says "prd", "requirements", "spec out", "plan this properly", or needs structured work breakdown before autonomous execution. Works for any project, any stack, any AI agent.
allowed-tools: "Read,Write,Edit,Bash,Grep,Glob,Agent"
metadata:
  version: 0.1.0
  author: Rico
  category: workflow
---

# PRD -- Machine-Verified Product Requirements

Create PRDs that AI agents can execute autonomously and verify mechanically.
No narrative evidence. No self-certification. No gaps. No "done" without proof.

## Trigger

- `/prd <task description>` -- create new PRD
- `/prd --execute` -- pick up PRD and work stories autonomously
- `/prd --close` -- run all verify commands, capture evidence, mark pass/fail
- `/prd --review` -- re-verify existing PRD, detect drift
- `/prd --amend` -- modify stories after creation (with audit trail)

## Output Location

```
.prd/
  prd.json              -- the PRD (machine-readable)
  progress.md           -- human-readable progress log
  evidence/             -- per-story verification output
    US-001.json         -- evidence for story 001
    US-002.json         -- evidence for story 002
```

Project root. Not tied to OMC, ralph, or any specific orchestration tool.

## Core Principles

1. **Commands or it didn't happen** -- every story has executable verify commands. Exit 0 = pass. No narrative evidence.
2. **Separate executor from verifier** -- the agent that writes code MUST NOT be the agent that runs verification. Different agent instance runs `--close`.
3. **Pre-flight catches gaps upfront** -- baseline checks run BEFORE work starts. Known issues get scoped, not discovered post-hoc.
4. **7-criteria circuit breaker** -- more than 7 acceptance criteria = compound story. Split it. No exceptions.
5. **Done = tested AND e2e verified** -- unit tests passing is not done. Real-world end-to-end test must pass.
6. **Cycle limits prevent infinite loops** -- max iterations per story (default 5), max total PRD cycles (default 20). Hit the limit = stop and report.

## Complexity Tiers

Not every task needs full ceremony. Match the tier to the work.

| Tier | Stories | Pre-flight | Critics | E2E Story | When |
|------|---------|------------|---------|-----------|------|
| **Quick** | 1-3 | Skip | Skip | Optional | Bug fix, small feature, config change |
| **Standard** | 4-10 | Required | 2 critics | Required | Feature, refactor, module add |
| **Full** | 10+ | Required | 4 critics | Required | Architecture change, new system, multi-module |

Detection: count stories after Phase 2. Tier determines ceremony.

## Schema

See `references/schema.md` for the full v2.1.0 JSON schema, story status state machine, and evidence structure.

## Story Writing Rules

See `references/story-rules.md` for all 9 rules -- verify commands, criteria limits, mandatory story types, dependencies, determinism, and integration stories.

## Workflows

See `references/workflows.md` for all workflow details:
- **Creation** (Phases 0-5) -- clarification gate, discover, draft, self-check, antagonistic review, finalize
- **Execution** (`--execute`) -- story selection, pipelined review protocol, execution cycle, regression protection
- **Closing** (`--close`) -- independent verifier runs all commands, captures evidence
- **Review** (`--review`) -- re-verify all stories, detect drift
- **Amendment** (`--amend`) -- modify stories with audit trail, handles pending/in-progress/passed states

## Anti-Patterns

See `references/anti-patterns.md` for 11 anti-patterns that kill PRDs and how to prevent them.

## Progress Log

See `references/progress-template.md` for the `.prd/progress.md` template.

## What This Skill Does NOT Do

1. **Schema validation** -- no JSON Schema file ships with this skill. The self-check and critic phases catch structural issues.
2. **Multi-agent coordination** -- if multiple agents work stories in parallel, they must claim stories (set `in_progress`) before starting. No built-in locking.
3. **CI/CD integration** -- this is an agent workflow, not a CI pipeline. Hook it into CI yourself if needed.
4. **Guarantee test quality** -- verify commands prove tests run and pass, not that the tests are good. That's what the e2e story is for.
