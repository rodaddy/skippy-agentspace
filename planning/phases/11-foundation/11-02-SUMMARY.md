---
phase: 11-foundation
plan: 02
subsystem: tooling
tags: [bash, dry-extraction, shared-library, common.sh]

requires:
  - phase: 11-foundation-01
    provides: tools/lib/common.sh shared library with skippy_ functions
provides:
  - All 6 tools/ scripts migrated to source common.sh
  - Consistent skippy_-namespaced function usage across all scripts
  - Graceful fallback stubs for standalone operation
affects: [testing, deploy-service]

tech-stack:
  added: []
  patterns: [source-with-fallback, skippy_-namespaced shared functions]

key-files:
  created: []
  modified:
    - tools/verify.sh
    - tools/validate-hooks.sh
    - tools/prereqs.sh
    - tools/index-sync.sh
    - tools/install.sh
    - tools/uninstall.sh

key-decisions:
  - "prereqs.sh keeps own exit-code logic for interactive install-prompt flow -- skippy_summary not used"
  - "Light scripts get minimal fallback (only skippy_repo_root + skippy_is_installed) vs full fallback for heavy scripts"
  - "Fallback stubs use $0 path derivation since BASH_SOURCE context differs in inline fallback"

patterns-established:
  - "Source-with-fallback block: always near top after set -euo pipefail"
  - "Full fallback for pass/fail/counter scripts, minimal fallback for utility scripts"

requirements-completed: [FOUND-01]

duration: 4min
completed: 2026-03-08
---

# Phase 11 Plan 02: DRY Migration Summary

**Migrated all 6 tools/ scripts to source common.sh, replacing duplicated pass/fail/counter/repo-root patterns with skippy_-namespaced shared functions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T17:24:33Z
- **Completed:** 2026-03-08T17:29:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- All 6 tools/ scripts now source common.sh with graceful fallback
- Zero bare pass()/fail()/warn()/is_installed() function definitions remain
- Zero bare PASS_COUNT/FAIL_COUNT/WARN_COUNT/ok_count/missing_count counter variables remain
- All scripts produce identical functional output and exit codes as before migration
- Fallback mode verified -- scripts work correctly even when common.sh is missing
- Zero references to common.sh in skills/ directory (portability constraint maintained)

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate verify.sh, validate-hooks.sh, prereqs.sh** - `9e35b76` (feat)
2. **Task 2: Migrate index-sync.sh, install.sh, uninstall.sh** - `0d36a3c` (feat)

## Files Created/Modified

- `tools/verify.sh` - Health check script: full migration of all 5 function groups + section headers + summary
- `tools/validate-hooks.sh` - Hook validation: pass/fail counters replaced, summary block replaced
- `tools/prereqs.sh` - Prerequisite checker: report_ok/missing/outdated replaced with skippy_pass/fail/warn, keeps own exit logic
- `tools/index-sync.sh` - Index sync: REPO_ROOT + is_installed replaced with skippy_ equivalents
- `tools/install.sh` - Installer: REPO_ROOT replaced with skippy_repo_root
- `tools/uninstall.sh` - Uninstaller: REPO_ROOT + REPO_SKILLS_DIR derivation replaced with skippy_repo_root

## Decisions Made

- **prereqs.sh keeps own exit-code logic:** The interactive install-prompt flow means initial scan results can change after prompts. Using skippy_summary would lose this nuance. skippy_ helpers used for display only.
- **Minimal vs full fallback stubs:** Heavy scripts (verify, validate-hooks, prereqs) get full fallback with all functions. Light scripts (index-sync, install, uninstall) get only the stubs they actually need.
- **Fallback uses $0 for path derivation:** Inside inline fallback stubs, BASH_SOURCE points to common.sh (which doesn't exist), so $0 is used instead for repo root derivation.

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- Phase 11 (Foundation) is now complete -- both plans executed
- common.sh shared library created (Plan 01) and all scripts migrated to use it (Plan 02)
- Ready for Phase 12 and beyond

## Self-Check: PASSED

- All 7 files verified present on disk
- Both task commits verified in git log (9e35b76, 0d36a3c)
- Summary file verified present

---
*Phase: 11-foundation*
*Completed: 2026-03-08*
