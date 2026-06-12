---
phase: 07-hook-installation
plan: 01
subsystem: infra
tags: [hooks, typescript, manifest, claude-code, law-enforcement]

# Dependency graph
requires:
  - phase: 06-core-infrastructure
    provides: 15 individual LAW files with enforcement metadata
provides:
  - Hook manifest declaring all 15 LAW hooks with event type, matcher, script, blocking
  - TypeScript interfaces for hook I/O matching official Claude Code snake_case schema
  - Shared context utility with persona detection and subagent awareness
  - Feedback builder with hookSpecificOutput-wrapped decision helpers
  - Input normalization shim for camelCase/snake_case compatibility
affects: [07-02, 07-03, 09-install-experience]

# Tech tracking
tech-stack:
  added: []
  patterns: [hookSpecificOutput wrapper for PreToolUse decisions, snake_case hook I/O contract, normalizeInput compat shim]

key-files:
  created:
    - skills/core/hooks/manifest.json
    - skills/core/hooks/lib/types.ts
    - skills/core/hooks/lib/context.ts
    - skills/core/hooks/lib/feedback.ts
  modified: []

key-decisions:
  - "Used snake_case field names (tool_name, tool_input) per official Claude Code docs, not legacy camelCase"
  - "hookSpecificOutput wrapper format for all PreToolUse decisions instead of older flat format"
  - "normalizeInput() compat shim handles both snake_case and camelCase inputs for portability"
  - "Separate blockTopLevel() for UserPromptSubmit/PostToolUse events vs PreToolUse wrapper format"

patterns-established:
  - "Hook manifest: single JSON file declaring all hooks with id, law, name, event, matcher, script, blocking"
  - "Shared lib pattern: types.ts (interfaces), context.ts (environment), feedback.ts (decisions) under hooks/lib/"
  - "Fail-open contract: hooks should catch errors and output allowDecision() rather than crashing"

requirements-completed: [HOOK-01]

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 7 Plan 1: Hook Manifest & Shared Library Summary

**Hook manifest declaring 15 LAW hooks plus shared TypeScript library (types, context, feedback) with snake_case I/O contract and hookSpecificOutput wrapper format**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T22:20:42Z
- **Completed:** 2026-03-07T22:23:17Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- Hook manifest with all 15 LAWs mapped to event types, matchers, and script filenames
- TypeScript type definitions matching official Claude Code snake_case schema (HookInput, PreToolUseOutput, TopLevelDecisionOutput, ViolationDetails)
- Context utility with persona detection (env var -> session file -> default), subagent detection, and camelCase/snake_case input normalization
- Feedback builder ported from existing hooks with updated hookSpecificOutput wrapper format and new blockTopLevel() for non-PreToolUse events

## Task Commits

Each task was committed atomically:

1. **Task 1: Create hook manifest and TypeScript types** - `05a72fd` (feat)
2. **Task 2: Create shared context utility and feedback builder** - `f50e661` (feat)

## Files Created/Modified
- `skills/core/hooks/manifest.json` - Single source of truth for all 15 hook registrations (event, matcher, script, blocking)
- `skills/core/hooks/lib/types.ts` - TypeScript interfaces: HookInput, PreToolUseOutput, TopLevelDecisionOutput, ViolationDetails, Message types
- `skills/core/hooks/lib/context.ts` - getContext() (persona/projectDir/skillDir), isSubagent(), normalizeInput() compat shim
- `skills/core/hooks/lib/feedback.ts` - createViolationFeedback(), allowDecision(), blockDecision(), askDecision(), blockTopLevel()

## Decisions Made
- Used snake_case field names per official Claude Code docs, with normalizeInput() shim for backward compatibility with existing camelCase hooks
- hookSpecificOutput wrapper format for all PreToolUse decisions -- the documented standard, replacing the older flat format used by existing PAI hooks
- Separate blockTopLevel() function for UserPromptSubmit events which use top-level decision format instead of hookSpecificOutput
- LAW 13 is the only hook with null matcher (UserPromptSubmit event type doesn't support matchers)

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

Minor: `bun run --bun -e` syntax requires a package.json. Used `bun -e` directly instead. No impact on verification results.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- Manifest and shared library ready for Plan 2 (10 ported hook scripts + 5 new hook scripts)
- All 15 hook scripts will import from lib/types.ts, lib/context.ts, lib/feedback.ts
- Installer (Plan 3) will read manifest.json to register hooks in settings.json

## Self-Check: PASSED

All 4 created files verified present. Both task commits (05a72fd, f50e661) verified in git log.

---
*Phase: 07-hook-installation*
*Completed: 2026-03-07*
