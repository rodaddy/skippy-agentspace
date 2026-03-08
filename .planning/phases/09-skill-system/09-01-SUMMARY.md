---
phase: 09-skill-system
plan: 01
subsystem: tooling
tags: [bash, installer, cli, selective-install]

# Dependency graph
requires:
  - phase: 02-plugin-packaging
    provides: original install.sh and uninstall.sh with single-skill support
provides:
  - selective install with --core, multi-positional args, --all, and no-arg status table
  - selective uninstall with multi-positional args and --all
affects: [10-production-readiness]

# Tech tracking
tech-stack:
  added: []
  patterns: [continue-on-error batch operations, status table display]

key-files:
  created: []
  modified:
    - tools/install.sh
    - tools/uninstall.sh

key-decisions:
  - "Continue-on-error for batch operations -- report failures at end rather than aborting mid-batch"
  - "show_status() uses printf column formatting with [installed]/[available] badges"
  - "Functions moved before argument parsing in install.sh to allow --help to call list_skills"

patterns-established:
  - "SKILL_NAMES array pattern: positional args collected into array, iterated with success/failure tracking"

requirements-completed: [SKIL-01]

# Metrics
duration: 3min
completed: 2026-03-08
---

# Phase 9 Plan 1: Selective Install/Uninstall Summary

**Selective install/uninstall with --core flag, multi-positional skill args, and no-arg status table display**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-08T02:01:39Z
- **Completed:** 2026-03-08T02:05:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- install.sh now supports --core (core only), multiple positional skill names, --all (unchanged), and no-arg status table
- uninstall.sh mirrors install.sh interface with multi-positional args and --all
- Both scripts use continue-on-error with success/failure count reporting for batch operations

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend install.sh with --core, multi-positional args, and no-arg status table** - `89cc28b` (feat)
2. **Task 2: Extend uninstall.sh with multi-positional selective uninstall** - `f15070e` (feat)

## Files Created/Modified
- `tools/install.sh` - Added SKILL_NAMES array, --core flag, show_status() function, updated --help and main logic
- `tools/uninstall.sh` - Replaced case statement with argument parsing loop, SKILL_NAMES array, --help, batch error handling

## Decisions Made
- Continue-on-error for batch operations -- tracks failed count and exits 1 if any failed, but processes all requested skills
- Functions moved above argument parsing in install.sh so --help can call list_skills() without forward reference
- show_status() uses printf with fixed-width columns for clean table alignment

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Selective install/uninstall ready for use
- Foundation for skill discovery and marketplace features in later plans

## Self-Check: PASSED

- [x] tools/install.sh exists
- [x] tools/uninstall.sh exists
- [x] 09-01-SUMMARY.md exists
- [x] Commit 89cc28b found
- [x] Commit f15070e found

---
*Phase: 09-skill-system*
*Completed: 2026-03-08*
