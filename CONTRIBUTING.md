# Contributing to skippy-agentspace

## Adding a Skill

Each skill is a self-contained directory under `skills/<name>/`:

```
skills/<name>/
  SKILL.md          # Entry point (<150 lines, detail in references/)
  commands/         # Claude Code slash commands (optional)
  references/       # Deep reference docs (optional)
  scripts/          # Shell scripts (optional)
```

**SKILL.md frontmatter** (required fields):

```yaml
name: skill-name
description: One-line summary
metadata:
  version: "1.2.0"
  author: your-name
  source: original | adapted-from-X
  category: core | workflow | utility | domain
```

**Integration checklist:**

1. Add skill entry to `.claude-plugin/marketplace.json`
2. Run `bash tools/index-sync.sh --generate` to update INDEX.md
3. Verify no cross-skill imports -- each skill must be standalone

## Running Tests

```bash
# Unit tests (bats-core, 37 cases, sandboxed HOME)
./tests/bats/bin/bats tests/

# Health check (24+ checks across 5 categories)
bash tools/verify.sh

# Full integration suite (36 tests, clones upstreams)
bash tools/integration-test.sh

# Integration -- skip upstream clones
bash tools/integration-test.sh --quick
```

All tests run in sandboxed `$HOME` -- never touches your real `~/.claude/`.

## Submitting Changes

**Branching:** Use `feat/`, `fix/`, or `wip/` prefixes. Never commit to main (hook-enforced).

**Shell scripts:**
- Shebang: `#!/usr/bin/env bash`
- Safety: `set -euo pipefail`
- Run tests before submitting

**Pull requests:** One feature or fix per PR. Include test output if applicable.

## Conventions

- `skippy_` namespace for shared functions (see `tools/lib/common.sh`)
- `validate_skill_name()` for any user-supplied skill name argument
- No cross-skill imports -- portability is a hard constraint
- Slim SKILL.md (<150 lines) with detail in `references/` subdirectory

See [CONVENTIONS.md](CONVENTIONS.md) for full coding conventions and content classification.
