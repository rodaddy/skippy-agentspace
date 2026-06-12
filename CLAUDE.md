# skippy-agentspace

> **Why this exists:** Claude Code marketplaces ship 30-40+ commands each. 85% is ceremony. Skippy is the machine that finds the 15% that matters and proves it with binary assertion evals.

> All LAWs from `~/.claude/CLAUDE.md` apply. `bun` for Node.js, `uv` for Python, never npm/yarn/pip.

## Quick Start

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace && ./tools/install.sh --all
# Optional: GitGuardian secret scanning
bash scripts/setup-ggshield.sh
# In Claude Code: /clear to pick up new skills
```

**New machine bootstrap:** See `bootstrap/INSTALL.md` for portable PAI setup from scratch.

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

See `planning/audits/marketplace-audit-2026-03-13.md` for full audit data.

## Architecture

Four layers:

| Layer | What | Ships As |
|-------|------|----------|
| **Engine** | Consume, coalesce, eval pipeline | `/skippy:consume`, `/skippy:coalesce`, `/skippy:eval`, `/skippy:status` |
| **Knowledge** | Pattern taxonomy, classification heuristics, eval framework | 18 reference docs + `evals/` per ability |
| **Defaults** | Pre-consumed sources + their coalesced output | 11 abilities from GSD+OMC+PAUL+Open Brain |
| **Bootstrap** | Portable PAI setup for new machines | `bootstrap/install.sh`, env/alias/zshrc templates |

## What's Built

```
skills/                     # 88 skills across 5 categories
  core/                     #   [core] (1) PAI identity -- personas, LAWs, rules, templates
  skippy/                   #   [workflow] (14) Dev enhancements, session mgmt, planning, todos
    agents/                 #     Subagent definitions (planning swarm, review swarm, executors)
  brain/                    #   [utility] (7) Browser, excalidraw, fabric, vaultwarden, trace, etc.
  deploy-service/           #   [domain] (1) LXC + Caddy proxy + DNS deployment
  <65 more>                 #   [uncategorized] n8n suite (8), infra, AI/ML, git, research, etc.
bootstrap/
  install.sh                # Portable PAI setup -- backs up, copies, resolves placeholders
  INSTALL.md                # Full bootstrap guide with prerequisite/secrets/verification docs
  env, zshrc, alias         # Shell config templates with __PLACEHOLDER__ conventions
scripts/
  setup-ggshield.sh         # GitGuardian secret scanning setup (non-interactive)
  test-ggshield.sh          # Verify ggshield installation
  daily-purge.sh            # Scheduled cleanup scripts
  refresh-all-code-kbs.sh   # Knowledge base re-indexing
  sync-dev-index.sh         # Development index synchronization
  cleanup-claude-mcps.ts    # MCP server cleanup utility
.claude-plugin/
  marketplace.json          # Plugin marketplace (24 plugins, strict: false)
evals/
  structural/               # Binary assertions for repo integrity (runner.sh + 4 category files)
  behavioral/               # Karpathy-style evals for install UX and repo quality
tools/
  lib/
    common.sh               # Shared shell library (skippy_* helpers: colors, logging, repo root, summary)
  security/                 # Security scanning tools (pattern detection, report generation)
  skill-gen/                # Auto-skill generation pipeline (detect, draft, propose, quarantine)
  install.sh                # Selective installer (--core, --all, positional args)
  uninstall.sh              # Selective uninstaller (handles symlinks AND copied dirs)
  local-install.sh          # Local-only installer (no symlinks, copies skill dirs)
  local-uninstall.sh        # Local-only uninstaller
  index-sync.sh             # Category-grouped INDEX.md generator
  bump-version.sh           # Version bump across all version locations
  verify.sh                 # brew-doctor-style health check
  prereqs.sh                # Cross-platform prerequisite checker
  validate-hooks.sh         # Hook manifest validation
  integration-test.sh       # 36 automated tests, fully sandboxed
  backup-restore.sh         # Snapshot/restore ~/.claude/ before testing
tests/                      # bats-core test suite (1100+ assertions)
INDEX.md                    # Auto-generated skill registry (5 category sections)
VERSION                     # Semantic version (current: 2.0.0)
GLOSSARY.md                 # Ubiquitous language -- shared domain terminology
```

### Skills by Category

| Category | Count | Examples |
|----------|-------|---------|
| Core | 1 | core (personas, LAWs, hooks, templates) |
| Workflow | 14 | skippy, autopilot, drive, prd, session-start/wrap/handoff, todos, team |
| Utility | 7 | brain, browser, excalidraw, fabric, gh-review, trace, vaultwarden |
| Domain | 1 | deploy-service |
| Uncategorized | 65 | n8n suite (8), infra (4), AI/creative (6), git (3), research, debug, prompting |

See [INDEX.md](INDEX.md) for the full catalog with portability badges.

## Commands

### Pipeline (v2.0)

| Command | What It Does |
|---------|-------------|
| `/skippy:consume <source>` | Audit a marketplace/plugin -- classify commands, extract patterns, persist results |
| `/skippy:coalesce` | Merge all consumed patterns into abilities, deduplicate, resolve overlaps |
| `/skippy:eval` | Run Karpathy-style binary assertion loops per ability, auto-fix failures |
| `/skippy:status` | Show consumed sources, abilities, scores, overlap map |

### Dev Workflow

| Command | What It Does |
|---------|-------------|
| `/skippy:reconcile` | Compare planned vs actual for the most recent phase -- reports deviations, flags state drift |
| `/skippy:review` | Multi-agent audit swarm -- spawns specialist reviewers, aggregates findings, applies fixes |
| `/skippy:update` | Check all tracked upstreams for changes and suggest cherry-picks |
| `/skippy:cleanup` | Quarantine or nuke ephemeral files (debug logs, telemetry, session history) |
| `/skippy:plan` | Create phased execution plan for a task |
| `/skippy:execute` | Execute a plan phase by phase |
| `/skippy:verify` | Run verification checks against success criteria |
| `/skippy:upgrade` | Upgrade skippy-agentspace itself |
| `/skippy:migrate` | Migrate between skill framework versions |
| `/skippy:install` | Install individual skills |
| `/skippy:progress` | Show current progress against active plan |
| `/skippy:quick` | Quick-start a task without full planning ceremony |

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

Full audit: `planning/audits/marketplace-audit-2026-03-13.md`

## Constraints

- **Portability**: Tiered -- see table below. Core workflow skills work on vanilla Claude Code. Utility/domain skills may require external infrastructure but document their requirements and fallback behavior.
- **Self-contained**: No cross-skill imports. Each skill is a standalone directory.
- **No build step**: Shell scripts + markdown only. No TypeScript/Node dependencies.
- **Standalone**: No runtime dependency on GSD, PAUL, or OMC. Historical source attribution only.
- **Stack**: `#!/usr/bin/env bash` for scripts. Markdown for rules/references.
- **Placeholder conventions**: Bootstrap templates use `__DOUBLE_UNDERSCORE__` for values resolved at install time (e.g., `__HOME__`, `__GEMINI_API_KEY__`). Skills use `<ANGLE_BRACKET>` for user-supplied values at runtime (e.g., `<source>`, `<skill-name>`).

### Portability Tiers

| Tier | Skills | Notes |
|------|--------|-------|
| **Fully portable** | core, skippy, add-todo, update-todo, check-todos, correct, trace | No external dependencies. Works on any Claude Code install. |
| **Degraded without infra** | autopilot, drive, session-start, session-wrap, session-handoff, brain, capture-session, fabric | Falls back to local files or reduced functionality when Open Brain, mcp2cli, or LiteLLM are unavailable. |
| **Requires setup** | team, browser, vaultwarden, excalidraw, deploy-service, homeassistant, proxmox, n8n | Need specific infrastructure (MCP servers, Proxmox, bun packages). Each skill documents requirements and what happens without them. |

## Project Status

v1.0-v1.2 shipped (16 phases, 39 plans). v2.0 shipped -- portable bootstrap, 88 skills, GitGuardian integration.

| Milestone | What | Status |
|-----------|------|--------|
| v1.0 | Initial release -- spec, packaging, commands, docs | Shipped 2026-03-07 |
| v1.1 | Portable PAI -- 12 skills, upstream tracking, bootstrap | Shipped 2026-03-08 |
| v1.2 | Standalone Skippy -- GSD absorption, audit swarm, testing | Shipped 2026-03-08 |
| v2.0 | Portable bootstrap, 88 skills, GitGuardian, curation engine | Shipped 2026-05 |

## Key Files

| Need | Read |
|------|------|
| Full project context + decisions | `planning/PROJECT.md` |
| Requirements (11 total, all mapped) | `planning/REQUIREMENTS.md` |
| Phase structure + success criteria | `planning/ROADMAP.md` |
| Current position + blockers | `planning/STATE.md` |
| Skill composition + workflow patterns | `ORCHESTRATION.md` |
| Skill index (88 skills by category) | `INDEX.md` |
| Dev workflow skill | `skills/skippy/SKILL.md` |
| Core skill entry point | `skills/core/SKILL.md` |
| Content conventions + upstream registry | `CONVENTIONS.md` |
| Bootstrap guide for new machines | `bootstrap/INSTALL.md` |
| GitGuardian secret scanning setup | `scripts/setup-ggshield.sh` |
