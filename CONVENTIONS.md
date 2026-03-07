# Conventions

## Content Classification

Private content lives externally at `~/.config/pai-private/`. The repo itself is entirely public-safe. No `private/` directory exists in-repo.

| Type | Classification | Location | Examples |
|------|---------------|----------|----------|
| Skills | Public | `skills/` | SKILL.md, commands/, references/ |
| References | Public | `skills/*/references/` | context-brackets.md, plan-boundaries.md |
| Commands | Public | `skills/*/commands/` | reconcile.md, update.md, cleanup.md |
| Tools/Scripts | Public | `tools/`, `skills/*/scripts/` | install.sh, skippy-update.sh |
| Plugin metadata | Public | `.claude-plugin/` | marketplace.json |
| Upstream tracking | Public | `upstreams/` | upstream.json per upstream |
| Planning artifacts | Public | `.planning/` | STATE.md, ROADMAP.md, plans |
| API keys/tokens | Private | `~/.config/pai-private/` | Never in repo |
| Personal preferences | Private | `~/.config/pai-private/memory/` | MEMORY.md, session state |
| Credential patterns | Private | `~/.config/pai-private/rules/` | Security protocols, style rules |
| MCP server configs | Private | Machine-specific | IP addresses, ports |

## Private Content Location

Private content uses the existing PAI pattern -- `~/.config/pai-private/`:

| Directory | Contents |
|-----------|----------|
| `memory/` | MEMORY.md, session state |
| `rules/` | Security protocols, style rules |

This is not new infrastructure. PAI already uses this location. The repo never contains private content -- architectural prevention is the primary protection, with `.gitignore` patterns as a secondary safety net.

## Upstream Registry

Each upstream is a directory under `upstreams/` containing an `upstream.json` file. The directory name is the upstream identifier. `ls upstreams/` is the registry query -- no discovery code needed.

### upstream.json Schema

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | yes | string | Human-readable identifier, matches directory name |
| `description` | yes | string | One-line summary of what this upstream provides |
| `repo` | yes | string (URL) | Git clone URL |
| `branch` | yes | string | Branch to track (usually "main") |
| `last_checked_sha` | yes | string | Last checked commit SHA, or "none" if never checked |
| `last_check` | yes | string | ISO 8601 date (e.g. "2026-03-07") or "never" |
| `cherry_picks` | no | string[] | Ideas/features extracted from this upstream |
| `notes` | no | string | Freeform context about the relationship |

### Adding a New Upstream

1. Create a directory: `mkdir upstreams/<name>`
2. Create `upstreams/<name>/upstream.json` with the schema fields above
3. Done -- no code changes required

Phase 8 will add `upstreams/omc/` using this exact process.

### Example

```json
{
  "name": "gsd",
  "description": "Get Shit Done -- phased execution framework for Claude Code",
  "repo": "https://github.com/gsd-build/get-shit-done.git",
  "branch": "main",
  "last_checked_sha": "none",
  "last_check": "never",
  "cherry_picks": [],
  "notes": "Base infrastructure -- we augment, never modify"
}
```

## Installation Philosophy

v1.1 shifts the installation approach:

| Concern | Handled By | Format |
|---------|-----------|--------|
| Prerequisite validation | Shell scripts | `#!/usr/bin/env bash` -- checks for bun, jq, git, bash 4+ |
| Install/config/update operations | Markdown instruction files | INSTALL.md, UPDATE.md, CONFIG.md -- designed for AI agents |

Existing v1.0 `tools/install.sh` remains for backward compatibility. New v1.1 operations use markdown instructions that AI agents (Claude, Gemini, Codex) execute directly.
