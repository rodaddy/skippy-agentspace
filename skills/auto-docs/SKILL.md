---
name: auto-docs
description: Automatic API documentation from TSDoc comments. Auto-enforced on commit. USE WHEN setting up new TS project OR user asks to "setup auto-docs" OR "enable docs".
triggers:
  - setup auto-docs
  - enable auto-docs
  - auto-docs setup
  - configure documentation
---

# auto-docs - Self-Documenting TypeScript

Automatically generates API documentation from TSDoc comments and enforces it stays in sync on every commit.

## Features

- **TSDoc → Markdown** - Extracts function/class docs using TypeDoc
- **Auto-enforcement** - Blocks commits if docs are out of sync (like LAW7)
- **Shared tool** - One tool at `~/.config/pai/Tools/auto-docs-generate.ts`
- **Global git hook** - Works in all TS projects automatically

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **Setup** | "setup auto-docs" | `Workflows/Setup.md` |
| **Status** | "check auto-docs" | `Workflows/Status.md` |

## Quick Start

```bash
# In any TypeScript library project
auto-docs setup
```

## How It Works

1. **Write TSDoc comments** in your TypeScript files
2. **Add markers** to README.template.md: `<!-- API START -->` and `<!-- API END -->`
3. **Commit code** - Hook auto-generates docs and enforces sync
4. **If docs out of sync** - Commit blocked, README.md regenerated, you stage and recommit

## Enforcement

- **Global git hook** at `~/.config/git/hooks/pre-commit`
- **Blocks commits** if README.md doesn't match TSDoc
- **Auto-regenerates** README.md from TSDoc on block
- **Like LAW7** - No escape hatch, must stay in sync
