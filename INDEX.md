# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

## Core

| Skill | Path | Commands |
|-------|------|----------|
| core | `core/SKILL.md` | (none) |

## Workflow

| Skill | Path | Commands |
|-------|------|----------|
| add-todo | `add-todo/SKILL.md` | (none) |
| capture-session | `capture-session/SKILL.md` | (none) |
| check-todos | `check-todos/SKILL.md` | (none) |
| correct | `correct/SKILL.md` | (none) |
| session-handoff | `session-handoff/SKILL.md` | (none) |
| session-start | `session-start/SKILL.md` | (none) |
| session-wrap | `session-wrap/SKILL.md` | (none) |
| skippy [installed] | `skippy/SKILL.md` | /skippy:cleanup, /skippy:execute, /skippy:install, /skippy:migrate, /skippy:plan, /skippy:progress, /skippy:quick, /skippy:reconcile, /skippy:review, /skippy:update, /skippy:upgrade, /skippy:verify |
| update-todo | `update-todo/SKILL.md` | (none) |

## Utility

| Skill | Path | Commands |
|-------|------|----------|
| brain | `brain/SKILL.md` | (none) |
| browser | `browser/SKILL.md` | (none) |
| excalidraw | `excalidraw/SKILL.md` | (none) |
| fabric | `fabric/SKILL.md` | (none) |
| gh-review | `gh-review/SKILL.md` | /gh-review:setup |
| vaultwarden | `vaultwarden/SKILL.md` | (none) |

## Domain

| Skill | Path | Commands |
|-------|------|----------|
| deploy-service | `deploy-service/SKILL.md` | (none) |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
