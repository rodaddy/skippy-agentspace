# skippy-agentspace

> Portable Claude Code skill repo. Cherry-picks the best workflow ideas from GSD and PAUL into standalone, installable skills.
> All LAWs from `~/.claude/CLAUDE.md` apply. `bun` for Node.js, `uv` for Python, never npm/yarn/pip.


> All LAWs (#!/bin/bash, protected branches, stack prefs) enforced via ~/.claude/CLAUDE.md and hooks.


## What This Is

A skill marketplace repo containing **skippy-dev** -- 5 workflow enhancements and 3 utility commands that augment GSD (get-shit-done) with the best ideas from PAUL (Plan-Apply-Unify Loop). Installs as a Claude Code plugin or via manual symlinks.

**Not a fork.** Both upstreams ride unchanged -- all enhancements are additive reference docs and utility commands.

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
  marketplace.json        # Plugin marketplace definition (strict: false)
skills/skippy-dev/
  SKILL.md                # Entry point -- 3 commands, 5 enhancement refs
  commands/               # /skippy:reconcile, /skippy:update, /skippy:cleanup
  references/             # 5 PAUL enhancement docs
  scripts/                # skippy-update.sh, skippy-cleanup.sh
  .versions               # Upstream version tracking (GSD + PAUL)
tools/
  install.sh              # Dual-target installer (skills/ or commands/)
  uninstall.sh            # Dual-target uninstaller
  index-sync.sh           # Validate/regenerate INDEX.md
INDEX.md                  # Auto-generated skill registry
```

## Commands

| Command | What It Does |
|---------|-------------|
| `/skippy:reconcile` | Compare planned vs actual for the most recent GSD phase -- reports deviations, flags state drift |
| `/skippy:update` | Check GSD and PAUL repos for upstream changes. Reports diffs, human decides what to absorb |
| `/skippy:cleanup` | Quarantine or nuke ephemeral files (debug logs, telemetry, session history). Reports space freed |

## Installation

**Plugin install** (preferred):
```
/plugin marketplace add owner/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

**Manual install:**
```bash
git clone <repo-url>
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

All 4 phases complete. v1 requirements satisfied.

| Phase | Goal | Status |
|-------|------|--------|
| 1. Spec Compliance | Portable paths, Agent Skills frontmatter, `bin/` to `scripts/` | Complete |
| 2. Plugin Packaging | `.claude-plugin/marketplace.json`, dual install targets | Complete |
| 3. Command Validation | Reconcile, update, cleanup commands work end-to-end | Complete |
| 4. Documentation | GSD dependency map, cold session CLAUDE.md | Complete |

## Key Files

| Need | Read |
|------|------|
| Full project context + decisions | `.planning/PROJECT.md` |
| Requirements (11 total, all mapped) | `.planning/REQUIREMENTS.md` |
| Phase structure + success criteria | `.planning/ROADMAP.md` |
| Current position + blockers | `.planning/STATE.md` |
| The actual skill | `skills/skippy-dev/SKILL.md` |
| Content conventions + upstream registry | `CONVENTIONS.md` |
