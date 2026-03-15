---
phase: 12-testing
plan: 02
subsystem: testing
tags: [bats, bash, install, uninstall, symlink-safety, input-validation]

# Dependency graph
requires:
  - phase: 12-testing plan 01
    provides: bats-core infrastructure, test_helper/common.bash, test patterns
provides:
  - install.sh test coverage (8 tests, all modes)
  - uninstall.sh test coverage (6 tests, including critical safety fix)
affects: [12-testing plan 03, tools/install.sh, tools/uninstall.sh]

# Tech tracking
tech-stack:
  added: []
  patterns: [subprocess testing via 'run bash "$SCRIPT"', sandboxed HOME for symlink tests, piped stdin for interactive prompts]

key-files:
  created:
    - tests/install.bats
    - tests/uninstall.bats
  modified: []

key-decisions:
  - "Used skippy instead of core for --target=commands test -- core has no commands/ subdirectory"

patterns-established:
  - "Pipe stdin for interactive prompts: echo 'n' | bash script.sh for uninstall --all hook prompt"
  - "Pre-install in setup() for uninstall tests -- each test starts with core already installed"

requirements-completed: [TEST-01, TEST-02]

# Metrics
duration: 2min
completed: 2026-03-08
---

# Phase 12 Plan 02: Install/Uninstall Test Coverage Summary

**14 bats tests covering install.sh (8 modes) and uninstall.sh (6 modes) with critical 71-skill-nuke safety verification**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T20:33:44Z
- **Completed:** 2026-03-08T20:35:39Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- 8 install.sh tests covering no-args status, --core, --all, positional, idempotent, error cases, and legacy --target=commands
- 6 uninstall.sh tests covering usage display, single removal, --all cleanup, and path traversal rejection
- Critical safety test validates non-skippy symlinks survive `--all` uninstall (the 71-skill nuke fix from PR #1)
- Both test files exceed minimum line counts (80 and 92 vs 60 and 50 required)

## Task Commits

Each task was committed atomically:

1. **Task 1: Write install.bats tests** - `fc714ec` (test)
2. **Task 2: Write uninstall.bats tests** - `2b88c09` (test)

## Files Created/Modified
- `tests/install.bats` (80 lines) - 8 tests for install.sh: status table, --core, --all, positional, idempotent, nonexistent, path traversal, legacy target
- `tests/uninstall.bats` (92 lines) - 6 tests for uninstall.sh: usage, single removal, --all cleanup, non-skippy preservation, not-installed, path traversal

## Decisions Made
- Used skippy for --target=commands test because core skill has no commands/ subdirectory (only hooks/ and references/)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed legacy target test using wrong skill**
- **Found during:** Task 1 (install.bats)
- **Issue:** Plan specified `--core --target=commands` but core skill has no commands/ directory -- install_skill_legacy() returns success with "SKIP" but creates no symlink
- **Fix:** Changed test to use `skippy --target=commands` since skippy is the only skill with a commands/ subdirectory
- **Files modified:** tests/install.bats
- **Verification:** All 8 tests pass
- **Committed in:** fc714ec (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary fix -- the planned test would have tested nothing useful. No scope creep.

## Issues Encountered
None beyond the deviation documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Install/uninstall test coverage complete
- Ready for 12-03 (index-sync.sh and end-to-end tests)
- Total test count now: 10 (common-lib) + 14 (install/uninstall) = 24 tests

## Self-Check: PASSED

- [x] tests/install.bats exists (80 lines, 8 tests)
- [x] tests/uninstall.bats exists (92 lines, 6 tests)
- [x] 12-02-SUMMARY.md exists
- [x] Commit fc714ec found (install.bats)
- [x] Commit 2b88c09 found (uninstall.bats)
- [x] All 14 tests pass when run together

---
*Phase: 12-testing*
*Completed: 2026-03-08*
