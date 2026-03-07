# skippy-agentspace

## What This Is

A portable skill repository for Claude Code that cherry-picks the best development workflow ideas from multiple frameworks (GSD, PAUL, OMC) into standalone, installable skills. First skill: `skippy-dev` -- 5 workflow enhancements that augment GSD with PAUL's best ideas, plus 3 utility commands. Designed for PAI (Rico's personal AI infrastructure) but portable enough for any Claude Code user.

## Core Value

Every skill works standalone with vanilla Claude Code -- no PAI dependency required. Skills are self-contained, installable, and enhanced (not broken) by PAI infrastructure when present.

## Requirements

### Validated

(None yet -- ship to validate)

### Active

- [ ] Origin documentation -- full story of why this exists (YouTube analysis, GSD vs PAUL comparison, architectural decision)
- [ ] 5 PAUL enhancement reference docs with real, actionable content (context brackets, reconciliation, task anatomy, plan boundaries, state consistency)
- [ ] `/skippy:reconcile` command works against a real `.planning/` project with completed phases
- [ ] `/skippy:update` script clones both GSD and PAUL repos, tracks versions, reports diffs
- [ ] `/skippy:cleanup` script quarantines or nukes ephemeral files with space reporting
- [ ] Install/uninstall tooling (`tools/install.sh`, `tools/uninstall.sh`) correctly symlinks skills into `~/.claude/commands/`
- [ ] Index sync (`tools/index-sync.sh`) validates INDEX.md matches actual skills
- [ ] Cold session context -- a new session opening this repo has enough documentation to understand what it is, why it exists, current state, and what to work on next
- [ ] CLAUDE.md includes origin story, architectural decisions, and current project status
- [ ] All scripts pass basic functional testing (run without errors, produce expected output)

### Out of Scope

- Forking GSD or PAUL -- we ride upstream, never fork
- Auto-merging upstream changes -- `/skippy:update` reports, human decides
- Hooks in `~/.claude/settings.json` -- enhancements are rule-based (reference docs), not hook-enforced
- BDD Given/When/Then ceremony for acceptance criteria -- too much overhead for solo dev
- PAUL's "no subagents for execution" philosophy -- GSD's parallel execution is correct at scale
- Publishing to npm or any package registry -- private repo, manual install

## Context

### Origin Story

On 2026-03-06, we watched a YouTube video (MppKHh_MfFc) comparing GSD vs the PAUL framework. After running `fabric extract_wisdom` on it, we cloned PAUL's repo (ChristopherKahler/paul) and did a deep code review.

**What PAUL does well (stolen):**
1. **Context Brackets** -- FRESH/MODERATE/DEEP/CRITICAL behavior adaptation based on context window usage
2. **Mandatory Reconciliation (UNIFY)** -- plan-vs-actual comparison after every phase
3. **Task Anatomy** -- 4 required fields per task: files, action, verify, done
4. **Plan Boundaries** -- explicit DO NOT CHANGE and SCOPE LIMITS in every plan
5. **State Consistency** -- cross-file alignment verification at phase transitions

**What PAUL gets wrong (rejected):**
- No subagents for execution -- works for tiny projects, dies at scale
- "Plans are prompts" -- clever framing for "write specific plans," not novel
- BDD for every acceptance criterion -- ceremony for ceremony's sake on solo projects
- The "70% context loss" claim about GSD subagents -- GSD writes structured artifacts for context transfer

### Architectural Decision

Three approaches were considered:

| Approach | Pros | Cons |
|----------|------|------|
| **PAI Skill + Hooks** (chosen) | No forks, modular, zero upstream maintenance | Parasitic on GSD |
| Full Skippy Framework | Full control, unified commands | Massive maintenance, diverges from both upstreams |
| Just Patch GSD | 30 minutes of work | No update mechanism, per-project, coupled to GSD internals |

We chose the parasitic approach: keep GSD unchanged, inject PAUL's ideas as reference docs that GSD agents can load on demand, and add utility commands for reconciliation, upstream monitoring, and cleanup.

### Relationship to PAI

- **Source:** This repo (`skippy-agentspace/`) is the development copy
- **Installed copy:** `~/.config/pai/Skills/skippy-dev/` (symlinked via `tools/install.sh`)
- **Commands registered:** `~/.claude/commands/skippy/` (symlinks to `skills/skippy-dev/commands/`)
- **Agent access:** Listed in `~/.config/pai/Skills/AGENT-INDEX.md` under "Development Workflow"

### Backup

Pre-change backup created at `~/Desktop/claude_setup/backup-2026-03-06-skippy-dev/` with restore script. Ephemeral files (2.5G of debug/telemetry/history) quarantined to `/Volumes/ThunderBolt/_tmp/claude-cleanup-2026-03-06/`.

## Constraints

- **Portability**: Every skill must work with vanilla Claude Code (`~/.claude/commands/`). PAI enhancements are optional.
- **Self-contained**: Each skill declares its own triggers, references, and commands. No cross-skill imports.
- **Slim core**: SKILL.md is the entry point (~150 lines max). Detail lives in `references/`.
- **No GSD modification**: All enhancements are additive references, never patches to GSD source.
- **Stack**: Shell scripts (`#!/usr/bin/env bash`), markdown for rules/references. No TypeScript/Node dependencies.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Parasitic skill over fork | Zero maintenance, modular, upgradeable | -- Pending |
| Reference docs over hooks | Hooks can't detect context usage; rules are self-enforced | -- Pending |
| Shell scripts for tooling | No build step, no dependencies, portable | -- Pending |
| Quarantine before delete for cleanup | Safer -- verify nothing breaks before nuking | -- Pending |
| Separate agentspace repo | Skills should be portable, not buried in PAI config | -- Pending |

---
*Last updated: 2026-03-06 after initialization*
