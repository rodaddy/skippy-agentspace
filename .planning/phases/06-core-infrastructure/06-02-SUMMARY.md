---
phase: 06-core-infrastructure
plan: 02
subsystem: infra
tags: [rules, templates, communication-style, stack-preferences, claude-md, user-md]

# Dependency graph
requires:
  - phase: 06-core-infrastructure-01
    provides: personas and LAWs directory structure under skills/core/references/
provides:
  - 4 public-safe rule files (communication-style, stack-preferences, output-locations, minimal-claude-dir)
  - Opinionated CLAUDE.md project template with CUSTOMIZE placeholders
  - user.md template with privacy header and structured sections
affects: [06-core-infrastructure-03, 09-install-experience, 10-validation]

# Tech tracking
tech-stack:
  added: []
  patterns: [HTML-comment-CUSTOMIZE-placeholders, public-safe-rule-extraction]

key-files:
  created:
    - skills/core/references/rules/communication-style.md
    - skills/core/references/rules/stack-preferences.md
    - skills/core/references/rules/output-locations.md
    - skills/core/references/rules/minimal-claude-dir.md
    - skills/core/references/templates/claude-md.template
    - skills/core/references/templates/user.md.template

key-decisions:
  - "HTML comment CUSTOMIZE syntax for template placeholders -- invisible in rendered markdown, actual defaults inline"
  - "Merged Python and TypeScript stack preferences into single stack-preferences.md"
  - "user.md.template includes Memory Hints section beyond the CONTEXT.md spec"

patterns-established:
  - "Public-safe extraction: document the PATTERN not private values, use placeholder syntax for user-specific paths"
  - "HTML comment CUSTOMIZE markers: <!-- CUSTOMIZE: field_name (default: value) -->"

requirements-completed: [CORE-03, CORE-04]

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 6 Plan 2: Rules & Templates Summary

**4 public-safe rule files and 2 opinionated project templates with HTML-comment CUSTOMIZE placeholders**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T21:07:20Z
- **Completed:** 2026-03-07T21:09:41Z
- **Tasks:** 2
- **Files created:** 6

## Accomplishments
- Extracted communication style, stack preferences, output locations, and minimal-claude-dir rules as public-safe reference docs
- Created opinionated CLAUDE.md template (92 lines) with 10 CUSTOMIZE markers covering project name, persona, stack, and LAW table
- Created user.md template (53 lines) with Identity, Preferences, Communication, Context, and Memory Hints sections

## Task Commits

Each task was committed atomically:

1. **Task 1: Create public-safe rule files** - `c5dec33` (feat)
2. **Task 2: Create CLAUDE.md and user.md templates** - `6f85102` (feat)

## Files Created/Modified
- `skills/core/references/rules/communication-style.md` - Persona-aware styling conventions, anti-patterns, universal rules
- `skills/core/references/rules/stack-preferences.md` - bun/uv/brew defaults, shell and file size conventions
- `skills/core/references/rules/output-locations.md` - Centralized report routing, session artifacts, secrets rules
- `skills/core/references/rules/minimal-claude-dir.md` - Symlink-only ~/.claude/ pattern with setup instructions
- `skills/core/references/templates/claude-md.template` - Opinionated project CLAUDE.md starter with LAW table and persona cascade
- `skills/core/references/templates/user.md.template` - User context structure with privacy header

## Decisions Made
- Used HTML comment CUSTOMIZE syntax (`<!-- CUSTOMIZE: field (default: value) -->`) for template placeholders -- invisible in rendered markdown, more readable than curly-brace syntax
- Merged Python preferences and TypeScript preferences into a single stack-preferences.md rather than maintaining separate files
- Added Memory Hints section to user.md.template beyond the CONTEXT.md spec -- extends the OpenClaw USER.md concept with explicit always/never/preferences

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- Rules and templates directories complete under skills/core/references/
- Plan 03 (SKILL.md + INDEX.md integration) can now reference all 4 subdirectories: personas/, laws/, rules/, templates/
- All content is public-safe -- verified no private IPs, server names, or personal details leaked

## Self-Check: PASSED

All 6 created files verified present. Both task commits (c5dec33, 6f85102) verified in git log. SUMMARY.md exists at expected path.

---
*Phase: 06-core-infrastructure*
*Completed: 2026-03-07*
