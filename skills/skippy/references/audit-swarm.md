# Audit Swarm -- Multi-Agent Review Protocol

Orchestrate specialist review agents in sequence, aggregate findings into a shared board, spawn fix agents for actionable issues, and cycle evaluation until clean. The main conversation acts as orchestrator -- subagents cannot spawn other subagents.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| v1.1 Audit Process | Ad-hoc multi-agent review (7 rounds, 20+ agents, 17 findings) | Proven at scale -- caught injection vectors, blast radius bugs, security regressions | Not codified -- relied on manual orchestration each time |

## Why This Version

The v1.1 audit was effective but ad-hoc. Each round required manually deciding which reviewers to spawn, how to aggregate findings, and when to stop cycling. This reference doc codifies that process into a repeatable protocol that `/skippy:review` can execute consistently. Key insight: the orchestrator (main conversation) manages all agent spawning because Claude Code prevents nested subagent spawning.

## Orchestration Flow

The 8-step process executed by the `/skippy:review` command:

1. **SCOPE** -- Detect review target (phase directory, file list, or full repo). Accept `--scope` argument or auto-detect from current `.planning/` state.
2. **PREPARE** -- Create findings board at `.reports/skippy-review/findings-{timestamp}.md` with section headers for each reviewer. Record start time.
3. **REVIEW** -- Spawn each reviewer subagent sequentially (security, code-quality, architecture, consistency). Pass scope and board path in the task prompt. Wait for each to complete before spawning the next.

   Review depth adapts to scope:
   | Depth | When | What |
   |---|---|---|
   | **Quick** | <10 files changed, no security-sensitive paths | Code-quality + consistency only |
   | **Standard** | 10-50 files, or any security-sensitive paths | All 4 reviewers |
   | **Deep** | >50 files, architectural changes, or milestone review | All reviewers + additional domain specialists |

   Source: GSD v1.34 code-review depth levels.
4. **SYNTHESIZE** -- Read the full findings board. Cross-reference findings across reviewers (e.g., security injection + code quality validation gap on the same function). Deduplicate overlapping findings.
5. **PRIORITIZE** -- Sort findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Group by file for fix planning. Only CRITICAL and HIGH trigger fix cycles.
6. **FIX** -- Spawn fix agents for each CRITICAL/HIGH finding. Each fix agent receives specific finding details and file paths. Fix agents make atomic commits prefixed `fix(review):`.
7. **EVALUATE** -- Spawn eval agent to verify fixes and check for regressions. If regressions found, spawn targeted fix agents. Loop max 3 times (see Exit Conditions).
8. **REPORT** -- Write final audit report with statistics: findings by severity, fixes applied, regressions caught, evaluation cycles, duration.

## Findings Board Protocol

The shared markdown file serves as the communication channel between agents. Location: `.reports/skippy-review/findings-{timestamp}.md`

```markdown
# Audit Findings Board

**Scope:** [what was reviewed]
**Started:** [timestamp]
**Status:** [in-progress | findings-complete | fixes-applied | verified]

## Security Review
[appended by security-reviewer agent]

## Code Quality Review
[appended by code-quality-reviewer agent]

## Architecture Review
[appended by architecture-reviewer agent]

## Consistency Review
[appended by consistency-reviewer agent]

## Synthesis

### Priority Actions
| # | Severity | Finding | Reviewer | Fix Status |
|---|----------|---------|----------|------------|

## Fix Log
[appended by fix agents -- commit hashes and what was fixed]

## Evaluation
[appended by eval agent -- regression check results]
```

## Severity Classification

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Must fix -- security vulnerabilities, data loss risks, credential exposure | Triggers fix cycle immediately |
| **HIGH** | Should fix -- logic errors, missing error handling, injection vectors | Triggers fix cycle |
| **MEDIUM** | Recommended -- code quality, maintainability, DRY violations | Logged for future cleanup |
| **LOW** | Optional -- style, naming, minor improvements | Logged only |

Only CRITICAL and HIGH findings trigger fix agent spawning. MEDIUM and LOW are documented but not auto-fixed.

## Sandbox Protocol

Three layers of protection, motivated by the v1.1 incident where a red team agent nuked 71 PAI skills by running `uninstall.sh --all` against real HOME:

1. **HOME override in system prompt** -- Every agent includes the instruction to `export HOME=$(mktemp -d)` before any HOME-referencing operation. Best-effort (agent may forget).
2. **Worktree isolation for fix agents** -- The `isolation: worktree` frontmatter field gives fix agents their own git worktree. Changes are isolated until merged. Strongest guarantee for git-level safety.
3. **Tool restrictions for reviewers** -- All 4 reviewers and the eval agent use `permissionMode: plan` (read-only). They have `Read, Grep, Glob, Bash` but cannot write files. The fix agent gets `Write, Edit` but operates in an isolated worktree.

## Agent Roster

| Agent | Role | Model | Permission Mode | Tools | Isolation |
|-------|------|-------|----------------|-------|-----------|
| security-reviewer | Scan for vulnerabilities, injection, secret exposure | sonnet | plan (read-only) | Read, Grep, Glob, Bash | None |
| code-quality-reviewer | Review DRY, error handling, dead code, complexity | sonnet | plan (read-only) | Read, Grep, Glob, Bash | None |
| architecture-reviewer | Check portability, conventions, dependencies, SoC | opus | plan (read-only) | Read, Grep, Glob, Bash | None |
| consistency-reviewer | Verify cross-file alignment (SKILL.md, INDEX.md, state) | sonnet | plan (read-only) | Read, Grep, Glob, Bash | None |
| fix-agent | Apply remediations with atomic commits | sonnet | bypassPermissions | Read, Grep, Glob, Bash, Write, Edit | worktree |
| eval-agent | Verify fixes, detect regressions, provide verdict | sonnet | plan (read-only) | Read, Grep, Glob, Bash | None |

Architecture reviewer uses opus (HIGH complexity per model-routing.md) because architecture analysis requires reasoning about system-wide impact and tradeoffs.

## Adaptive Gating

Track reviewer hit rates over time. If a specialist reviewer produces 0 findings for N consecutive dispatches (suggested: 10), auto-gate that reviewer -- skip dispatching them for similar scopes. This prevents wasting agent calls on reviewers that never find issues in certain codebases.

Rules:
- Security and data-migration reviewers are `[NEVER_GATE]` -- always dispatch regardless of hit rate (insurance reviewers)
- Force flag `--force-all` overrides gating and dispatches all reviewers
- Gating is per-scope-category, not global (a reviewer gated for "docs changes" may still fire for "auth changes")
- Store hit rates in `.reports/skippy-review/reviewer-stats.json`

Source: gstack v0.15 review army adaptive gating.

## Anti-Slop Review Mode

A specialized review pass focused on AI-generated code quality. Deletion-first approach:
- Look for unnecessary abstractions, over-engineering, premature generalization
- Flag code that adds complexity without clear justification
- Use `--review` flag for reviewer-only pass (no auto-fix -- just report)
- Bounded scope: only reviews files changed in the current PR/phase, not the whole repo

Source: OMC v4.10 ai-slop-cleaner skill.

## Exit Conditions

When to stop the fix/eval cycle:

| Condition | Action |
|-----------|--------|
| All CRITICAL/HIGH findings fixed and verified | Exit: success -- write final report |
| Max 3 eval cycles reached | Exit: report remaining failures with diagnosis |
| Same failure appears 3 consecutive times | Exit early: fix approach is wrong, escalate (per verification-loops.md) |
| Environment error (not a code issue) | Exit: report infrastructure problem |
| No CRITICAL/HIGH findings found | Skip fix/eval entirely -- report findings only |

## Integration Points

- **verification-loops.md** -- Cycling protocol used by eval agent (max iterations, same-failure detection, exit conditions)
- **model-routing.md** -- Tier selection for agents (sonnet default, opus for architecture). Orchestrator can override to opus for complex fixes.
- **checkpoints.md** -- Human verification gates. The orchestrator can insert a `checkpoint:human-verify` before applying fixes if running in non-autonomous mode.
- **plan-structure.md** -- Task format used for reporting. Findings map to the verify/done pattern.

## When to Apply

- After phase completion -- review all files created/modified during the phase
- Before milestone release -- full repo review
- Ad-hoc on specific files/directories -- `--scope path/to/dir`
- After major refactoring -- verify no regressions or convention violations

---
*Sources: v1.1 audit process (7 rounds, 20+ agents, 17 findings). Adapted from OMC UltraQA cycling and PAUL verification protocol. Enriched with gstack v0.15 adaptive gating, OMC v4.10 anti-slop review, GSD v1.34 review depth tiers.*
*Last reviewed: 2026-04-06*
