# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

## Core

| Skill | Path | Commands |
|-------|------|----------|
| core [installed] | `core/SKILL.md` | (none) |

## Workflow

| Skill | Path | Commands |
|-------|------|----------|
| add-todo [installed] | `add-todo/SKILL.md` | (none) |
| autopilot [installed] | `autopilot/SKILL.md` | (none) |
| capture-session [installed] | `capture-session/SKILL.md` | (none) |
| check-todos [installed] | `check-todos/SKILL.md` | (none) |
| correct [installed] | `correct/SKILL.md` | (none) |
| drive [installed] | `drive/SKILL.md` | (none) |
| session-handoff [installed] | `session-handoff/SKILL.md` | (none) |
| session-start [installed] | `session-start/SKILL.md` | (none) |
| session-wrap [installed] | `session-wrap/SKILL.md` | (none) |
| skippy [installed] | `skippy/SKILL.md` | /skippy:cleanup, /skippy:execute, /skippy:install, /skippy:migrate, /skippy:plan, /skippy:progress, /skippy:quick, /skippy:reconcile, /skippy:review, /skippy:update, /skippy:upgrade, /skippy:verify |
| team [installed] | `team/SKILL.md` | (none) |
| update-todo [installed] | `update-todo/SKILL.md` | (none) |

## Utility

| Skill | Path | Commands |
|-------|------|----------|
| brain [installed] | `brain/SKILL.md` | (none) |
| browser [installed] | `browser/SKILL.md` | (none) |
| excalidraw [installed] | `excalidraw/SKILL.md` | (none) |
| fabric [installed] | `fabric/SKILL.md` | (none) |
| gh-review [installed] | `gh-review/SKILL.md` | /gh-review:setup |
| trace [installed] | `trace/SKILL.md` | (none) |
| vaultwarden [installed] | `vaultwarden/SKILL.md` | (none) |

## Domain

| Skill | Path | Commands |
|-------|------|----------|
| deploy-service [installed] | `deploy-service/SKILL.md` | (none) |

## Uncategorized

| Skill | Path | Commands |
|-------|------|----------|
| prd-to-issues [installed] | `prd-to-issues/SKILL.md` | (none) |
| prd [installed] | `prd/SKILL.md` | (none) |
| ubiquitous-language [installed] | `ubiquitous-language/SKILL.md` | (none) |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
