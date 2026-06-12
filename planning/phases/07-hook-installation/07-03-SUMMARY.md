---
phase: 07-hook-installation
plan: 03
subsystem: infra
tags: [hooks, installer, uninstaller, validation, shell, typescript, settings-json]

# Dependency graph
requires:
  - phase: 07-hook-installation
    provides: Hook manifest (manifest.json), shared library (types, context, feedback), and 15 hook scripts
provides:
  - Shell installer that safely merges PAI hooks into settings.json with backup and idempotency
  - Shell uninstaller with double-check removal (path + manifest cross-reference)
  - TypeScript JSON merge/remove backend (lib/merge.ts) callable via bun
  - Validation script with quick (5 checks) and full (9 checks) modes covering all HOOK requirements
  - INSTALL.md with automated and manual (AI-agent-facing) installation instructions
  - Updated SKILL.md with Hooks section -- all 15 LAWs show hook enforcement
affects: [09-install-experience]

# Tech tracking
tech-stack:
  added: []
  patterns: [shell orchestrator + TypeScript backend for JSON operations, double-check removal strategy, heredoc test fixtures in validation scripts]

key-files:
  created:
    - skills/core/hooks/install-hooks.sh
    - skills/core/hooks/uninstall-hooks.sh
    - skills/core/hooks/lib/merge.ts
    - skills/core/hooks/INSTALL.md
    - tools/validate-hooks.sh
  modified:
    - skills/core/SKILL.md

key-decisions:
  - "Bun-only JSON backend -- bun is already a hard dependency for hook scripts, no need for python3/jq fallbacks yet"
  - "Shell orchestrator + TypeScript backend split -- bash handles flow/backup/args, bun handles JSON merge/remove"
  - "Validation script uses bun -e for JSON checks rather than jq -- consistent with project's bun-first stack"
  - "Check 4 grep pattern targets input.toolName/raw.toolName not bare toolName -- avoids false positives from local variable names"

patterns-established:
  - "Install pattern: backup -> validate prerequisites -> delegate JSON merge to bun -> report results"
  - "Double-check removal: command must contain identifier AND match manifest entry to be removed"
  - "Validation quick/full split: quick for CI (< 5s), full for pre-release (round-trip install/uninstall tests)"

requirements-completed: [HOOK-02, HOOK-03, HOOK-04, HOOK-05]

# Metrics
duration: 4min
completed: 2026-03-07
---

# Phase 7 Plan 3: Hook Installer, Uninstaller & Validation Summary

**Shell installer/uninstaller with bun-powered JSON merge backend, full validation suite covering all HOOK requirements (backup, safety, idempotency, double-check removal), and INSTALL.md for AI-agent-driven installation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-07T22:39:19Z
- **Completed:** 2026-03-07T22:43:30Z
- **Tasks:** 2
- **Files created/modified:** 6

## Accomplishments
- install-hooks.sh merges 15 PAI hooks into settings.json while preserving all GSD/OMC hooks and non-hook settings
- uninstall-hooks.sh removes only PAI hooks using double-check strategy (path identifier + manifest cross-reference)
- lib/merge.ts exports mergeHooks/removeHooks for programmatic use and serves as CLI entrypoint via bun
- Idempotent: running install twice produces identical output (0 added, 15 skipped on second run)
- tools/validate-hooks.sh passes 13/13 checks in full mode (manifest, structure, install safety, uninstall safety, idempotency, backup)
- SKILL.md updated: all 15 LAWs now show hook enforcement -- zero "Phase 7 gap" entries remain

## Task Commits

Each task was committed atomically:

1. **Task 1: Create JSON merge backend and installer/uninstaller scripts** - `f165aee` (feat)
2. **Task 2: Create validation script, INSTALL.md, and update SKILL.md** - `865c338` (feat)

## Files Created/Modified
- `skills/core/hooks/lib/merge.ts` - TypeScript JSON merge/remove backend with mergeHooks() and removeHooks() exports
- `skills/core/hooks/install-hooks.sh` - Shell installer with backup, dry-run, settings override, bun prerequisite check
- `skills/core/hooks/uninstall-hooks.sh` - Shell uninstaller with backup and double-check removal
- `tools/validate-hooks.sh` - 9-check validation (5 quick + 4 full) covering HOOK-01 through HOOK-05
- `skills/core/hooks/INSTALL.md` - Automated + manual installation instructions for humans and AI agents
- `skills/core/SKILL.md` - Added Hooks section with 15-hook table, updated LAWs enforcement column

## Decisions Made
- Bun-only JSON backend for initial release -- bun is already a hard dependency since every hook script uses `#!/usr/bin/env bun`. Python3/jq fallbacks deferred as future enhancement if portability becomes a need.
- Shell orchestrator + TypeScript backend split: bash handles argument parsing, backup creation, prerequisite validation, and reporting. Bun handles the actual JSON merge/remove operations. Clean separation of concerns.
- Validation check 4 (camelCase detection) uses targeted grep for `input.toolName`/`raw.toolName` patterns rather than bare `toolName` -- local function parameters with camelCase names are perfectly valid and should not trigger false positives.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed false-positive camelCase detection in validate-hooks.sh**
- **Found during:** Task 2 (validation script creation)
- **Issue:** Check 4 grep pattern `toolName\|toolInput` matched local variable names (function parameters) in hook scripts, not actual camelCase field access on hook input
- **Fix:** Changed grep to target `input.toolName`/`raw.toolName` patterns that indicate actual field access violations
- **Files modified:** tools/validate-hooks.sh
- **Verification:** All 13/13 checks pass in full mode
- **Committed in:** 865c338 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Trivial grep pattern refinement. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviation above.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- Phase 7 is now fully complete: manifest + shared lib + 15 hook scripts + installer + uninstaller + validation
- Complete hook system ready for integration into install experience (Phase 9)
- `bash tools/validate-hooks.sh --full` can be used as a gate check in any CI or pre-release workflow

## Self-Check: PASSED

All 6 created/modified files verified present. Both task commits (f165aee, 865c338) verified in git log.

---
*Phase: 07-hook-installation*
*Completed: 2026-03-07*
