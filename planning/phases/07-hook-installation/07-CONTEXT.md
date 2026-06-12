# Phase 7: Hook Installation - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Install and uninstall PAI hooks into Claude Code's settings.json without destroying existing hooks from GSD, OMC, or other systems. All 15 LAWs get hook enforcement scripts under our control. Includes manifest, installer, uninstaller, backup, and the hook scripts themselves.

</domain>

<decisions>
## Implementation Decisions

### Hook ownership identification
- PAI hooks identified by command path containing `skills/core/hooks/`
- Uninstaller uses double-check: path substring match AND manifest cross-reference
- Only hooks matching both criteria are removed -- belt and suspenders safety
- GSD hooks use `~/.claude/get-shit-done/`, OMC hooks use `plugins/cache/omc/` -- no collision risk

### Hook script location and language
- All hook scripts live under `skills/core/hooks/` in the repo
- Written in TypeScript, run via `bun`
- Shared context utility at `skills/core/hooks/lib/context.ts` -- injects active persona + project path into hook context
- Each hook imports the shared utility for consistent contract
- This overrides the project constraint "no TypeScript/Node dependencies" -- bun is already required, TypeScript hooks match the GSD/OMC ecosystem

### Hook scope
- All 15 LAWs get hook scripts under `skills/core/hooks/`
- 10 existing hooks (currently in GSD/PAI paths) are PORTED to our TypeScript + wrapper pattern -- not copied verbatim
- 5 missing hooks (LAWs 10-14, currently "Manual") are written fresh
- After installation, PAI hooks are self-contained -- no dependency on GSD or PAI hook paths
- Manifest declares all 15 hooks with event type, matcher, and command path

### Installer architecture
- **Markdown-first:** Primary install path is markdown instructions (INSTALL.md) designed for AI agents to follow
- **Script secondary:** Convenience shell script wraps the same operations for humans
- **Multi-backend JSON:** Installer detects available JSON tool and uses it:
  - `bun` (TypeScript helper) -- preferred
  - `python3`/`uv` -- fallback
  - `jq` -- last resort
- Prerequisites validated first (Phase 10 prereqs.sh), then installer uses whatever JSON tool is available
- Shell script handles flow: backup, validation, reporting. Delegates JSON merge to detected backend.

### Backup and idempotency
- settings.json backed up before any modification (HOOK-05)
- Timestamped backup: `settings.json.backup-YYYY-MM-DD-HHMMSS`
- Running installer twice produces same result (HOOK-04) -- checks if hook already exists before adding
- Uninstaller only removes hooks matching both path convention AND manifest entry (HOOK-03)

### Hook manifest format
- JSON file declaring all hooks: event type, matcher pattern, command path, description, LAW reference
- Lives at `skills/core/hooks/manifest.json`
- Used by both installer (what to add) and uninstaller (what to remove)

### Claude's Discretion
- Exact manifest JSON schema (beyond required fields above)
- How to detect active persona in the shared context utility
- Specific jq/TypeScript/Python implementations for the JSON merge
- Hook script internal structure (beyond using shared context utility)
- Whether to split hooks into subdirectories by event type or keep flat

</decisions>

<specifics>
## Specific Ideas

- Current settings.json has 21 hooks across 7 event types (SessionStart, PreToolUse, PostToolUse, Stop, SubagentStop, SessionEnd, UserPromptSubmit)
- GSD hooks use paths under `~/.claude/get-shit-done/`, OMC hooks use `~/.claude/plugins/cache/omc/`
- The shared context wrapper enriches Claude Code's default stdin JSON with active persona and project path -- minimal overhead, high value for LAW 4 (persona-aware critical thinking enforcement)
- Phase 6 LAW files document enforcement metadata -- use this as the source for which event type and matcher each hook needs

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/core/references/laws/*.md`: 15 LAW files with enforcement metadata (event type, matcher documented per LAW)
- `tools/install.sh`: Existing dual-target installer -- pattern for argument parsing, target detection
- `tools/uninstall.sh`: Existing uninstaller -- pattern for clean removal
- GSD hooks at `~/.claude/get-shit-done/hooks/`: 10 working hook scripts to port from

### Established Patterns
- Claude Code hooks: JSON entries in `settings.json` under `hooks.{EventType}[]` with `matcher` and `command` fields
- GSD hook contract: stdin receives JSON context, stdout/stderr for response
- Slim SKILL.md + deep references: hooks/ follows same pattern as references/

### Integration Points
- `~/.claude/settings.json`: Target file for hook registration
- `skills/core/SKILL.md`: Needs hooks section added (or topic table updated)
- `INDEX.md`: May need update if hooks add new capability
- Phase 10 (Bootstrap): prereqs.sh validates bun is available before hooks can run

</code_context>

<deferred>
## Deferred Ideas

- **Hook testing framework** -- automated tests for hooks (run hook, check output). Good idea but out of scope for Phase 7.
- **Hook hot-reload** -- detect settings.json changes and reload without restarting Claude Code. Not possible with current Claude Code architecture.
- **Per-project hook overrides** -- allow project-level CLAUDE.md to disable specific LAW hooks. Interesting but complex -- revisit in Phase 9-10.

</deferred>

---

*Phase: 07-hook-installation*
*Context gathered: 2026-03-07*
