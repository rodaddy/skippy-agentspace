# Phase 11: Foundation - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract shared shell functions into `tools/lib/common.sh` and add `.gitattributes` for clean distribution. The 6 existing tools/ scripts (1,507 lines total) currently have zero shared code -- each is fully self-contained with duplicated patterns for repo root detection, output formatting, and install status checking.

</domain>

<decisions>
## Implementation Decisions

### Output helper naming
- Use `skippy_pass`, `skippy_warn`, `skippy_fail`, `skippy_suggest` -- four helpers
- Single argument signature: `skippy_pass "message"` -- no detail parameter
- Emoji prefixes matching current style: pass='✓', warn='⚠', fail='✗', suggest='💡'
- Scripts currently using `report_ok`/`report_missing` (prereqs.sh) switch to skippy_ names

### Fallback behavior
- Inline minimal stubs if `common.sh` is missing -- scripts keep working with degraded output
- Full stubs including counters so `skippy_summary()` still works even without common.sh
- Fallback block defines: counter init, all 4 output helpers, and skippy_summary

### Repo root detection
- `skippy_repo_root()` function with auto-detect plus env override
- Primary: derive from `dirname($0)/..`, validate by checking for `skills/` directory
- Fallback: check `$SKIPPY_ROOT` env var if dirname detection fails
- Supports both in-repo execution (first install) and out-of-repo execution (updates from /tmp)

### Counter & summary system
- common.sh owns the full lifecycle: init counters to 0, auto-increment in helpers, summary prints report
- Counter variables: `SKIPPY_PASS`, `SKIPPY_WARN`, `SKIPPY_FAIL` (no _COUNT suffix)
- `skippy_summary()` prints totals AND sets exit code (0 if no failures, 1 if any)
- Scripts end with `skippy_summary` as their last line -- no manual exit logic needed
- `skippy_section "Name"` provides `=== Name ===` header formatting for grouped output

### .gitattributes scope
- `.planning/` -- export-ignore (required by success criteria)
- `.reports/` and `docs/` -- export-ignore (audit/analysis artifacts)
- `tests/` and `.github/` -- export-ignore (dev/CI only, tests from Phase 12)
- `upstreams/` -- export-ignore (upstream tracking metadata)
- `CONVENTIONS.md` and `CHANGELOG.md` -- kept in exports (useful for installed users)
- No linguist attributes -- not worth complexity for private repo

### Claude's Discretion
- Exact color codes (ANSI escape sequences) for terminal output
- Whether `skippy_section` uses `===` or `---` or bold ANSI
- Internal implementation of `skippy_is_installed()` (return code vs echo)
- Order of functions in common.sh
- Whether to add a `skippy_debug()` helper for verbose mode

</decisions>

<specifics>
## Specific Ideas

- Fallback stub block should be copy-pasteable -- one block that any script can use identically
- `skippy_repo_root()` validates by checking for `skills/` directory presence, not just trusting dirname
- prereqs.sh has a Bash 3.2 compatibility requirement (Phase 10 decision) -- common.sh itself should work on Bash 4+ since prereqs.sh checks for that first, but the sourcing/fallback pattern must not use Bash 4+ syntax

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- verify.sh (lines 30-33): `pass()`/`warn()`/`fail()`/`suggest()` with counter increments -- closest to target pattern
- index-sync.sh (lines 22-28): `is_installed()` function -- cleanest existing install check
- All 4 scripts using REPO_ROOT use identical `cd "$(dirname "$0")/.." && pwd` pattern

### Established Patterns
- All scripts use `#!/usr/bin/env bash` (LAW 7 compliant)
- No script currently sources external files -- all self-contained
- `[[ ]]` and `[ ]` mixed across scripts -- not a blocker but worth noting
- verify.sh delegates to validate-hooks.sh via subprocess (line 135)

### Integration Points
- All 6 tools/ scripts will source common.sh near the top
- Skill scripts in `skills/*/scripts/*.sh` must NOT source common.sh (portability constraint from success criteria)
- prereqs.sh runs before bash upgrade -- fallback stubs must use Bash 3.2 syntax
- verify.sh currently delegates section-style output -- will switch to skippy_section

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 11-foundation*
*Context gathered: 2026-03-08*
