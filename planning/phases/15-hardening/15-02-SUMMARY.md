---
phase: 15-hardening
plan: 02
subsystem: tooling
tags: [bash, versioning, jq, sed, automation]

# Dependency graph
requires:
  - phase: 11-foundation
    provides: common.sh shared library (skippy_pass/fail/section/summary)
provides:
  - tools/bump-version.sh for atomic version bumps across all 26 repo locations
  - Portable sed helper (_sed_inplace) for GNU/BSD compatibility
affects: [release-workflow, version-management]

# Tech tracking
tech-stack:
  added: []
  patterns: [portable-sed-inplace, grep-fixed-string-verification, jq-temp-file-mv]

key-files:
  created: [tools/bump-version.sh]
  modified: []

key-decisions:
  - "Portable _sed_inplace helper detects GNU vs BSD sed at runtime -- machine has GNU sed via homebrew"
  - "grep -F (fixed string) for post-bump verification -- regex grep false-positives on version-like substrings"
  - "grep pipeline wrapped with || true to prevent pipefail crash on zero-match success case"

patterns-established:
  - "_sed_inplace helper: detect GNU vs BSD sed for portable in-place editing"
  - "Subshell grep with || true for pipefail-safe counting of matches"

requirements-completed: [HARD-02]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 15 Plan 02: Version Bump Automation Summary

**Atomic version bump script (bump-version.sh) reading canonical version from marketplace.json and updating all 26 locations via jq + portable sed**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T21:15:55Z
- **Completed:** 2026-03-08T21:19:55Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created tools/bump-version.sh with --patch/--minor/--major and --dry-run support
- Reads canonical version from marketplace.json metadata.version via jq
- Updates all 26 version locations: marketplace.json (13 fields via jq), 12 SKILL.md files (sed), migrate.md (sed)
- Post-bump verification confirms zero old-version references remain using skippy_pass/fail/summary

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bump-version.sh with dry-run and verification** - `1c3a1e0` (feat)

## Files Created/Modified
- `tools/bump-version.sh` - Atomic version bump automation (188 lines, executable)

## Decisions Made
- **Portable sed:** Added `_sed_inplace` helper that detects GNU vs BSD sed at runtime. This machine has GNU sed via homebrew (`/opt/homebrew/bin/sed`), so `sed -i ''` fails (GNU treats `''` as the script argument). The helper checks `sed --version` for "GNU sed" and uses `sed -i` (GNU) or `sed -i ''` (BSD) accordingly.
- **Fixed-string grep:** Used `grep -F` instead of regex grep for post-bump verification. Regex grep with version string `0.1.0` false-matched `300-1000` in migrate.md because `.` matches any character.
- **Pipefail-safe grep:** Wrapped verification grep in subshell with `|| true` to prevent `set -euo pipefail` from crashing when grep returns exit code 1 (no matches -- the success case).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] GNU sed compatibility with _sed_inplace helper**
- **Found during:** Task 1 (verification of real bump)
- **Issue:** `sed -i '' "s/..."` crashes on GNU sed (homebrew) because GNU treats `''` as the script, not the backup suffix
- **Fix:** Added `_sed_inplace()` helper that detects GNU vs BSD sed and calls the correct syntax
- **Files modified:** tools/bump-version.sh
- **Verification:** Real --patch bump succeeds with all 26 locations updated
- **Committed in:** 1c3a1e0

**2. [Rule 1 - Bug] grep regex false positive on version string**
- **Found during:** Task 1 (post-bump verification)
- **Issue:** `grep "0.1.0"` matched `300-1000` in migrate.md because `.` is a regex wildcard
- **Fix:** Changed to `grep -F` (fixed string matching)
- **Files modified:** tools/bump-version.sh
- **Verification:** Post-bump verification shows 0 false positives
- **Committed in:** 1c3a1e0

**3. [Rule 1 - Bug] pipefail crash on successful bump verification**
- **Found during:** Task 1 (post-bump verification)
- **Issue:** `grep ... | wc -l` with `set -euo pipefail` crashes when grep returns 0 matches (exit 1) -- which is the success case
- **Fix:** Wrapped grep in subshell with `|| true` before piping to `wc -l`
- **Files modified:** tools/bump-version.sh
- **Verification:** Script exits 0 on successful bump with zero remaining references
- **Committed in:** 1c3a1e0

---

**Total deviations:** 3 auto-fixed (3 bugs -- Rule 1)
**Impact on plan:** All fixes necessary for correctness. No scope creep. Script works on both GNU and BSD sed systems.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 15 complete (both plans done)
- Version bumps are now a single command: `bash tools/bump-version.sh --patch|--minor|--major [--dry-run]`
- Ready for v1.2 milestone completion

---
*Phase: 15-hardening*
*Completed: 2026-03-08*
