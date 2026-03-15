# Phase 1 Context: Spec Compliance

## What This Phase Fixes

The skippy skill works but is not portable -- hardcoded paths, non-standard frontmatter, and wrong directory names prevent it from working on any machine other than Rico's or via plugin install.

## Concrete Problems to Fix

### 1. Hardcoded Absolute Paths (SPEC-01)

5 hardcoded paths found in command files. Must be replaced with `${CLAUDE_SKILL_DIR}` or relative paths:

```
skills/skippy/commands/reconcile.md:12  @/Users/rico/.config/pai/Skills/skippy/SKILL.md
skills/skippy/commands/reconcile.md:13  @/Users/rico/.config/pai/Skills/skippy/references/reconciliation.md
skills/skippy/commands/reconcile.md:14  @/Users/rico/.config/pai/Skills/skippy/references/state-consistency.md
skills/skippy/commands/update.md:12     @/Users/rico/.config/pai/Skills/skippy/SKILL.md
skills/skippy/commands/cleanup.md:12    @/Users/rico/.config/pai/Skills/skippy/SKILL.md
```

**Replace with:** Relative paths from the command file to the skill directory, e.g. `@../SKILL.md`, `@../references/reconciliation.md`. Or use `${CLAUDE_SKILL_DIR}` if Claude Code expands it in command files (needs verification -- known bug #11011).

### 2. Non-Standard Frontmatter (SPEC-02)

Current SKILL.md frontmatter:
```yaml
---
name: skippy
description: Development workflow enhancements...
triggers:
  - /skippy:reconcile
  - /skippy:update
  - /skippy:cleanup
  - reconcile plan
  - check upstream
  - cleanup ephemeral
---
```

**Problems:**
- `triggers:` is NOT in the Agent Skills spec. Claude Code uses `name` + `description` for discovery. Remove `triggers:`.
- Missing `metadata:` block (optional but recommended for version tracking)

**Target frontmatter:**
```yaml
---
name: skippy
description: Development workflow enhancements -- context awareness, reconciliation, task rigor, plan boundaries, and state consistency. Augments GSD with best-of-breed ideas from the PAUL framework.
metadata:
  version: "0.1.0"
  author: "rodaddy"
  source: "https://github.com/rodaddy/skippy-agentspace"
---
```

**Note:** Keep description under 130 chars to stay within Claude Code's ~16k char skill budget. Current is 154 chars -- needs trimming.

### 3. Rename bin/ to scripts/ (SPEC-03)

Agent Skills spec convention uses `scripts/` not `bin/`. Rename:
```
skills/skippy/bin/skippy-update.sh  →  skills/skippy/scripts/skippy-update.sh
skills/skippy/bin/skippy-cleanup.sh →  skills/skippy/scripts/skippy-cleanup.sh
```

Update all references to `bin/` in:
- `skills/skippy/SKILL.md` (commands section references bin/)
- `CLAUDE.md` (file tree shows bin/)
- `INDEX.md` (if it references bin/)

### 4. Progressive Disclosure Structure (STRU-01)

Already mostly correct. Verify:
- SKILL.md under 150 lines (currently ~84 lines ✓)
- Detail in `references/` (5 files ✓)
- Navigation index present (INDEX.md ✓, but check if it lists references)

May need a `docs/` directory for project-level documentation (origin, decisions) separate from skill references.

## Files to Read Before Planning

| File | Why |
|------|-----|
| `skills/skippy/SKILL.md` | The main file to modify |
| `skills/skippy/commands/reconcile.md` | Has 3 hardcoded paths |
| `skills/skippy/commands/update.md` | Has 1 hardcoded path |
| `skills/skippy/commands/cleanup.md` | Has 1 hardcoded path |
| `.planning/research/STACK.md` | Agent Skills spec details |
| `.planning/research/ARCHITECTURE.md` | Claude Code discovery mechanisms |
| `.planning/research/PITFALLS.md` | Known bugs and naming collision risks |

## Design Decisions Already Made

- **Relative paths preferred over `${CLAUDE_SKILL_DIR}`** -- `${CLAUDE_SKILL_DIR}` has a known bug (#11011) with plugin scripts on first execution. Relative paths work everywhere.
- **Keep `commands/` subdirectory for now** -- research noted it's "legacy" but we have 3 commands with separate workflows. Merging into SKILL.md with `$ARGUMENTS` dispatch is a Phase 2 consideration, not Phase 1.
- **Shell scripts stay as shell** -- no TypeScript/Node build step. Just rename the directory.

## Success Criteria (from ROADMAP.md)

1. No absolute paths exist in any skill file
2. SKILL.md frontmatter passes Agent Skills spec validation
3. `scripts/` directory exists where `bin/` was, all references updated
4. Progressive disclosure pattern -- slim SKILL.md, detail in references/docs/, index present
