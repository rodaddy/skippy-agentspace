# skippy-agentspace

> Standalone Claude Code skill framework with patterns adapted from GSD, PAUL, and OMC.
> All LAWs from `~/.claude/CLAUDE.md` apply. `bun` for Node.js, `uv` for Python, never npm/yarn/pip.


> All LAWs (#!/bin/bash, protected branches, stack prefs) enforced via ~/.claude/CLAUDE.md and hooks.


## What This Is

A **skill curation engine** for Claude Code. Pull in any number of marketplaces/plugins. Skippy audits each one, extracts valuable patterns, coalesces them into deduplicated abilities, and verifies every ability with Karpathy-style binary assertion eval loops.

**Pipeline:** Consume -> Coalesce -> Eval -> Iterate -> Ship

Not "here's some skills, trust us." Instead: "here's skills with assertions proving they work, and the machine that built them."

## Why This Exists

Claude Code has a growing ecosystem of marketplaces and plugins (GSD, OMC, PAUL, superpowers, etc.). Each ships 30-40+ commands. Most are ceremony, overlap, or marketing. The actual value in any marketplace is 5-7 core patterns buried under wrapper commands.

Skippy is the machine that extracts those patterns. On 2026-03-13, we ran the first manual audit:
- **93 commands** audited across GSD (32), OMC (38), Open Brain (18 patterns), PAUL (5)
- **85% cut** -- 60 commands were ceremony, duplicates, or self-referential tooling
- **11 abilities** emerged from the remaining 15% after cross-source deduplication
- **8 process failures** from the manual run became pipeline features

See `.planning/audits/marketplace-audit-2026-03-13.md` for full audit data.

## Architecture

Three layers:

| Layer | What | Ships As |
|-------|------|----------|
| **Engine** | Consume, coalesce, eval pipeline | `/skippy:consume`, `/skippy:coalesce`, `/skippy:eval`, `/skippy:status` |
| **Knowledge** | Pattern taxonomy, classification heuristics, eval framework | 18 reference docs + `evals/` per ability |
| **Defaults** | Pre-consumed sources + their coalesced output | 11 abilities from GSD+OMC+PAUL+Open Brain |

## What's Built

```
.claude-plugin/
  marketplace.json          # Plugin marketplace (16 skills, strict: false)
skills/
  core/                     # [core] PAI identity -- personas, LAWs, rules, templates
  skippy/                   # [workflow] Dev enhancements -- 12 commands, 18 reference docs
    agents/                 # Subagent definitions (11 agents: planning swarm, review swarm, executors)
  add-todo/                 # [workflow] Scope-aware todo/idea capture
  autopilot/                # [workflow] Full autonomous lifecycle -- expand, plan, execute, QA, validate
  check-todos/              # [workflow] Unified todo viewer with action routing
  correct/                  # [workflow] Add correction rules to doc Gotchas sections
  drive/                    # [workflow] Persistence loop -- PRD stories, acceptance criteria, architect sign-off
  session-wrap/             # [workflow] End-of-session file/commit workflow
  team/                     # [workflow] Coordinated N-agent execution via Claude Code native teams
  update-todo/              # [workflow] Progress, complete, defer, or drop todos
  browser/                  # [utility] Browser automation via MCP and browse CLI
  excalidraw/               # [utility] Mermaid-to-Excalidraw diagram generation
  fabric/                   # [utility] AI content processing (228+ patterns)
  trace/                    # [utility] Agent flow visualization -- session timeline and summary
  vaultwarden/              # [utility] Fast credential lookup via MCP
  deploy-service/           # [domain] LXC + nginx proxy + DNS deployment
tools/
  lib/
    common.sh               # Shared shell library (skippy_* helpers: colors, logging, repo root, summary)
  install.sh                # Selective installer (--core, --all, positional args)
  uninstall.sh              # Selective uninstaller
  index-sync.sh             # Category-grouped INDEX.md generator
INDEX.md                    # Auto-generated skill registry (4 category sections)
```

## Commands

### Pipeline (v2.0 -- in development)

| Command | What It Does |
|---------|-------------|
| `/skippy:consume <source>` | Audit a marketplace/plugin -- classify commands, extract patterns, persist results |
| `/skippy:coalesce` | Merge all consumed patterns into abilities, deduplicate, resolve overlaps |
| `/skippy:eval` | Run Karpathy-style binary assertion loops per ability, auto-fix failures |
| `/skippy:status` | Show consumed sources, abilities, scores, overlap map |

### Existing (v1.x)

| Command | What It Does |
|---------|-------------|
| `/skippy:reconcile` | Compare planned vs actual for the most recent phase -- reports deviations, flags state drift |
| `/skippy:review` | Multi-agent audit swarm -- spawns specialist reviewers, aggregates findings, applies fixes |
| `/skippy:update` | Check all tracked upstreams for changes and suggest cherry-picks |
| `/skippy:cleanup` | Quarantine or nuke ephemeral files (debug logs, telemetry, session history) |

## Installation

**Plugin install** (preferred):
```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy@skippy-agentspace
```

**Manual install:**
```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
./tools/install.sh    # Auto-detects ~/.claude/skills/ (modern) or ~/.claude/commands/ (legacy)
```

**Uninstall:** `./tools/uninstall.sh` (removes symlinks from both targets)

## Consumed Sources (defaults)

| Source | Commands Audited | Kept | Cut | Key Abilities |
|--------|-----------------|------|-----|---------------|
| [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) | 32 | 10 | 22 | Bootstrap, Plan, Execute, Verify, Persist, Debug |
| [anthropics/oh-my-claudecode](https://github.com/anthropics/oh-my-claudecode) | 38 | 13 | 25 | Loop, Interview, Review, Plan (adversarial) |
| [ChristopherKahler/paul](https://github.com/ChristopherKahler/paul) | 5 | 5 | 0 | Context brackets, reconciliation, plan boundaries |
| Open Brain (local) | 18 patterns | 6 | 12 | Remember |

Full audit: `.planning/audits/marketplace-audit-2026-03-13.md`

## Constraints

- **Portability**: Every skill works with vanilla Claude Code. PAI enhancements optional.
- **Self-contained**: No cross-skill imports. Each skill is a standalone directory.
- **No build step**: Shell scripts + markdown only. No TypeScript/Node dependencies.
- **Standalone**: No runtime dependency on GSD, PAUL, or OMC. Historical source attribution only.
- **Stack**: `#!/usr/bin/env bash` for scripts. Markdown for rules/references.

## Project Status

v1.0-v1.2 shipped (16 phases, 39 plans). v2.0 in planning -- curation engine.

| Milestone | What | Status |
|-----------|------|--------|
| v1.0 | Initial release -- spec, packaging, commands, docs | Shipped 2026-03-07 |
| v1.1 | Portable PAI -- 12 skills, upstream tracking, bootstrap | Shipped 2026-03-08 |
| v1.2 | Standalone Skippy -- GSD absorption, audit swarm, testing | Shipped 2026-03-08 |
| **v2.0** | **Curation Engine -- consume/coalesce/eval pipeline** | **Planning** |

## Key Files

| Need | Read |
|------|------|
| Full project context + decisions | `.planning/PROJECT.md` |
| Requirements (11 total, all mapped) | `.planning/REQUIREMENTS.md` |
| Phase structure + success criteria | `.planning/ROADMAP.md` |
| Current position + blockers | `.planning/STATE.md` |
| Skill composition + workflow patterns | `ORCHESTRATION.md` |
| Skill index (all 12 skills by category) | `INDEX.md` |
| Dev workflow skill | `skills/skippy/SKILL.md` |
| Core skill entry point | `skills/core/SKILL.md` |
| Content conventions + upstream registry | `CONVENTIONS.md` |
