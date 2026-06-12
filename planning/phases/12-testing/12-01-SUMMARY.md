---
phase: 12-testing
plan: 01
subsystem: testing
tags: [bats-core, bats-assert, bats-support, bash-testing, git-submodules]

# Dependency graph
requires:
  - phase: 11-foundation
    provides: tools/lib/common.sh shared library
provides:
  - bats-core test infrastructure via vendored git submodules
  - shared test helper with HOME sandboxing
  - 10 passing tests for tools/lib/common.sh
affects: [12-02, 12-03]

# Tech tracking
tech-stack:
  added: [bats-core, bats-support, bats-assert]
  patterns: [vendored-test-deps-via-submodules, home-sandboxing-via-BATS_TEST_TMPDIR, skippy-root-fallback-for-tests]

key-files:
  created:
    - tests/bats/ (submodule)
    - tests/test_helper/bats-support/ (submodule)
    - tests/test_helper/bats-assert/ (submodule)
    - tests/test_helper/common.bash
    - tests/common-lib.bats
  modified:
    - .gitmodules

key-decisions:
  - "Load paths in test helper use test_helper/ prefix since bats resolves relative to .bats file, not the helper"
  - "10 tests instead of planned 8 -- added SKIPPY_ROOT fallback test and color-disable test for completeness"

patterns-established:
  - "HOME sandboxing: every test overrides HOME=$BATS_TEST_TMPDIR to prevent touching real ~/.claude/"
  - "Counter reset: unset counters before sourcing common.sh so :-0 defaults initialize fresh per test"
  - "Direct call for side-effect testing: use run for output assertions, direct call for counter assertions (run creates subshell)"

requirements-completed: [TEST-01, TEST-02]

# Metrics
duration: 3min
completed: 2026-03-08
---

# Phase 12 Plan 01: Test Infrastructure Summary

**Vendored bats-core test framework with HOME-sandboxed test helper and 10 passing tests for common.sh**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-08T20:27:51Z
- **Completed:** 2026-03-08T20:30:28Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Vendored bats-core, bats-support, bats-assert as git submodules -- no brew dependency for running tests
- Shared test helper with HOME sandboxing that prevents any test from touching real ~/.claude/
- 10 passing tests covering all common.sh public functions: repo_root, pass/warn/fail, summary, is_installed, colors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add bats submodules and create test helper** - `96e68b9` (chore)
2. **Task 2: Write common-lib.bats tests** - `a9d95fa` (test)

## Files Created/Modified
- `.gitmodules` - Git submodule configuration for 3 bats dependencies
- `tests/bats/` - bats-core submodule (test runner binary at bin/bats)
- `tests/test_helper/bats-support/` - bats-support submodule (assertion helpers)
- `tests/test_helper/bats-assert/` - bats-assert submodule (assert_success, assert_output, etc.)
- `tests/test_helper/common.bash` - Shared setup: HOME sandboxing, REPO_ROOT, SKIPPY_ROOT, library loading
- `tests/common-lib.bats` - 10 tests for tools/lib/common.sh

## Decisions Made
- Load paths in test helper use `test_helper/` prefix because bats `load` resolves relative to the .bats file location, not the helper file's location
- 10 tests instead of planned 8 -- added SKIPPY_ROOT fallback test and color-disable test for fuller coverage
- Counter assertions use direct function calls (not `run`) because `run` creates a subshell that isolates counter side-effects

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bats load path resolution in test helper**
- **Found during:** Task 2 (TDD RED phase)
- **Issue:** `load 'bats-support/load'` in common.bash resolved relative to .bats file (tests/), looking for tests/bats-support/ which doesn't exist
- **Fix:** Changed to `load 'test_helper/bats-support/load'` and `load 'test_helper/bats-assert/load'`
- **Files modified:** tests/test_helper/common.bash
- **Verification:** All 10 tests pass
- **Committed in:** a9d95fa (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Load path fix was necessary for tests to run. No scope creep.

## Issues Encountered
None beyond the load path fix documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Test infrastructure ready for plans 02 and 03 to add install.bats, uninstall.bats, and other test files
- Pattern established: load test_helper/common, call _common_setup, source the script under test
- All future tests inherit HOME sandboxing automatically

## Self-Check: PASSED

All 6 files found, both commits verified, line count minimums met.

---
*Phase: 12-testing*
*Completed: 2026-03-08*
