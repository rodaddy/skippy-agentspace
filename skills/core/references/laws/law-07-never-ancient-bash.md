# LAW 7: Never Ancient Bash

**Enforcement:** `pre-ancient-bash-blocker.ts` (PreWrite, PreEdit hooks)
**Severity:** MANDATORY

## Rule

Use `#!/usr/bin/env bash` (or `zsh`, `sh`). NEVER `#!/bin/bash`.

## Why

macOS system bash is v3.2.57 (2007). Homebrew bash is v5.3.9. The `env` shebang uses whichever is in PATH, ensuring modern bash features (associative arrays, `<()` process substitution fixes, etc.) work correctly.

## Shell Selection

| Syntax Needed | Shebang |
|---------------|---------|
| Zsh-specific | `#!/usr/bin/env zsh` |
| POSIX portable | `#!/usr/bin/env sh` |
| General scripts | `#!/usr/bin/env bash` |
| Sourced files | No shebang (inherit parent) |

## Enforcement Details

- Pre-Write hook blocks any file containing `#!/bin/bash`
- Post-write auto-fix hook corrects to `#!/usr/bin/env bash`
- Applies to all `.sh` files and any file with a shebang line

## Examples

**Correct:** `#!/usr/bin/env bash`
**Incorrect:** `#!/bin/bash`

## Exceptions

- None. There is never a valid reason to hardcode `#!/bin/bash` in this environment.
