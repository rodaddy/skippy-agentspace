---
phase: 01-spec-compliance
plan: 01
subsystem: infra
tags: [portability, agent-skills-spec, shell-scripts, markdown]

# Dependency graph
requires:
  - phase: none
    provides: n/a (first plan)
provides:
  - Portable skill files with no hardcoded absolute paths
  - Spec-compliant SKILL.md frontmatter (name, description, metadata)
  - scripts/ directory convention (renamed from bin/)
  - Progressive disclosure structure (80-line SKILL.md + 5 reference docs)
affects: [plugin-packaging, command-validation, documentation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Relative @../ paths for command file context references"
    - "${CLAUDE_SKILL_DIR} for runtime script/reference paths in body text"
    - "SKIPPY_QUARANTINE_DIR env var for configurable quarantine location"
    - "SKIPPY_CACHE_DIR env var for configurable upstream cache"

key-files:
  created: []
  modified:
    - skills/skippy-dev/SKILL.md
    - skills/skippy-dev/commands/reconcile.md
    - skills/skippy-dev/commands/update.md
    - skills/skippy-dev/commands/cleanup.md
    - skills/skippy-dev/scripts/skippy-update.sh
    - skills/skippy-dev/scripts/skippy-cleanup.sh
    - CLAUDE.md
    - INDEX.md

key-decisions:
  - "Relative @../ paths for command file context refs (not ${CLAUDE_SKILL_DIR}) due to bug #11011"
  - "${CLAUDE_SKILL_DIR} used for runtime paths in SKILL.md body (bug does not apply to non-@ references)"
  - "Shell scripts use env vars (SKIPPY_QUARANTINE_DIR, SKIPPY_CACHE_DIR) with sensible defaults for portability"
  - "No docs/ directory created -- references/ alone satisfies STRU-01 progressive disclosure"

patterns-established:
  - "Relative paths for @ context references in command files"
  - "Environment variable overrides with fallback defaults in shell scripts"
  - "Description under 130 chars in SKILL.md frontmatter"

requirements-completed: [SPEC-01, SPEC-02, SPEC-03, STRU-01]

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 1 Plan 1: Spec Compliance Summary

**Portable skill paths with relative @../ refs, ${CLAUDE_SKILL_DIR} runtime paths, and bin/ to scripts/ rename**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-07T05:35:28Z
- **Completed:** 2026-03-07T05:38:49Z
- **Tasks:** 3 (2 implementation + 1 verification)
- **Files modified:** 8

## Accomplishments
- Eliminated all hardcoded absolute paths from skill files (6 files across commands, SKILL.md, and shell scripts)
- Aligned SKILL.md frontmatter to Agent Skills spec: removed triggers, added metadata block, trimmed description
- Renamed bin/ to scripts/ and updated all references across the project
- Made shell scripts portable with env var overrides (SKIPPY_QUARANTINE_DIR, SKIPPY_CACHE_DIR)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix hardcoded paths and align frontmatter** - `ac4e576` (feat)
2. **Task 2: Rename bin/ to scripts/ and update all references** - `14c4a96` (feat)
3. **Task 3: Verify progressive disclosure and run full validation** - no commit (verification only, no file changes)

## Files Created/Modified
- `skills/skippy-dev/SKILL.md` - Replaced frontmatter (removed triggers, added metadata), fixed 5 body paths
- `skills/skippy-dev/commands/reconcile.md` - Fixed 3 absolute @-reference paths to relative
- `skills/skippy-dev/commands/update.md` - Fixed @-reference path and script execution path
- `skills/skippy-dev/commands/cleanup.md` - Fixed @-reference path, quarantine path, script path, objective text
- `skills/skippy-dev/scripts/skippy-update.sh` - Renamed from bin/, portable VERSIONS_FILE and UPSTREAM_DIR paths
- `skills/skippy-dev/scripts/skippy-cleanup.sh` - Renamed from bin/, configurable QUARANTINE_DIR via env var
- `CLAUDE.md` - Updated file tree (bin/ to scripts/), removed resolved known issues section
- `INDEX.md` - Updated skill description to match trimmed SKILL.md

## Decisions Made
- Used relative `@../` paths for command file context references (per locked decision, bug #11011 affects ${CLAUDE_SKILL_DIR} in @ refs)
- Used `${CLAUDE_SKILL_DIR}` for runtime paths in SKILL.md body text (non-@ refs, bug does not apply)
- Made shell scripts portable via env var overrides with sensible defaults: SKIPPY_QUARANTINE_DIR defaults to $TMPDIR/skippy-cleanup, SKIPPY_CACHE_DIR defaults to ~/.cache/skippy-upstream
- Did not create docs/ directory -- references/ alone satisfies STRU-01's progressive disclosure requirement

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed hardcoded paths in shell scripts**
- **Found during:** Task 1 (Fix hardcoded paths)
- **Issue:** Plan listed path fixes for .md files but skippy-cleanup.sh and skippy-update.sh also contained hardcoded absolute paths (/Volumes/ThunderBolt/_tmp/, ~/.config/pai/Skills/skippy-dev/.versions)
- **Fix:** Replaced with env var overrides (SKIPPY_QUARANTINE_DIR, SKIPPY_CACHE_DIR) with portable defaults. Added SKILL_DIR resolution for .versions file path.
- **Files modified:** skills/skippy-dev/bin/skippy-cleanup.sh, skills/skippy-dev/bin/skippy-update.sh
- **Verification:** grep -rn confirms zero hardcoded paths in skills/
- **Committed in:** ac4e576 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Essential for correctness -- plan's own must_have states "No hardcoded absolute paths exist in any skill file under skills/". Shell scripts are skill files. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All skill files are portable and spec-compliant
- Ready for Phase 2 (Plugin Packaging) -- clean files to package
- Blocker from research still relevant: ${CLAUDE_SKILL_DIR} expansion bug (#11011) needs testing in Phase 2 for plugin script execution

## Self-Check: PASSED

All 8 modified files verified present. Both task commits (ac4e576, 14c4a96) verified in git history. SUMMARY.md exists at expected path.

---
*Phase: 01-spec-compliance*
*Completed: 2026-03-07*
