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
| check-todos [installed] | `check-todos/SKILL.md` | (none) |
| correct [installed] | `correct/SKILL.md` | (none) |
| session-wrap [installed] | `session-wrap/SKILL.md` | (none) |
| skippy-dev [installed] | `skippy-dev/SKILL.md` | /skippy:cleanup, /skippy:migrate, /skippy:reconcile, /skippy:update, /skippy:upgrade |
| update-todo [installed] | `update-todo/SKILL.md` | (none) |

## Utility

| Skill | Path | Commands |
|-------|------|----------|
| browser [installed] | `browser/SKILL.md` | (none) |
| excalidraw [installed] | `excalidraw/SKILL.md` | (none) |
| fabric [installed] | `fabric/SKILL.md` | (none) |
| vaultwarden [installed] | `vaultwarden/SKILL.md` | (none) |

## Domain

| Skill | Path | Commands |
|-------|------|----------|
| deploy-service [installed] | `deploy-service/SKILL.md` | (none) |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
