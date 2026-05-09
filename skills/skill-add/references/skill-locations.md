<!-- Extracted from SKILL.md -- load on demand -->

# Skill Locations and Registration

## Location Types

| Type | Source Path | Symlink Target | When to Use |
|------|------------|----------------|-------------|
| **Global** | `~/.config/pai/Skills/<name>/` | `~/.claude/skills/<name>` | General-purpose, shareable |
| **Private** | `~/.config/pai-private/Skills/<name>/` | `~/.claude/skills/<name>` | Personal, sensitive, work-specific |
| **Project** | `<project>/.claude/skills/<name>/` | None (auto-discovered) | Project-specific workflows |

**Default:** Global (`~/.config/pai/Skills/`)

## Symlink Rules

**CRITICAL:** Global and private skills MUST be symlinked to `~/.claude/skills/` to be discovered by Claude Code.

```bash
# Global skill
ln -s ~/.config/pai/Skills/<name> ~/.claude/skills/<name>

# Private skill
ln -s ~/.config/pai-private/Skills/<name> ~/.claude/skills/<name>

# Project skill -- NO symlink needed
# Claude Code auto-discovers from <project>/.claude/skills/
```

## Directory Structure

```
~/.config/pai/Skills/<name>/
  SKILL.md              # Core directives (~80-150 lines)
  references/           # Detailed reference material
    architecture.md     # System architecture docs
    commands.md         # Command reference tables
    troubleshooting.md  # Known issues and fixes
    ...
  scripts/              # Optional -- only if skill has custom scripts
```

## ~/.claude/skills/ Management

This directory should contain ONLY symlinks. Source of truth is always in `~/.config/pai/` or `~/.config/pai-private/`.

```bash
# Verify all are symlinks
ls -la ~/.claude/skills/
# Everything should show -> pointing to source
```

## When to Use Memory Instead of a Skill

Create a memory file (`~/.config/pai-private/memory/<name>.md`) when:
- No custom workflow or multi-step process
- Just facts, procedures, or reference data
- Uses only existing tools (no special orchestration)
- Content is stable and doesn't need `references/` growth

Create a skill when:
- Repeatable multi-step workflow
- Reference material that grows over time
- Needs to be invocable by trigger phrase
- Benefits from on-demand loading (not always in context)
