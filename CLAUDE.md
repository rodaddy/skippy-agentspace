# skippy-agentspace

> Portable Claude Code skill repo. Cherry-picks the best workflow ideas from GSD and PAUL into standalone, installable skills.
> All LAWs from `~/.claude/CLAUDE.md` apply. `bun` for Node.js, `uv` for Python, never npm/yarn/pip.


> All LAWs (#!/bin/bash, protected branches, stack prefs) enforced via ~/.claude/CLAUDE.md and hooks.


## What This Is

A skill marketplace repo containing **12 portable skills** across 4 categories: core identity, workflow automation, utility tools, and domain-specific deployment. Each skill has a slim SKILL.md (<150 lines) with deep references for detail. Installs as a Claude Code plugin or via manual symlinks.

**Not a fork.** All upstreams ride unchanged -- enhancements are additive reference docs and utility commands.

## Why This Exists

On 2026-03-06, we analyzed the [PAUL framework](https://github.com/ChristopherKahler/paul) after watching a YouTube comparison of GSD vs PAUL. After cloning PAUL's repo and reviewing every file, we identified **5 ideas worth stealing** and rejected the rest.

### What We Stole from PAUL

| # | Enhancement | What It Does | Reference |
|---|-------------|-------------|-----------|
| 1 | Context Brackets | Self-monitor context window usage (FRESH/MODERATE/DEEP/CRITICAL) and adapt behavior | `references/context-brackets.md` |
| 2 | Mandatory Reconciliation | Plan-vs-actual comparison after every phase -- what deviated and why | `references/reconciliation.md` |
| 3 | Task Anatomy | 4 required fields per task: files, action, verify, done | `references/task-anatomy.md` |
| 4 | Plan Boundaries | Explicit DO NOT CHANGE and SCOPE LIMITS in every plan | `references/plan-boundaries.md` |
| 5 | State Consistency | Cross-file alignment verification at phase transitions | `references/state-consistency.md` |

### What We Rejected from PAUL

- **No subagents for execution** -- works for tiny projects, dies at scale. GSD's parallel execution is correct.
- **BDD Given/When/Then for every AC** -- ceremony for ceremony's sake on solo projects.
- **"Plans are prompts" framing** -- clever marketing for "write specific plans," not novel.
- **"70% context loss" claim about GSD** -- GSD writes structured artifacts for context transfer.

## Architecture

Three approaches evaluated. We chose **parasitic skill** -- ride GSD unchanged, inject PAUL's ideas as reference docs.

| Approach | Why Chosen / Rejected |
|----------|----------------------|
| **PAI Skill + Hooks** (chosen) | No forks, modular, zero upstream maintenance. Injects PAUL ideas as reference docs. |
| Full Skippy Framework | Rejected -- massive maintenance burden, diverges from both upstreams |
| Just Patch GSD | Rejected -- no update mechanism, per-project only, coupled to GSD internals |

## What's Built

```
.claude-plugin/
  marketplace.json          # Plugin marketplace (12 skills, strict: false)
skills/
  core/                     # [core] PAI identity -- personas, LAWs, rules, templates
  skippy-dev/               # [workflow] Dev enhancements -- 5 commands, 10 reference docs
  add-todo/                 # [workflow] Scope-aware todo/idea capture
  check-todos/              # [workflow] Unified todo viewer with action routing
  correct/                  # [workflow] Add correction rules to doc Gotchas sections
  session-wrap/             # [workflow] End-of-session file/commit workflow
  update-todo/              # [workflow] Progress, complete, defer, or drop todos
  browser/                  # [utility] Browser automation via MCP and browse CLI
  excalidraw/               # [utility] Mermaid-to-Excalidraw diagram generation
  fabric/                   # [utility] AI content processing (228+ patterns)
  vaultwarden/              # [utility] Fast credential lookup via MCP
  deploy-service/           # [domain] LXC + nginx proxy + DNS deployment
tools/
  install.sh                # Selective installer (--core, --all, positional args)
  uninstall.sh              # Selective uninstaller
  index-sync.sh             # Category-grouped INDEX.md generator
INDEX.md                    # Auto-generated skill registry (4 category sections)
```

## Commands

| Command | What It Does |
|---------|-------------|
| `/skippy:reconcile` | Compare planned vs actual for the most recent GSD phase -- reports deviations, flags state drift |
| `/skippy:update` | Check all tracked upstreams for changes and suggest cherry-picks. Generic -- iterates upstreams/*/upstream.json |
| `/skippy:cleanup` | Quarantine or nuke ephemeral files (debug logs, telemetry, session history). Reports space freed |
| `/skippy:migrate` | Migrate PAI skills to portable format -- scan, rank, dry-run, migrate, update integration |
| `/skippy:upgrade` | Pull latest, re-install skills and hooks, verify, report changes and customization conflicts |

## Installation

**Plugin install** (preferred):
```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

**Manual install:**
```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
./tools/install.sh    # Auto-detects ~/.claude/skills/ (modern) or ~/.claude/commands/ (legacy)
```

**Uninstall:** `./tools/uninstall.sh` (removes symlinks from both targets)

## Upstream Sources

| Repo | What It Is | What We Take |
|------|-----------|-------------|
| [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) | Phased execution framework for Claude Code | Base infrastructure -- we augment, never modify |
| [ChristopherKahler/paul](https://github.com/ChristopherKahler/paul) | Plan-Apply-Unify Loop framework | 5 enhancement ideas (see table above) |

Monitor for upstream changes: `/skippy:update`

## Constraints

- **Portability**: Every skill works with vanilla Claude Code. PAI enhancements optional.
- **Self-contained**: No cross-skill imports. Each skill is a standalone directory.
- **No build step**: Shell scripts + markdown only. No TypeScript/Node dependencies.
- **No GSD modification**: All enhancements are additive references, never patches.
- **Stack**: `#!/usr/bin/env bash` for scripts. Markdown for rules/references.

## Project Status

v1 complete. v1.1 in progress -- 12 skills migrated, skill system operational.

| Phase | Goal | Status |
|-------|------|--------|
| 1-4 (v1) | Spec, packaging, commands, docs | Complete |
| 5. Foundation | Conventions, upstream tracking | Complete |
| 6. Skill Content | Core + skippy-dev content | Complete |
| 7. Hooks | LAW enforcement hooks | Complete |
| 8. Upstream Integration | OMC cherry-picks, reference docs | Complete |
| 9. Skill System | Selective install, migrate, 12 skills | Complete |
| 10. Production Readiness | Final validation | Planned |

## Key Files

| Need | Read |
|------|------|
| Full project context + decisions | `.planning/PROJECT.md` |
| Requirements (11 total, all mapped) | `.planning/REQUIREMENTS.md` |
| Phase structure + success criteria | `.planning/ROADMAP.md` |
| Current position + blockers | `.planning/STATE.md` |
| Skill index (all 12 skills by category) | `INDEX.md` |
| Dev workflow skill | `skills/skippy-dev/SKILL.md` |
| Core skill entry point | `skills/core/SKILL.md` |
| Content conventions + upstream registry | `CONVENTIONS.md` |
