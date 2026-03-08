# Stack Preferences

Default tool and package manager conventions. These are opinionated defaults --
override per-project in your CLAUDE.md if needed.

## Package Managers

| Language | Use | Never Use |
|----------|-----|-----------|
| Node.js / TypeScript | `bun` | npm, yarn, pnpm |
| Python | `uv` | pip, pip3, conda |
| macOS system packages | `brew` | manual downloads |

## Node.js / TypeScript

- **Runtime:** Bun preferred over Node.js
- **Install:** `bun install`, `bun add <package>`
- **Run:** `bun run <script>`
- **Style:** Functional patterns over classes, explicit types (avoid `any`), prefer `const` over `let`

## Python

- **Ad-hoc execution:** `claudePy -c "..."` -- never `python3` or `uv run python -c`
- **Virtual environments:** Always use `uv venv` for isolation
- **Install:** `uv add <package>` (not `pip install`)
- **Dependencies:** Keep `pyproject.toml` updated, use `uv sync`

## Shell Scripts

- **Shebang:** `#!/usr/bin/env bash` (or `zsh`, `sh`) -- NEVER `#!/bin/bash`
- **Why:** macOS system bash is ancient (v3.2). The `env` shebang picks up modern bash from PATH.
- See LAW 7 for enforcement details.

## File Size Limits

- Maximum 750 lines per file
- Split proactively at ~600 lines
- See LAW 9 for enforcement details.
