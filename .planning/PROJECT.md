# skippy-agentspace

## What This Is

A portable PAI infrastructure package for Claude Code. Core system (personas, LAWs, hooks, commands) plus add-on skills -- all bootstrappable on a new machine from a single repo. Cherry-picks the best ideas from GSD, PAUL, and OMC as upstream sources. Every skill follows the slim-core pattern: small SKILL.md entry point with deep reference docs in folders, so everything is available without eating context.

## Core Value

Every skill works standalone with vanilla Claude Code -- no PAI dependency required. Skills are self-contained, installable, and enhanced (not broken) by PAI infrastructure when present.

## Current Milestone: v1.2 Standalone Skippy

**Goal:** Skippy IS the framework -- no external dependencies on GSD, PAUL, or OMC at runtime. Automated testing, code quality, and a formalized multi-agent audit swarm.

**Target features:**
- GSD pattern absorption (phased execution, state tracking, plan structure, wave-based parallelism, checkpoints, verification loops)
- `/skippy:review` audit swarm command (multi-agent review/fix/eval loop, sandboxed)
- bats-core test suite (~260 lines minimum)
- DRY extraction (`tools/lib/common.sh`)
- deploy-service hardening (config mechanism, input validation, root guards)
- CONTRIBUTING.md
- `.gitattributes` export-ignore for `.planning/`
- Version bump mechanism

## Requirements

### Validated

<!-- Shipped in v1.0 and confirmed working. -->

- ✓ Origin documentation -- full story of why this exists -- v1.0
- ✓ 5 PAUL enhancement reference docs with real, actionable content -- v1.0
- ✓ `/skippy:reconcile` command works against a real `.planning/` project -- v1.0
- ✓ `/skippy:update` script clones both repos, tracks versions, reports diffs -- v1.0
- ✓ `/skippy:cleanup` script quarantines or nukes ephemeral files -- v1.0
- ✓ Install/uninstall tooling correctly symlinks skills -- v1.0
- ✓ Index sync validates INDEX.md matches actual skills -- v1.0
- ✓ Cold session context for new sessions -- v1.0
- ✓ CLAUDE.md includes origin story and architectural decisions -- v1.0
- ✓ All scripts pass basic functional testing -- v1.0
- ✓ OMC analysis and cherry-pick (third upstream alongside GSD and PAUL) -- v1.1
- ✓ Extensible upstream system -- add new packages/marketplaces to cherry-pick from -- v1.1
- ✓ Core infrastructure package (personas, LAWs, hooks, commands) -- v1.1
- ✓ All PAI skills restructured to slim SKILL.md + deep references pattern -- v1.1
- ✓ Add-on skill system (opt-in installation per skill) -- v1.1
- ✓ New machine bootstrap (clone + install = working PAI) -- v1.1

### Active

<!-- v1.2 scope -- defined during requirements phase. -->

(Defining in v1.2 milestone)

### Out of Scope

- Forking GSD or PAUL -- historical source attribution only
- Auto-merging upstream changes -- `/skippy:update` reports, human decides
- BDD Given/When/Then ceremony for acceptance criteria -- too much overhead for solo dev
- PAUL's "no subagents for execution" philosophy -- parallel execution is correct at scale
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
| **PAI Skill + Hooks** (chosen) | No forks, modular, zero upstream maintenance | Derived from GSD patterns |
| Full Skippy Framework | Full control, unified commands | Massive maintenance, diverges from both upstreams |
| Just Patch GSD | 30 minutes of work | No update mechanism, per-project, coupled to GSD internals |

We chose the portable skill repo approach: standalone execution with source attribution to GSD and PAUL, plus utility commands for reconciliation, upstream monitoring, and cleanup.

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
- **Standalone execution**: Skippy defines its own execution protocol via reference docs. GSD credited as source, not required as dependency.
- **Stack**: Shell scripts (`#!/usr/bin/env bash`) for tools, markdown for rules/references. Bun/TypeScript for structured data operations (YAML parsing, state management).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Portable skill repo over fork | Zero maintenance, modular, upgradeable | -- Pending |
| Reference docs over hooks | Hooks can't detect context usage; rules are self-enforced | -- Pending |
| Shell scripts for tooling | No build step, no dependencies, portable | -- Pending |
| Quarantine before delete for cleanup | Safer -- verify nothing breaks before nuking | -- Pending |
| Separate agentspace repo | Skills should be portable, not buried in PAI config | -- Pending |

---
*Last updated: 2026-03-08 after v1.2 milestone start*
