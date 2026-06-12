---
phase: 06-core-infrastructure
plan: 01
subsystem: infra
tags: [personas, laws, markdown, portable-skills, soul-md]

# Dependency graph
requires:
  - phase: 05-foundation
    provides: public/private split and upstream registry patterns
provides:
  - 4 self-contained persona files (Skippy, Bob, Clarisa, April) as injectable prompt fragments
  - 15 individual LAW files with enforcement metadata
  - skills/core/references/ directory structure for personas and laws
affects: [06-02, 06-03, 07-hook-installation, 09-install-experience]

# Tech tracking
tech-stack:
  added: []
  patterns: [soul-md-inspired persona structure, individual LAW files with enforcement metadata]

key-files:
  created:
    - skills/core/references/personas/skippy.md
    - skills/core/references/personas/bob.md
    - skills/core/references/personas/clarisa.md
    - skills/core/references/personas/april.md
    - skills/core/references/laws/law-01-never-assume.md
    - skills/core/references/laws/law-02-checkbox-questions.md
    - skills/core/references/laws/law-03-procon-analysis.md
    - skills/core/references/laws/law-04-critical-thinking.md
    - skills/core/references/laws/law-05-explain-before-doing.md
    - skills/core/references/laws/law-06-interview-first.md
    - skills/core/references/laws/law-07-never-ancient-bash.md
    - skills/core/references/laws/law-08-never-work-on-main.md
    - skills/core/references/laws/law-09-file-size-limits.md
    - skills/core/references/laws/law-10-qmd-first.md
    - skills/core/references/laws/law-11-no-secrets-in-git.md
    - skills/core/references/laws/law-12-private-repos-default.md
    - skills/core/references/laws/law-13-no-silent-autopilot.md
    - skills/core/references/laws/law-14-network-share-protocol.md
    - skills/core/references/laws/law-15-no-litellm-self-surgery.md
  modified: []

key-decisions:
  - "Preserved original character voice in each persona file rather than sanitizing to uniform style"
  - "LAW enforcement metadata is honest about current state -- 5 LAWs marked Manual with Phase 7 gap note"
  - "Removed private content (IP addresses, server names) from LAW 14 and 15 for public safety"
  - "Added Critical Thinking Style section to each persona showing how they implement LAW 4"

patterns-established:
  - "Self-contained injectable persona: single file per persona with personality, calibration, vocal patterns, communication, interaction protocol, critical thinking, core directive"
  - "LAW individual file: name, enforcement metadata, severity, rule, rationale, enforcement details, examples, exceptions"

requirements-completed: [CORE-01, CORE-02]

# Metrics
duration: 5min
completed: 2026-03-07
---

# Phase 6 Plan 1: Personas & LAWs Summary

**4 personas (564 lines) and 15 LAWs (542 lines) extracted as portable, self-contained reference files under skills/core/references/**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-07T20:58:53Z
- **Completed:** 2026-03-07T21:04:39Z
- **Tasks:** 2
- **Files created:** 19

## Accomplishments
- Extracted 4 persona files preserving original character voice (Skippy's sarcasm, Bob's structure, Clarisa's warmth, April's creativity)
- Split 15 LAWs from monolithic laws.md into individual files with consistent structure
- Honest enforcement metadata: 10 hook-enforced, 5 marked "Manual -- hook required (Phase 7 gap)"
- All files are self-contained injectable units with no cross-references

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract and restructure 4 persona files** - `e40a50b` (feat)
2. **Task 2: Split LAWs into 15 individual files with enforcement metadata** - `e3f1063` (feat)

## Files Created/Modified
- `skills/core/references/personas/skippy.md` - Sarcastic, brilliant default persona (111 lines)
- `skills/core/references/personas/bob.md` - Methodical, data-driven analyst (143 lines)
- `skills/core/references/personas/clarisa.md` - Warm, supportive empath (141 lines)
- `skills/core/references/personas/april.md` - Creative, visual thinker (169 lines)
- `skills/core/references/laws/law-01-never-assume.md` through `law-15-no-litellm-self-surgery.md` - 15 individual LAW files (31-42 lines each)

## Decisions Made
- Preserved original voice in persona files -- Skippy's file sounds like Skippy wrote it, Bob's is structured and analytical, etc.
- LAW enforcement metadata is honest: 5 LAWs (6, 10, 12, 13, 14) honestly marked as "Manual -- hook required (Phase 7 gap)" rather than pretending all are hook-enforced
- Removed private content (IP addresses, specific server names) from LAW 14 (Network Share Protocol) and LAW 15 (LiteLLM Self-Surgery) -- genericized for public safety
- Added Critical Thinking Style section to each persona, documenting how each implements LAW 4 per the research guidance

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- Persona and LAW reference directories established, ready for Plan 2 (rules, templates, SKILL.md)
- Plan 3 (integration) can register core/ in INDEX.md and marketplace.json
- Phase 7 (Hook Installation) has clear gap list: LAWs 6, 10, 12, 13, 14 need hooks

## Self-Check: PASSED

All 19 created files verified present. Both task commits (e40a50b, e3f1063) verified in git log.

---
*Phase: 06-core-infrastructure*
*Completed: 2026-03-07*
