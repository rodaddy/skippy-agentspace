---
phase: 02-plugin-packaging
plan: 02
subsystem: infra
tags: [install, symlink, dual-target, skills, commands]

# Dependency graph
requires:
  - phase: 01-spec-compliance
    provides: Portable paths, #!/usr/bin/env bash shebangs, Agent Skills frontmatter
provides:
  - Dual-target install.sh supporting both ~/.claude/skills/ and ~/.claude/commands/
  - Auto-detection of modern vs legacy Claude Code install targets
  - Plugin conflict warning for users switching install methods
affects: [03-command-validation, 04-documentation]

# Tech tracking
tech-stack:
  added: []
  patterns: [dual-target-detection, plugin-conflict-warning, re-install-handling]

key-files:
  created: []
  modified: [tools/install.sh]

key-decisions:
  - "Modern target symlinks entire skill directory; legacy target symlinks commands/ subdirectory only"
  - "Auto-detection prefers ~/.claude/skills/ when it exists, falls back to ~/.claude/commands/"
  - "Plugin conflict warning checks ~/.claude/plugins/cache/ for duplicate skill installations"

patterns-established:
  - "Dual-target detection: check directory existence for auto mode, explicit --target flag for override"
  - "Re-install pattern: detect existing symlink, unlink, recreate -- refuse to overwrite real directories"

requirements-completed: [STRU-03]

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 2 Plan 2: Dual-Target Install Summary

**Rewritten install.sh with auto-detection of ~/.claude/skills/ (modern) vs ~/.claude/commands/ (legacy) targets, --target override flag, and plugin conflict warnings**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T05:56:16Z
- **Completed:** 2026-03-07T05:57:56Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Rewrote install.sh with full dual-target support (modern skills/ and legacy commands/)
- Auto-detection logic prefers ~/.claude/skills/ when available, falls back to ~/.claude/commands/
- Added --target=skills|commands|auto override flag for explicit control
- Plugin conflict warning when skill is also installed via marketplace
- Clean re-install handling (replaces existing symlinks, refuses to overwrite real directories)

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite install.sh with dual-target support** - `6251975` (feat)

## Files Created/Modified
- `tools/install.sh` - Dual-target skill installer with auto-detection, --target flag, --all flag, plugin conflict warning, re-install handling

## Decisions Made
- Modern target symlinks the entire skill directory (SKILL.md + commands/ + references/ + scripts/) for full discovery
- Legacy target symlinks only commands/ subdirectory (slash commands only, no SKILL.md auto-loading)
- Auto mode checks for ~/.claude/skills/ directory existence as the detection heuristic
- Plugin conflict check scans ~/.claude/plugins/cache/ for matching SKILL.md files
- Script refuses to overwrite non-symlink directories (safety guard against data loss)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- install.sh ready for use with both modern and legacy Claude Code installations
- uninstall.sh (Plan 3) should be updated to match the dual-target pattern established here
- Command validation (Phase 3) can test install/uninstall workflows end-to-end

## Self-Check: PASSED

- [x] tools/install.sh exists
- [x] 02-02-SUMMARY.md exists
- [x] Commit 6251975 exists in git log

---
*Phase: 02-plugin-packaging*
*Completed: 2026-03-07*
