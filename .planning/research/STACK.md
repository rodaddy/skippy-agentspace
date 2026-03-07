# Technology Stack

**Project:** skippy-agentspace (Portable Claude Code Skill Marketplace)
**Researched:** 2026-03-06
**Overall confidence:** HIGH

## Recommended Stack

### Core Format: Agent Skills Open Standard

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Agent Skills spec | 1.0 | Skill file format (SKILL.md + frontmatter) | Industry standard adopted by 30+ tools (Claude Code, Codex, Gemini CLI, Cursor, VS Code Copilot, Goose, Roo Code, etc.). Write once, run everywhere. |
| YAML frontmatter | -- | Skill metadata (name, description, triggers) | Required by Agent Skills spec. Claude uses `description` for auto-discovery. |
| Markdown | -- | Skill instructions, reference docs, commands | Native format for all AI coding agents. No build step. |

**Confidence:** HIGH -- verified against official Agent Skills spec at agentskills.io and Claude Code docs at code.claude.com/docs/en/skills.

### Distribution: Claude Code Plugin System

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `.claude-plugin/plugin.json` | -- | Plugin manifest | Claude Code's native packaging format. One `plugin.json` describes all bundled skills. |
| `.claude-plugin/marketplace.json` | -- | Marketplace catalog | Enables `/plugin marketplace add` and `/plugin install`. Git repo = marketplace. |
| Git repository (GitHub) | -- | Plugin source and distribution | Anthropic's own skills repo uses this pattern. Users add via `/plugin marketplace add owner/repo`. |

**Confidence:** HIGH -- verified against official docs and Anthropic's own `anthropics/skills` repo marketplace.json.

### Scripting Runtime

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Bash (`#!/usr/bin/env bash`) | 5.x+ | Skill scripts (install, update, cleanup) | Zero dependencies, portable, matches project constraint. Already in use. |
| `${CLAUDE_SKILL_DIR}` | -- | Portable path resolution in SKILL.md | Built-in Claude Code variable. Resolves to the skill's directory at runtime. Eliminates hardcoded absolute paths. |
| `${CLAUDE_PLUGIN_ROOT}` | -- | Portable path in plugin hooks/MCP configs | Built-in Claude Code variable for plugin-scoped scripts. |

**Confidence:** HIGH -- `CLAUDE_SKILL_DIR` confirmed in official Claude Code skills docs (string substitutions table).

### Skill Structure (Per Agent Skills Spec)

| Component | Path | Purpose | Required |
|-----------|------|---------|----------|
| `SKILL.md` | `skills/<name>/SKILL.md` | Entrypoint -- frontmatter + instructions | Yes |
| `references/` | `skills/<name>/references/` | Detailed docs loaded on demand | No |
| `scripts/` (or `bin/`) | `skills/<name>/scripts/` | Executable code agents can run | No |
| `commands/` | `skills/<name>/commands/` | Slash command .md files (Claude Code extension) | No |
| `assets/` | `skills/<name>/assets/` | Templates, schemas, data files | No |

**Note:** The Agent Skills spec uses `scripts/`. Claude Code supports both `scripts/` and `bin/`. Recommend migrating to `scripts/` for cross-tool compatibility.

### Infrastructure Tools

| Tool | Purpose | Why |
|------|---------|-----|
| `tools/install.sh` | Symlink skills to `~/.claude/commands/` | Keep for backward compat with pre-plugin manual install. Plugin system supersedes this for distribution. |
| `tools/index-sync.sh` | Validate INDEX.md matches actual skills | Useful for development. Plugin system handles discovery automatically post-install. |
| `skills-ref` CLI | Validate SKILL.md against Agent Skills spec | Official validation tool from agentskills/agentskills repo. Run in CI or pre-commit. |

## What NOT to Use

| Technology | Why Not | Use Instead |
|------------|---------|-------------|
| npm/yarn for distribution | Adds Node.js dependency to what should be zero-dep markdown+shell | Git repo as plugin marketplace (Anthropic's pattern) |
| TypeScript/Node.js for skill logic | Breaks portability constraint. Skills should be markdown + shell. | Bash scripts in `scripts/` |
| `.claude/commands/` as primary format | Merged into skills system since Claude Code v2.1.3. Commands still work but skills are the future. | `.claude/skills/` with SKILL.md |
| Hardcoded absolute paths in commands | `@/Users/rico/...` breaks portability. Only works on Rico's machine. | `${CLAUDE_SKILL_DIR}` variable or relative paths from SKILL.md |
| Custom skill discovery/loading | Claude Code already handles auto-discovery from `~/.claude/skills/`, `.claude/skills/`, and plugins. | Native Claude Code skill discovery |
| `triggers:` frontmatter field | Not in Agent Skills spec or Claude Code's supported frontmatter. Claude uses `description` for matching. | `description` field with specific keywords |
| Forking GSD or PAUL | Maintenance burden, divergence risk | Parasitic enhancement via reference docs (current approach is correct) |
| MCP servers for skill logic | Overkill for workflow knowledge. MCP is for external connectivity (APIs, databases). | Skills for procedural knowledge, MCP only if external tool integration needed |

## Dual Distribution Strategy

The project needs two distribution paths that coexist:

### Path 1: Plugin Marketplace (Primary -- New Users)

```
skippy-agentspace/
  .claude-plugin/
    marketplace.json          # Marketplace catalog
    plugin.json               # Plugin manifest (if repo itself is the plugin)
  skills/
    skippy-dev/
      SKILL.md
      scripts/                # Renamed from bin/ for spec compliance
      references/
      commands/               # Claude Code slash commands
```

**Install:** `/plugin marketplace add rodaddy/skippy-agentspace` then `/plugin install skippy-dev@skippy-agentspace`

### Path 2: Manual Symlink (Backward Compat -- PAI Users)

```bash
./tools/install.sh skippy-dev
# Creates: ~/.claude/commands/skippy -> skills/skippy-dev/commands/
# Also: ~/.claude/skills/skippy-dev -> skills/skippy-dev/ (NEW)
```

**Why both:** Plugin system is the standard path. Manual symlinks support PAI's existing AGENT-INDEX.md workflow and users who want fine-grained control.

## Agent Skills Spec Compliance Gaps (Current State)

| Spec Requirement | Current State | Fix |
|-----------------|---------------|-----|
| `name` must match directory name | `skippy-dev` in frontmatter matches `skills/skippy-dev/` | OK |
| `description` is required | Present | OK |
| `name` -- no consecutive hyphens | `skippy-dev` has single hyphen | OK |
| `scripts/` directory (not `bin/`) | Uses `bin/` | Rename to `scripts/` |
| `triggers:` not a spec field | Used in current SKILL.md frontmatter | Remove; put trigger keywords in `description` |
| No hardcoded absolute paths | `commands/reconcile.md` has `@/Users/rico/...` | Use `${CLAUDE_SKILL_DIR}` or relative paths |
| `plugin.json` manifest | Missing | Create `.claude-plugin/plugin.json` |
| `marketplace.json` | Missing | Create `.claude-plugin/marketplace.json` |

## Progressive Disclosure Architecture

The Agent Skills spec mandates efficient context use:

1. **Metadata layer** (~100 tokens per skill): `name` + `description` loaded at startup for all installed skills
2. **Instructions layer** (< 5000 tokens recommended): Full SKILL.md body loaded when skill activates
3. **Resources layer** (on demand): `references/`, `scripts/`, `assets/` loaded only when explicitly needed

Current `skippy-dev` SKILL.md is ~84 lines -- well within the 500-line recommendation. Five reference docs are properly separated for on-demand loading. This is correct.

## Version Pinning Strategy

Use `metadata.version` in SKILL.md frontmatter (Agent Skills spec) and `version` in plugin.json:

```yaml
# In SKILL.md frontmatter
metadata:
  author: rodaddy
  version: "0.1.0"
```

```json
// In .claude-plugin/plugin.json
{
  "name": "skippy-dev",
  "version": "0.1.0"
}
```

Marketplace can pin to git refs or SHAs for release channels (stable vs latest).

## Sources

- [Agent Skills Specification](https://agentskills.io/specification) -- open standard, 30+ compatible tools (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- official Anthropic docs (HIGH confidence)
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- official distribution system (HIGH confidence)
- [Anthropic's skills repo marketplace.json](https://github.com/anthropics/skills/blob/main/.claude-plugin/marketplace.json) -- reference implementation (HIGH confidence)
- [Agent Skills GitHub](https://github.com/agentskills/agentskills) -- spec repo with validation tooling (HIGH confidence)
- [Claude Code community FAQ on skills vs plugins](https://x.com/claude_code/status/2009479585172242739) -- "Plugins are containers for distributing skills" (MEDIUM confidence)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) -- community skill collections (MEDIUM confidence)
