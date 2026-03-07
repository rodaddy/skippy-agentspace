# skippy-agentspace

Portable skill marketplace for Claude Code. Skills work standalone with vanilla Claude Code, optionally enhanced by PAI infrastructure.

> All LAWs from `~/.claude/CLAUDE.md` apply. bun for Node.js, uv for Python, never npm/yarn/pip.


> All LAWs (#!/bin/bash, protected branches, stack prefs) enforced via ~/.claude/CLAUDE.md and hooks.


## Architecture

```
skippy-agentspace/
  skills/              # Portable skills (each self-contained)
    <name>/
      SKILL.md          # Core directives (~80-150 lines)
      commands/          # Slash command .md files (Claude Code native)
      references/        # Detailed reference docs (loaded on demand)
      bin/               # Scripts (optional)
  tools/                # Marketplace infrastructure
    index-sync.sh        # Validates/regenerates INDEX.md from skills/
    install.sh           # Install a skill into ~/.claude/commands/ + symlinks
    uninstall.sh         # Remove a skill cleanly
  INDEX.md              # Auto-generated skill registry
  CLAUDE.md             # This file
```

## Design Principles

1. **Portable by default** -- every skill works with `~/.claude/commands/` (Claude Code native). No PAI dependency.
2. **PAI-enhanced optionally** -- if PAI is installed, skills can reference LAWs, personas, hooks. But they MUST work without them.
3. **Self-contained** -- each skill declares its own triggers, references, and commands. No cross-skill imports.
4. **Slim core, fat references** -- SKILL.md is the entry point (~150 lines max). Detail lives in references/.
5. **Index stays in sync** -- `tools/index-sync.sh` validates INDEX.md matches actual skills. Run before every commit.

## Skill Anatomy

Each skill directory contains:
- `SKILL.md` -- frontmatter (name, description, triggers) + workflow steps + critical rules
- `commands/` -- one .md file per slash command, symlinked to `~/.claude/commands/<name>/`
- `references/` -- detailed docs loaded on demand by agents
- `bin/` -- executable scripts (optional)

## Installation

```bash
# Install a single skill
./tools/install.sh <skill-name>

# Install all skills
./tools/install.sh --all

# Uninstall
./tools/uninstall.sh <skill-name>
```

## Index Management

```bash
# Validate INDEX.md matches actual skills
./tools/index-sync.sh --check

# Regenerate INDEX.md from skills/ directories
./tools/index-sync.sh --generate
```

## Origin

Born from PAI's skippy-dev skill (2026-03-06). Extracts the best patterns from:
- **GSD** (get-shit-done) -- phased execution, state management, agent spawning
- **OMC** (oh-my-claudecode) -- orchestration loops, parallel execution, teams
- **PAUL** -- context awareness, reconciliation, task anatomy, plan boundaries

The extraction pipeline: usage audit -> identify high-value commands -> extract into portable skills -> monitor upstream for ideas via `/skippy:update`.
