# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

| Skill | Path | Commands | References | Use When |
|-------|------|----------|------------|----------|
| skippy-dev | `skippy-dev/SKILL.md` | /skippy:reconcile, /skippy:update, /skippy:cleanup | context-brackets.md, plan-boundaries.md, reconciliation.md, state-consistency.md, task-anatomy.md | Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, state consistency |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add owner/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
