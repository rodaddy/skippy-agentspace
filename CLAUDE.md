# skippy-agentspace

> All LAWs from `~/.claude/CLAUDE.md` apply. bun for Node.js, uv for Python, never npm/yarn/pip.


> All LAWs (#!/bin/bash, protected branches, stack prefs) enforced via ~/.claude/CLAUDE.md and hooks.


## What This Is

A portable Claude Code skill repo that cherry-picks the best development workflow ideas from **GSD** (get-shit-done) and **PAUL** (Plan-Apply-Unify Loop) into standalone, installable skills. First (and currently only) skill: **skippy-dev**.

**Not a fork.** We ride both upstreams unchanged -- all enhancements are additive reference docs and utility commands.

## Why This Exists

On 2026-03-06, we analyzed the [PAUL framework](https://github.com/ChristopherKahler/paul) after watching a YouTube comparison of GSD vs PAUL. After cloning PAUL's repo and reviewing every file, we identified **5 ideas worth stealing** and **several ideas to reject**.

### What We Stole from PAUL

| # | Enhancement | What It Does | Reference |
|---|-------------|-------------|-----------|
| 1 | Context Brackets | Self-monitor context window usage (FRESH/MODERATE/DEEP/CRITICAL) and adapt behavior | `skills/skippy-dev/references/context-brackets.md` |
| 2 | Mandatory Reconciliation | Plan-vs-actual comparison after every phase -- what deviated and why | `skills/skippy-dev/references/reconciliation.md` |
| 3 | Task Anatomy | 4 required fields per task: files, action, verify, done | `skills/skippy-dev/references/task-anatomy.md` |
| 4 | Plan Boundaries | Explicit DO NOT CHANGE and SCOPE LIMITS in every plan | `skills/skippy-dev/references/plan-boundaries.md` |
| 5 | State Consistency | Cross-file alignment verification at phase transitions | `skills/skippy-dev/references/state-consistency.md` |

### What We Rejected from PAUL

- **No subagents for execution** -- works for tiny projects, dies at scale. GSD's parallel execution is correct.
- **BDD Given/When/Then for every AC** -- ceremony for ceremony's sake on solo projects.
- **"Plans are prompts" framing** -- clever marketing for "write specific plans," not novel.
- **"70% context loss" claim about GSD** -- GSD writes structured artifacts for context transfer.

### Architectural Decision

Three approaches were evaluated. We chose **parasitic skill** (option 1):

| Approach | Why Chosen / Rejected |
|----------|----------------------|
| **PAI Skill + Hooks** (chosen) | No forks, modular, zero upstream maintenance. Rides GSD, injects PAUL ideas as reference docs. |
| Full Skippy Framework | Rejected -- massive maintenance burden, diverges from both upstreams |
| Just Patch GSD | Rejected -- no update mechanism, per-project only, coupled to GSD internals |

## Current Status

**GSD project initialized** with 4 phases. See `.planning/` for full state.

| Phase | Goal | Status |
|-------|------|--------|
| 1. Spec Compliance | Portable paths, Agent Skills frontmatter, `bin/` → `scripts/` | Not started |
| 2. Plugin Packaging | `.claude-plugin/plugin.json`, dual install targets | Not started |
| 3. Command Validation | Reconcile, update, cleanup commands work end-to-end | Not started |
| 4. Documentation | GSD dependency map, cold session CLAUDE.md | Not started |

**Next action:** `/gsd:plan-phase 1` or `/gsd:discuss-phase 1`

## What's Already Built

```
skills/skippy-dev/
  SKILL.md              # Entry point -- 3 commands, 5 enhancement refs
  commands/              # /skippy:reconcile, /skippy:update, /skippy:cleanup
  references/            # 5 PAUL enhancement docs (context brackets, reconciliation, etc.)
  scripts/               # skippy-update.sh, skippy-cleanup.sh
  .versions              # Upstream version tracking (GSD + PAUL)
tools/
  install.sh             # Symlink skill into ~/.claude/commands/
  uninstall.sh           # Remove symlinks
  index-sync.sh          # Validate/regenerate INDEX.md
INDEX.md                 # Auto-generated skill registry
```

## Key Files for Context

| Need | Read |
|------|------|
| Full project context + decisions | `.planning/PROJECT.md` |
| What we're building (11 requirements) | `.planning/REQUIREMENTS.md` |
| Phase structure + success criteria | `.planning/ROADMAP.md` |
| Current position + blockers | `.planning/STATE.md` |
| Domain research (stack, features, architecture, pitfalls) | `.planning/research/SUMMARY.md` |
| The actual skill being built | `skills/skippy-dev/SKILL.md` |

## Upstream Sources

| Repo | What It Is | What We Take |
|------|-----------|-------------|
| [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) | Phased execution framework for Claude Code | Base infrastructure -- we augment, never modify |
| [ChristopherKahler/paul](https://github.com/ChristopherKahler/paul) | Plan-Apply-Unify Loop framework | 5 enhancement ideas (see table above) |

Monitor for upstream changes: `/skippy:update`

## Constraints

- **Portability**: Every skill must work with vanilla Claude Code. PAI enhancements optional.
- **Self-contained**: No cross-skill imports. Each skill is a standalone directory.
- **No build step**: Shell scripts + markdown only. No TypeScript/Node dependencies.
- **No GSD modification**: All enhancements are additive references, never patches.
- **Stack**: `#!/usr/bin/env bash` for scripts. Markdown for rules/references.
