---
phase: 05-foundation
plan: 02
subsystem: infra
tags: [upstream-registry, json, migration, extensibility]

# Dependency graph
requires:
  - phase: 01-spec-compliance
    provides: "skills/skippy-dev/.versions file being replaced"
provides:
  - "upstreams/gsd/upstream.json -- GSD upstream tracking metadata"
  - "upstreams/paul/upstream.json -- PAUL upstream tracking metadata"
  - "Directory-per-upstream extensible registry pattern"
affects: [08-upstream-checker]

# Tech tracking
tech-stack:
  added: []
  patterns: [directory-per-upstream registry, JSON metadata per upstream]

key-files:
  created:
    - upstreams/gsd/upstream.json
    - upstreams/paul/upstream.json
  modified: []

key-decisions:
  - "Directory-per-upstream pattern -- each upstream is a directory with upstream.json, no code changes to add new upstreams"
  - "last_checked_sha and last_check initialized to none/never matching old .versions data"

patterns-established:
  - "Upstream registry: upstreams/{name}/upstream.json with name, repo, branch, sha, cherry_picks fields"
  - "Extensibility test: create temp directory to prove pattern works without code changes"

requirements-completed: [FOUN-02, FOUN-03, FOUN-04]

# Metrics
duration: 1min
completed: 2026-03-07
---

# Phase 5 Plan 2: Upstream Registry Summary

**Directory-per-upstream JSON registry replacing .versions, with GSD and PAUL entries and validated extensibility**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-07T20:00:41Z
- **Completed:** 2026-03-07T20:02:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created extensible upstream registry at `upstreams/` with per-directory JSON metadata
- Migrated GSD and PAUL tracking from shell key=value `.versions` to structured JSON
- Validated extensibility by creating and removing a temporary test-upstream directory
- Removed old `.versions` file with zero data loss (both formats had none/never values)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create upstream registry with GSD and PAUL entries** - `09bdc96` (feat)
2. **Task 2: Remove old .versions file and validate extensibility** - `680bbde` (chore)

## Files Created/Modified
- `upstreams/gsd/upstream.json` - GSD upstream tracking (repo URL, branch, SHA, empty cherry_picks)
- `upstreams/paul/upstream.json` - PAUL upstream tracking (repo URL, branch, SHA, 5 cherry_picks listed)
- `skills/skippy-dev/.versions` - Removed (migrated to upstreams/)

## Decisions Made
- Initialized `last_checked_sha` and `last_check` to `none`/`never` to match existing `.versions` data exactly -- no information lost
- Did NOT modify `skippy-update.sh` -- Phase 8 will rewrite it to read `upstreams/*/upstream.json`

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- Upstream registry is ready for Phase 8's generic upstream checker to consume
- `skippy-update.sh` still works (reinitializes `.versions` if missing) -- no breakage during transition
- Adding new upstreams (e.g., OMC) requires only `mkdir upstreams/omc && create upstream.json`

---
*Phase: 05-foundation*
*Completed: 2026-03-07*
