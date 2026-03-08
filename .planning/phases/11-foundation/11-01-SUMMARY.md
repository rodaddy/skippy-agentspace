---
phase: 11-foundation
plan: 01
subsystem: infra
tags: [bash, shell-library, gitattributes, shared-functions]

# Dependency graph
requires:
  - phase: 10-bootstrap
    provides: "6 tools/ scripts with duplicated patterns"
provides:
  - "tools/lib/common.sh with 8 skippy_-namespaced functions"
  - ".gitattributes with export-ignore for 6 dev-only directories"
affects: [11-02, 12-testing, 15-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns: [skippy_-namespaced shared library, source-with-fallback, ANSI color with terminal detection]

key-files:
  created:
    - tools/lib/common.sh
    - .gitattributes
  modified: []

key-decisions:
  - "ANSI colors with automatic terminal detection (_SKIPPY_ prefixed private vars)"
  - "echo -e for color output -- consistent with existing script patterns"

patterns-established:
  - "skippy_ namespace: all shared functions and counter variables use skippy_ prefix"
  - "Source-only library: direct execution guard via BASH_SOURCE[0] == $0 check"
  - "export-ignore: both directory name and /** glob for each excluded path"

requirements-completed: [FOUND-01, FOUND-02]

# Metrics
duration: 2min
completed: 2026-03-08
---

# Phase 11 Plan 01: Shared Shell Library and Distribution Attributes Summary

**tools/lib/common.sh with 8 skippy_-namespaced functions (repo root, 4 output helpers, section, summary, install detection) plus .gitattributes excluding 6 dev-only paths from git archive**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T17:20:24Z
- **Completed:** 2026-03-08T17:21:54Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- Created shared shell library with 8 functions covering 5 function groups (repo root, output helpers, section headers, summary with exit code, install detection)
- ANSI color output with automatic terminal detection (disables colors when stdout is not a TTY)
- .gitattributes with 14 export-ignore rules covering all 6 dev-only directories plus git metadata files

## Task Commits

Each task was committed atomically:

1. **Task 1: Create tools/lib/common.sh shared library** - `7dc4f77` (feat)
2. **Task 2: Create .gitattributes with export-ignore rules** - `f8e07dc` (feat)

## Files Created/Modified
- `tools/lib/common.sh` - Shared shell library with skippy_repo_root, skippy_pass/warn/fail/suggest, skippy_section, skippy_summary, skippy_is_installed
- `.gitattributes` - Distribution exclusion rules for git archive (14 export-ignore entries)

## Decisions Made
- Added ANSI color codes with automatic terminal detection (colors disabled when stdout is not a TTY) -- improves readability in terminal, clean output in logs
- Used `echo -e` for color output rather than `printf` -- consistent with existing script patterns in the codebase
- Private color variables use `_SKIPPY_` prefix (underscore convention for internal-use vars)

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- common.sh is ready for Plan 11-02 to migrate all 6 tools/ scripts to source it
- .gitattributes is complete and requires no further work
- Phase 12 (Testing) can write bats tests against common.sh functions

---
*Phase: 11-foundation*
*Completed: 2026-03-08*
