# skippy-agentspace

> **Why this exists:** Claude Code marketplaces ship 30-40+ commands each. 85% is ceremony. Skippy is the machine that finds the 15% that matters and proves it with binary assertion evals.

> All LAWs from `~/.claude/CLAUDE.md` apply. `bun` for Node.js, `uv` for Python, never npm/yarn/pip.

## Quick Start

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace && ./tools/install.sh --all
# In Claude Code: /clear to pick up new skills
```

## What This Is

A **skill curation engine** for Claude Code. Pull in any number of marketplaces/plugins. Skippy audits each one, extracts valuable patterns, coalesces them into deduplicated abilities, and verifies every ability with Karpathy-style binary assertion eval loops.

**Pipeline:** Consume -> Coalesce -> Eval -> Iterate -> Ship

Not "here's some skills, trust us." Instead: "here's skills with assertions proving they work, and the machine that built them."

## Why This Exists

Claude Code has a growing ecosystem of marketplaces and plugins (GSD, OMC, PAUL, superpowers, etc.). Each ships 30-40+ commands. Most are ceremony, overlap, or marketing. The actual value in any marketplace is 5-7 core patterns buried under wrapper commands.

Skippy is the machine that extracts those patterns. We audited 93 commands across 6 sources:
- **85% cut** -- 60 commands were ceremony, duplicates, or self-referential tooling
- **11 abilities** emerged from the remaining 15% after cross-source deduplication
- **103 structural assertions** verify repo integrity on every commit
- **Per-skill Karpathy evals** prove each skill actually works (not just that it exists)

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
  marketplace.json          # Plugin marketplace (24 skills, strict: false)
skills/
  core/                     # [core] PAI identity -- personas, LAWs, rules, templates
  skippy/                   # [workflow] Dev enhancements -- 12 commands, 18 reference docs
    agents/                 # Subagent definitions (11 agents: planning swarm, review swarm, executors)
  add-todo/                 # [workflow] Scope-aware todo/idea capture
  autopilot/                # [workflow] Full autonomous lifecycle -- expand, plan, execute, QA, validate
  brain/                    # [utility] Second Brain knowledge base queries via Open Brain
  browser/                  # [utility] Browser automation via MCP and browse CLI
  capture-session/          # [workflow] Capture session insights to Open Brain
  check-todos/              # [workflow] Unified todo viewer with action routing
  correct/                  # [workflow] Add correction rules to doc Gotchas sections
  deploy-service/           # [domain] LXC + nginx proxy + DNS deployment
  drive/                    # [workflow] Persistence loop -- PRD stories, acceptance criteria, architect sign-off
  excalidraw/               # [utility] Mermaid-to-Excalidraw diagram generation
  fabric/                   # [utility] AI content processing (228+ patterns)
  gh-review/                # [utility] Claude Code review workflow with self-hosted runner
  prd/                      # [workflow] Bulletproof PRDs with machine-verifiable acceptance criteria
  prd-to-issues/            # [workflow] Break PRDs into GitHub issues with vertical slicing
  session-handoff/          # [workflow] Generate targeted first message for next session
  session-start/            # [workflow] Pick up where you left off after /clear
  session-wrap/             # [workflow] End-of-session file/commit workflow
  team/                     # [workflow] Coordinated N-agent execution via Claude Code native teams
  trace/                    # [utility] Agent flow visualization -- session timeline and summary
  ubiquitous-language/      # [workflow] Project glossary for shared domain terminology
  update-todo/              # [workflow] Progress, complete, defer, or drop todos
  vaultwarden/              # [utility] Fast credential lookup via MCP
evals/
  structural/               # 68 binary assertions for repo integrity (runner.sh)
  behavioral/               # Karpathy-style evals for install UX and repo quality
tools/
  lib/
    common.sh               # Shared shell library (skippy_* helpers: colors, logging, repo root, summary)
  install.sh                # Selective installer (--core, --all, positional args)
  uninstall.sh              # Selective uninstaller (handles symlinks AND copied dirs)
  index-sync.sh             # Category-grouped INDEX.md generator
INDEX.md                    # Auto-generated skill registry (4 category sections)
VERSION                     # Semantic version (current: 1.2.0)
GLOSSARY.md                 # Ubiquitous language -- shared domain terminology
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
| [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 38 | 13 | 25 | Loop, Interview, Review, Plan (adversarial) |
| [ChristopherKahler/paul](https://github.com/ChristopherKahler/paul) | 5 | 5 | 0 | Context brackets, reconciliation, plan boundaries |
| [garrytan/gstack](https://github.com/garrytan/gstack) | 25 | 0 | 25 | 8 patterns enriched existing abilities |
| [obra/superpowers](https://github.com/obra/superpowers) | 14 | 0 | 14 | Anti-rationalization, hard-gate, two-stage review |
| Open Brain (local) | 18 patterns | 6 | 12 | Remember |

Full audit: `.planning/audits/marketplace-audit-2026-03-13.md`

## Constraints

- **Portability**: Tiered -- see table below. Core workflow skills work on vanilla Claude Code. Utility/domain skills may require external infrastructure but document their requirements and fallback behavior.
- **Self-contained**: No cross-skill imports. Each skill is a standalone directory.
- **No build step**: Shell scripts + markdown only. No TypeScript/Node dependencies.
- **Standalone**: No runtime dependency on GSD, PAUL, or OMC. Historical source attribution only.
- **Stack**: `#!/usr/bin/env bash` for scripts. Markdown for rules/references.

### Portability Tiers

| Tier | Skills | Notes |
|------|--------|-------|
| **Fully portable** | core, skippy, add-todo, update-todo, check-todos, correct, trace | No external dependencies. Works on any Claude Code install. |
| **Degraded without infra** | autopilot, drive, session-start, session-wrap, session-handoff, brain, capture-session, fabric | Falls back to local files or reduced functionality when Open Brain, mcp2cli, or LiteLLM are unavailable. |
| **Requires setup** | team, browser, vaultwarden, excalidraw, deploy-service | Need specific infrastructure (MCP servers, Proxmox, bun packages). Each skill documents requirements and what happens without them. |

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
| Skill index (all 24 skills by category) | `INDEX.md` |
| Dev workflow skill | `skills/skippy/SKILL.md` |
| Core skill entry point | `skills/core/SKILL.md` |
| Content conventions + upstream registry | `CONVENTIONS.md` |
