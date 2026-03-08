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
| skippy-dev [installed] | `skippy-dev/SKILL.md` | /skippy:cleanup, /skippy:migrate, /skippy:reconcile, /skippy:update |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add owner/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
