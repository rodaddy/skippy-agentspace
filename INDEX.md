# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

### Requires Legend

| Badge | Meaning |
|-------|---------|
| Standalone | Works with vanilla Claude Code, no extra dependencies |
| Needs bun | Requires bun runtime (brew-installable) |
| Needs infra | Requires external infrastructure (MCP servers, Proxmox, etc.) |

## Core

| Skill | Path | Commands | Requires |
|-------|------|----------|----------|
| core [installed] | `core/SKILL.md` | (none) | Needs bun |

## Workflow

| Skill | Path | Commands | Requires |
|-------|------|----------|----------|
| add-todo [installed] | `add-todo/SKILL.md` | (none) | Standalone |
| check-todos [installed] | `check-todos/SKILL.md` | (none) | Standalone |
| correct [installed] | `correct/SKILL.md` | (none) | Standalone |
| session-wrap [installed] | `session-wrap/SKILL.md` | (none) | Standalone |
| skippy-dev [installed] | `skippy-dev/SKILL.md` | /skippy:cleanup, /skippy:migrate, /skippy:reconcile, /skippy:update, /skippy:upgrade | Standalone |
| update-todo [installed] | `update-todo/SKILL.md` | (none) | Standalone |

## Utility

| Skill | Path | Commands | Requires |
|-------|------|----------|----------|
| browser [installed] | `browser/SKILL.md` | (none) | Needs infra |
| excalidraw [installed] | `excalidraw/SKILL.md` | (none) | Needs infra |
| fabric [installed] | `fabric/SKILL.md` | (none) | Needs infra |
| vaultwarden [installed] | `vaultwarden/SKILL.md` | (none) | Needs infra |

## Domain

| Skill | Path | Commands | Requires |
|-------|------|----------|----------|
| deploy-service [installed] | `deploy-service/SKILL.md` | (none) | Needs infra |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
