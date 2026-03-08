---
name: skippy-dev
description: Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
---

# skippy-dev -- Development Workflow Enhancements

Additive rules and tools that sharpen planning and execution workflows. Everything here is referenced guidance that agents and main context can load on demand.

## Enhancements

Best-of-breed patterns cherry-picked from PAUL, OMC, and cross-package analysis.

| # | Enhancement | Reference | When It Applies |
|---|-------------|-----------|-----------------|
| 1 | Context Brackets | `references/context-brackets.md` | Every session -- self-monitor context usage |
| 2 | Mandatory Reconciliation | `references/reconciliation.md` | After phase execution, before marking complete |
| 3 | Plan Structure | `references/plan-structure.md` | PLAN.md format spec, task structure, deviation rules, summary format |
| 4 | Plan Boundaries | `references/plan-boundaries.md` | During plan creation -- define what NOT to touch |
| 5 | State Consistency | `references/state-consistency.md` | Before/after phase execution -- cross-file alignment |
| 6 | Model Routing | `references/model-routing.md` | Agent spawning -- match model to task complexity |
| 7 | Verification Loops | `references/verification-loops.md` | Post-implementation -- structured quality feedback |
| 8 | Session Persistence | `references/session-persistence.md` | Session start/end -- context transfer across sessions |
| 9 | Structured Deliberation | `references/structured-deliberation.md` | Architecture decisions -- PDOC framework for options analysis |
| 10 | Skill Extraction | `references/skill-extraction.md` | Pattern promotion -- correction to pattern to skill graduation |
| 11 | Pre-Execution Gate | `references/pre-execution-gate.md` | Before execution -- intercept vague requests, redirect to planning |
| 12 | Ambiguity Scoring | `references/ambiguity-scoring.md` | Before planning -- quantitative requirements clarity gate |
| 13 | Compaction Resilience | `references/compaction-resilience.md` | Mid-session -- checkpoint state before context compaction |
| 14 | Parallel File Ownership | `references/parallel-file-ownership.md` | Parallel execution -- non-overlapping file ownership for concurrent agents |
| 15 | Phased Execution | `references/phased-execution.md` | Phase execution with wave-based parallelism |
| 16 | State Tracking | `references/state-tracking.md` | STATE.md lifecycle, progress tracking, size management |
| 17 | Checkpoints | `references/checkpoints.md` | Human-in-the-loop verification during execution |
| 18 | Audit Swarm | `references/audit-swarm.md` | Multi-agent review -- spawning, findings, fix/eval cycling |

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

Check all tracked upstreams for changes and suggest cherry-picks.

**Workflow:**

1. Read all `upstreams/*/upstream.json` files from the repo root
2. For each upstream: clone or fetch, compare HEAD against last_checked_sha
3. Report changes grouped by area, highlight cherry-picked regions
4. Update tracking (last_checked_sha, last_check) in each upstream.json
5. Flag cross-package analysis for re-review if significant changes detected

No auto-merge -- present findings and let the user decide.

### `/skippy:cleanup`

Manage ephemeral files (debug logs, telemetry, session history).

**Workflow:**

1. Run `${CLAUDE_SKILL_DIR}/scripts/skippy-cleanup.sh [--quarantine|--nuke]`
2. Default is `--quarantine` (moves to a configurable quarantine directory)
3. Reports space freed

### `/skippy:upgrade`

Upgrade skippy-agentspace to latest version preserving customizations.

**Workflow:**

1. Snapshot current state (installed skills, hook count, HEAD commit)
2. Pull latest from origin
3. Re-install all skills and hooks (`tools/install.sh --all`, `skills/core/hooks/install-hooks.sh`)
4. Run `tools/verify.sh` and compare against pre-upgrade snapshot
5. Report changes, new/removed skills, and any customization conflicts

No auto-resolve -- presents options and lets the user decide.

### `/skippy:migrate`

Migrate PAI skills from `~/.config/pai/Skills/` into portable format under `skills/`.

**Workflow:**

1. Scan all directories under `~/.config/pai/Skills/` -- count files, lines, subdirectory structure
2. Check which skills already exist under `skills/` (flag as "already migrated")
3. Rank candidates by priority: daily driver frequency > foundational chain > portable value
4. Present ranked table to user -- wait for approval before proceeding
5. For each approved skill, show dry-run preview (target file tree, SKILL.md preview, what gets stripped/flattened)
6. Migrate: create target directory, slim SKILL.md to <150 lines, flatten subdirs, sanitize private content
7. Update integration files: `marketplace.json`, rebuild `INDEX.md` via `tools/index-sync.sh`

No auto-migration -- presents findings and lets the user decide what to migrate.

### `/skippy:review`

Run a multi-agent code review cycle on the current project or specified scope.

**Workflow:**

1. Determine scope (phase, directory, or full repo)
2. Spawn 4 specialist reviewers sequentially (security, code quality, architecture, consistency)
3. Aggregate findings into shared board at `.reports/skippy-review/findings-{timestamp}.md`
4. Spawn fix agents for CRITICAL and HIGH severity findings
5. Evaluate fixes, cycle if regressions found (max 3 iterations)
6. Generate final audit report with statistics

**Output:** Findings board at `.reports/skippy-review/` with severity-rated findings, fix log, and evaluation results.

## For Agents

When spawning agents (planner, executor, verifier), you can enhance their prompts:

```
Read ${CLAUDE_SKILL_DIR}/references/plan-structure.md
# Include when the agent is creating plans

Read ${CLAUDE_SKILL_DIR}/references/plan-boundaries.md
# Include when the plan needs scope protection

Read ${CLAUDE_SKILL_DIR}/references/state-consistency.md
# Include when the agent touches state files

Read ${CLAUDE_SKILL_DIR}/references/phased-execution.md
# Include when the agent orchestrates multi-plan execution

Read ${CLAUDE_SKILL_DIR}/references/checkpoints.md
# Include when the plan has human verification steps

Read ${CLAUDE_SKILL_DIR}/references/audit-swarm.md
# Include when spawning review agents or running audit cycles
```

Don't load all references into every agent -- pick the relevant one.

## Maintenance

| Reference | Purpose |
|-----------|---------|
| `../../docs/cross-package-analysis.md` | Cross-package pattern analysis across all upstreams -- re-review when `/skippy:update` flags significant changes |
