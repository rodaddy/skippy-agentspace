---
name: pai-init
description: Initialize a new project with PAI's CLAUDE.md template. Creates a project-specific CLAUDE.md with standard structure, LAWs reminder, and corrections section.
triggers:
  - /pai-init
  - init project
  - initialize project
  - setup claude
  - create claude.md
---

# pai-init - Project Initialization

Creates a project CLAUDE.md with PAI standards.

## Usage

```
/pai-init              # Initialize current directory
/pai-init <path>       # Initialize specific directory
```

## What It Creates

A `CLAUDE.md` file with:
- LAWs inheritance reminder (points to parent CLAUDE.md files)
- Quick facts section (stack, commands)
- Critical rules section
- Corrections log section (for "not this shit again" items)

## Workflow

1. Check if CLAUDE.md already exists (prompt to overwrite or merge)
2. Detect project type from package.json, Cargo.toml, pyproject.toml, etc.
3. Auto-fill commands based on detected type
4. Create the file

## Template

```markdown
# Project: {name}

> LAWs from ~/.claude/CLAUDE.md and ~/Development/CLAUDE.md ALWAYS apply.
> Personal context available at ~/.config/pai-private/memory/ if needed.

## Quick Facts

- **Stack**: {detected or ask}
- **Package Manager**: bun (NOT npm/yarn)
- **Test**: `bun test`
- **Build**: `bun run build`
- **Lint**: `bun run lint`

## Key Directories

- `src/` - Source code
- `tests/` - Test files

## Project-Specific Rules

{project-specific conventions}

## Corrections Log

Rules added when Claude repeatedly does something wrong in THIS project.

<!-- Format: When Claude does X → Rule: "Do Y instead" -->

- (none yet - add as you encounter them)
```

## Implementation

When invoked:

1. **Detect project root** - Look for package.json, .git, etc.
2. **Check existing** - If CLAUDE.md exists, ask: overwrite, merge, or cancel
3. **Auto-detect stack**:
   - package.json → Node/TypeScript, check for framework
   - Cargo.toml → Rust
   - pyproject.toml/setup.py → Python
   - go.mod → Go
4. **Extract commands** - Read scripts from package.json, Makefile, etc.
5. **Generate CLAUDE.md** - Apply template with detected values
6. **Offer to add to .gitignore** - If user wants CLAUDE.md private

## Notes

- Always uses bun for Node projects (LAW)
- Never creates unnecessary files (LAW)
- Template is minimal - user adds project-specific rules as needed
