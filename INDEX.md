# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

| Skill | Path | Commands | References | Use When |
|-------|------|----------|------------|----------|
| core | `core/SKILL.md` | (none -- commands deferred) | personas/, laws/, rules/, templates/ | PAI core infrastructure -- personas, LAWs, rules, and project templates |
| skippy-dev | `skippy-dev/SKILL.md` | /skippy:reconcile, /skippy:update, /skippy:cleanup | context-brackets.md, model-routing.md, plan-boundaries.md, reconciliation.md, session-persistence.md, skill-extraction.md, state-consistency.md, structured-deliberation.md, task-anatomy.md, verification-loops.md | Development workflow enhancements -- context awareness, reconciliation, task rigor, model routing, verification loops, session persistence |

## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add owner/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
