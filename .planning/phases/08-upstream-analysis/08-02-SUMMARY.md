---
phase: 08-upstream-analysis
plan: 02
subsystem: upstream-tracking
tags: [upstream, omc, paul, gsd, best-of-breed, reference-docs, cherry-pick, synthesis]

# Dependency graph
requires:
  - phase: 08-upstream-analysis
    provides: cross-package analysis with cherry-pick recommendations (docs/cross-package-analysis.md)
  - phase: 05-foundation
    provides: directory-per-upstream pattern and reference doc conventions
provides:
  - skills/skippy-dev/references/model-routing.md (complexity-based model tier selection)
  - skills/skippy-dev/references/verification-loops.md (cycling verification with bounded iterations)
  - skills/skippy-dev/references/session-persistence.md (tiered state persistence)
  - skills/skippy-dev/references/structured-deliberation.md (multi-perspective plan review with PDOC)
  - skills/skippy-dev/references/skill-extraction.md (knowledge capture with quality gates)
affects: [08-03-generic-updater, skippy-dev-SKILL-md-update]

# Tech tracking
tech-stack:
  added: []
  patterns: [best-of-breed-synthesis-format, source-upstreams-table, pdoc-deliberation-framework, graduation-path-pattern]

key-files:
  created:
    - skills/skippy-dev/references/model-routing.md
    - skills/skippy-dev/references/verification-loops.md
    - skills/skippy-dev/references/session-persistence.md
    - skills/skippy-dev/references/structured-deliberation.md
    - skills/skippy-dev/references/skill-extraction.md
  modified: []

key-decisions:
  - "Created all 5 reference docs (3 HIGH + 2 MEDIUM) -- both MEDIUM patterns confirmed substantial by cross-package analysis"
  - "Structured-research (MEDIUM) skipped -- plan scope only named deliberation and extraction, analysis calls it a reach-for-when-needed pattern"
  - "OMC-specific tools referenced only in Source Upstreams comparison tables (describing weakness), never in actionable Pattern sections"
  - "PDOC framework (Principles, Drivers, Options, Commitment) coined as portable name for ralplan-DR deliberation structure"
  - "Graduation path concept added to skill-extraction: correction -> pattern -> skill with explicit promotion triggers"

patterns-established:
  - "Evolved reference doc format: Source Upstreams table + Why This Version + The Pattern + Integration Points + When to Apply + Sources footer"
  - "Source attribution in reference docs: each doc credits which upstream contributed which concept"
  - "Decision table pattern: When to Apply section uses task-scope routing tables consistently across all docs"

requirements-completed: [UPST-03]

# Metrics
duration: 9min
completed: 2026-03-08
---

# Phase 8 Plan 02: Best-of-Breed Reference Docs Summary

**5 best-of-breed reference docs synthesizing strongest patterns from OMC, PAUL, and GSD -- model routing, verification loops, session persistence, structured deliberation, and skill extraction**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-08T00:54:08Z
- **Completed:** 2026-03-08T01:03:23Z
- **Tasks:** 2
- **Files created:** 5

## Accomplishments
- Created 3 HIGH priority reference docs: model-routing (OMC+GSD), verification-loops (OMC+PAUL+GSD), session-persistence (OMC+GSD)
- Created 2 MEDIUM priority reference docs: structured-deliberation (OMC ralplan+deep-interview+GSD), skill-extraction (OMC learner+PAI corrections)
- Established evolved reference doc format with Source Upstreams table, Why This Version rationale, and Sources footer
- Total reference docs in skills/skippy-dev/references/ grew from 6 to 11
- All docs are self-contained and actionable without loading upstream source code

## Task Commits

Each task was committed atomically:

1. **Task 1: Create HIGH priority best-of-breed reference docs** - `a06fc0e` (feat)
2. **Task 2: Create MEDIUM priority reference docs** - `c341561` (feat)

## Files Created/Modified
- `skills/skippy-dev/references/model-routing.md` - Complexity-based model tier selection heuristic (LOW/MEDIUM/HIGH)
- `skills/skippy-dev/references/verification-loops.md` - Cycling verification with bounded iterations, same-failure detection, severity-rated review
- `skills/skippy-dev/references/session-persistence.md` - Tiered persistence (Priority/Working/Reference) mapped to GSD artifacts
- `skills/skippy-dev/references/structured-deliberation.md` - PDOC framework for multi-perspective plan review with deliberate mode
- `skills/skippy-dev/references/skill-extraction.md` - Quality gates for knowledge capture with correction-to-skill graduation path

## Decisions Made
- Created all 5 reference docs (3 HIGH + 2 MEDIUM) since cross-package analysis confirmed both MEDIUM patterns as substantial
- Skipped structured-research doc -- not in plan scope, and analysis characterizes it as "reach for when needed" rather than a core workflow pattern
- Coined PDOC (Principles, Drivers, Options, Commitment) as the portable name for the deliberation framework, avoiding OMC's RALPLAN-DR branding
- Added graduation path concept to skill-extraction (correction -> pattern -> skill) bridging OMC's learner with PAI's existing /correct workflow
- Code-review severity rating folded into verification-loops rather than standalone (per cross-package analysis recommendation)
- OMC-specific tools appear only in Source Upstreams tables describing upstream weaknesses, never in actionable sections

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- 11 reference docs now in skills/skippy-dev/references/ (5 new best-of-breed + 6 existing PAUL references)
- SKILL.md for skippy-dev will need updating to reference the 5 new docs (future task)
- Plan 03 (generic updater) can proceed -- upstream.json entries and reference docs are in place

## Self-Check: PASSED

All 6 files found. Both task commits (a06fc0e, c341561) verified in git log.

---
*Phase: 08-upstream-analysis*
*Completed: 2026-03-08*
