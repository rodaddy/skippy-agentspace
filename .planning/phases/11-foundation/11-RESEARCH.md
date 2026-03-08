# Phase 11: Foundation - Research

**Researched:** 2026-03-08
**Domain:** Shell shared library extraction + git distribution attributes
**Confidence:** HIGH

## Summary

Phase 11 is a well-scoped refactoring phase with two distinct deliverables: (1) extracting duplicated shell patterns from 6 `tools/` scripts into `tools/lib/common.sh`, and (2) creating `.gitattributes` with `export-ignore` rules for clean distribution. Both are well-understood shell engineering tasks with zero external dependencies.

All 6 scripts (1,507 lines total) are fully self-contained today. Four scripts use identical `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` patterns. Three scripts (verify.sh, validate-hooks.sh, prereqs.sh) define independent pass/fail/counter systems. Two scripts (index-sync.sh, verify.sh) duplicate install-detection logic. The extraction is mechanical -- no behavioral changes, just consolidation with a new `skippy_` namespace.

**Primary recommendation:** Extract 5 function groups into `tools/lib/common.sh` (repo root, 4 output helpers, counters+summary, section headers, install detection), then update each of the 6 scripts to source it with inline fallback stubs. Create `.gitattributes` with both directory name and `/**` glob for each excluded path.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Output helpers: `skippy_pass`, `skippy_warn`, `skippy_fail`, `skippy_suggest` -- four helpers, single argument, emoji prefixes (pass=checkmark, warn=warning, fail=x, suggest=lightbulb)
- Fallback: inline minimal stubs if `common.sh` is missing -- full stubs including counters so `skippy_summary()` still works
- Repo root: `skippy_repo_root()` with auto-detect plus `$SKIPPY_ROOT` env override, validates by checking for `skills/` directory
- Counters: `SKIPPY_PASS`, `SKIPPY_WARN`, `SKIPPY_FAIL` (no _COUNT suffix), auto-increment in helpers, `skippy_summary()` prints totals and sets exit code
- `skippy_section "Name"` for `=== Name ===` header formatting
- .gitattributes scope: `.planning/`, `.reports/`, `docs/`, `tests/`, `.github/`, `upstreams/` as export-ignore; CONVENTIONS.md and CHANGELOG.md kept in exports
- No linguist attributes
- prereqs.sh fallback block must use Bash 3.2 syntax (prereqs.sh runs before bash upgrade)
- Skill scripts (`skills/*/scripts/*.sh`) must NOT source common.sh (portability constraint)

### Claude's Discretion
- Exact ANSI color codes for terminal output
- Whether `skippy_section` uses `===` or `---` or bold ANSI
- Internal implementation of `skippy_is_installed()` (return code vs echo)
- Order of functions in common.sh
- Whether to add a `skippy_debug()` helper for verbose mode

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUND-01 | `tools/lib/common.sh` extracts shared functions (`REPO_ROOT`, `pass`/`warn`/`fail`, `is_installed`) used by 3+ scripts | Exact duplication patterns mapped across all 6 scripts; function signatures locked via CONTEXT.md decisions |
| FOUND-02 | `.gitattributes` marks `.planning/` as `export-ignore` for distribution | Git official docs confirm syntax; scope expanded per CONTEXT.md to include .reports/, docs/, tests/, .github/, upstreams/ |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 4+ (common.sh), 3.2 (fallback stubs) | Shell runtime | Already project standard; prereqs.sh enforces 4+ |
| git | any | `.gitattributes` processing | Built-in git feature, no external tool needed |

### Supporting
No additional libraries needed. This phase is pure shell refactoring with zero dependencies.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline fallback stubs | `set +e` + source-or-die | Violates success criteria -- scripts must keep working without common.sh |
| POSIX `.` sourcing | `source` keyword | Both work in bash 4+; POSIX form is more portable but `source` is clearer -- either is fine since we require bash |

**Installation:**
```bash
# No installation needed -- pure shell, zero dependencies
mkdir -p tools/lib
```

## Architecture Patterns

### Recommended Project Structure
```
tools/
  lib/
    common.sh            # Shared library (NEW)
  index-sync.sh          # Sources common.sh
  install.sh             # Sources common.sh
  prereqs.sh             # Sources common.sh (Bash 3.2 fallback)
  uninstall.sh           # Sources common.sh
  validate-hooks.sh      # Sources common.sh
  verify.sh              # Sources common.sh
.gitattributes           # Distribution exclusions (NEW)
```

### Pattern 1: Source-with-Fallback
**What:** Each script sources `common.sh` but defines inline stubs if the file is missing.
**When to use:** Every tools/ script.
**Example:**
```bash
# Source shared library with graceful fallback
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Minimal stubs -- script works with degraded output
    SKIPPY_PASS=0 SKIPPY_WARN=0 SKIPPY_FAIL=0
    skippy_pass()    { echo "  PASS: $1"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn()    { echo "  WARN: $1"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail()    { echo "  FAIL: $1"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_suggest() { echo "    Fix: $1"; }
    skippy_section() { echo "=== $1 ==="; }
    skippy_summary() {
        echo "  $SKIPPY_PASS passed, $SKIPPY_WARN warnings, $SKIPPY_FAIL failures"
        [[ "$SKIPPY_FAIL" -eq 0 ]] && return 0 || return 1
    }
    skippy_repo_root() {
        local root
        root="$(cd "$(dirname "$0")/.." && pwd)"
        if [[ -d "$root/skills" ]]; then echo "$root"; return 0; fi
        if [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]]; then echo "$SKIPPY_ROOT"; return 0; fi
        echo "$root"
    }
    skippy_is_installed() {
        [[ -L "$HOME/.claude/skills/$1" ]] || [[ -L "$HOME/.claude/commands/$1" ]]
    }
fi
```
**Source:** Informed by bash shared library best practices and CONTEXT.md decisions.

### Pattern 2: Namespace Prefix Convention
**What:** All common.sh functions and counter variables use `skippy_` prefix.
**When to use:** Every exported function and global variable.
**Why:** Avoids collision with script-local functions (verify.sh currently uses bare `pass()`, `fail()`).

### Pattern 3: Function-Based Repo Root
**What:** `skippy_repo_root()` replaces inline `REPO_ROOT=...` assignments.
**When to use:** Any script that needs the repository root path.
**Example:**
```bash
# In common.sh
skippy_repo_root() {
    local root
    # Primary: derive from script location
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    # Validate: check for skills/ directory
    if [[ -d "$root/skills" ]]; then
        echo "$root"
        return 0
    fi
    # Fallback: env var
    if [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]]; then
        echo "$SKIPPY_ROOT"
        return 0
    fi
    # Last resort: return unvalidated
    echo "$root"
    return 1
}
```
**Key detail:** common.sh lives at `tools/lib/common.sh`, so the repo root from `BASH_SOURCE[0]` is `../../` (up from lib/, up from tools/). But in the fallback block each script uses `dirname "$0"/..` since that's relative to the script itself in `tools/`.

### Anti-Patterns to Avoid
- **Sourcing common.sh from skill scripts:** Success criteria explicitly forbids `skills/*/scripts/*.sh` from sourcing common.sh. Skills must remain fully standalone for portability.
- **Using `$BASH_SOURCE` in the fallback block:** The fallback runs inline in the calling script, so `$BASH_SOURCE` would point to the caller, not to common.sh. Use `$0` instead.
- **Using Bash 4+ syntax in the fallback block:** prereqs.sh must work on Bash 3.2 (macOS default). The fallback block is copy-pasted into prereqs.sh, so it must avoid associative arrays, `declare -A`, `${var,,}` case conversion, etc. Note: `[[ ]]` is fine in Bash 3.2.
- **Double-incrementing counters:** If a script sources common.sh AND defines its own counter increment in pass/fail, counts will be wrong. The switchover must be all-or-nothing per script.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repo root detection | Hardcoded paths per script | `skippy_repo_root()` | 4 scripts duplicate the same pattern; centralizing catches edge cases (symlinks, /tmp execution) |
| Output formatting | Per-script pass/fail/warn | `skippy_pass/warn/fail/suggest` | 3 scripts have independent implementations with inconsistent formatting |
| Install detection | Per-script symlink checks | `skippy_is_installed()` | 2 scripts duplicate `[[ -L ~/.claude/skills/$name ]]` checks |
| Summary with exit code | Manual counter + conditional exit | `skippy_summary()` | Ensures consistent exit behavior across all scripts |

**Key insight:** The 6 scripts have organically grown parallel implementations of the same 5 concerns. Centralizing them eliminates ~80 lines of duplicated code and ensures behavioral consistency.

## Common Pitfalls

### Pitfall 1: BASH_SOURCE vs $0 in sourced files
**What goes wrong:** `$0` in a sourced file refers to the caller, not the sourced file. `${BASH_SOURCE[0]}` refers to the file being sourced.
**Why it happens:** common.sh is sourced (not executed), so `$0` = the calling script.
**How to avoid:** In common.sh, use `${BASH_SOURCE[0]}` for self-referencing paths (e.g., computing repo root). In fallback stubs (inline in the caller), use `$0`.
**Warning signs:** `skippy_repo_root()` returns wrong path when called from different directories.

### Pitfall 2: Bash 3.2 compatibility in fallback block
**What goes wrong:** prereqs.sh runs before bash upgrade. If the fallback block uses Bash 4+ syntax, prereqs.sh breaks on fresh macOS.
**Why it happens:** macOS ships with Bash 3.2. prereqs.sh is the script that checks for and installs Bash 4+.
**How to avoid:** Fallback block must avoid: associative arrays (`declare -A`), `${var,,}` / `${var^^}`, `|&`, `coproc`, `mapfile`/`readarray`. All standard `[[ ]]` and arithmetic `$(( ))` are fine.
**Warning signs:** prereqs.sh fails with syntax errors on a fresh macOS install.

### Pitfall 3: set -e + source interaction
**What goes wrong:** If common.sh has a command that returns non-zero during sourcing, `set -e` in the caller kills the script.
**Why it happens:** All 6 scripts use `set -euo pipefail`. Sourced files execute in the caller's context.
**How to avoid:** common.sh should only define functions and initialize variables (all return 0). No command execution during source time. Counter initializations like `SKIPPY_PASS=0` are safe.
**Warning signs:** Script exits immediately after sourcing common.sh with no error message.

### Pitfall 4: Variable collision during migration
**What goes wrong:** verify.sh currently uses `PASS_COUNT`, common.sh introduces `SKIPPY_PASS`. If both exist during a partial migration, counts diverge.
**Why it happens:** Incremental migration where old and new variable names coexist.
**How to avoid:** Full switchover per script -- replace ALL `pass()`/`PASS_COUNT` references with `skippy_pass()`/`SKIPPY_PASS` in a single commit per script.
**Warning signs:** Summary line shows 0 even though checks ran.

### Pitfall 5: export-ignore needs both directory and glob
**What goes wrong:** Using just `.planning/ export-ignore` won't exclude contents recursively.
**Why it happens:** Git's `.gitattributes` patterns matching directories don't recursively match paths inside that directory (unlike `.gitignore`).
**How to avoid:** Use both forms: `.planning export-ignore` AND `.planning/** export-ignore`.
**Warning signs:** `git archive` still includes files under excluded directories.

## Code Examples

Verified patterns from analysis of existing codebase:

### common.sh Full Structure
```bash
#!/usr/bin/env bash
# common.sh -- Shared functions for skippy-agentspace tools/
# Sourced by tools/*.sh, never executed directly.
#
# Provides:
#   skippy_repo_root    - Resolve repository root path
#   skippy_pass/warn/fail/suggest - Output helpers with counters
#   skippy_section      - Section header formatting
#   skippy_summary      - Print totals, set exit code
#   skippy_is_installed - Check if a skill is symlinked

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "ERROR: common.sh should be sourced, not executed directly." >&2
    exit 1
fi

# --- Counter initialization ---
SKIPPY_PASS=0
SKIPPY_WARN=0
SKIPPY_FAIL=0

# --- Repo root detection ---
skippy_repo_root() {
    local root
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    if [[ -d "$root/skills" ]]; then
        echo "$root"
        return 0
    fi
    if [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]]; then
        echo "$SKIPPY_ROOT"
        return 0
    fi
    echo "$root"
    return 1
}

# --- Output helpers ---
skippy_pass()    { echo "  PASS: $1"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
skippy_warn()    { echo "  WARN: $1"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
skippy_fail()    { echo "  FAIL: $1"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
skippy_suggest() { echo "    Fix: $1"; }

# --- Section header ---
skippy_section() { echo "=== $1 ==="; }

# --- Summary with exit code ---
skippy_summary() {
    echo "  $SKIPPY_PASS passed, $SKIPPY_WARN warnings, $SKIPPY_FAIL failures"
    if [[ "$SKIPPY_FAIL" -gt 0 ]]; then
        return 1
    fi
    return 0
}

# --- Install detection ---
skippy_is_installed() {
    local skill_name="$1"
    [[ -L "$HOME/.claude/skills/$skill_name" ]] || [[ -L "$HOME/.claude/commands/$skill_name" ]]
}
```

### Sourcing Pattern (for scripts using pass/fail/summary)
```bash
# Near top of script, after set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # [fallback stubs -- copy-paste block]
fi
REPO_ROOT="$(skippy_repo_root)"
```

### Sourcing Pattern (for scripts only using repo root / is_installed)
```bash
# For scripts like install.sh that don't use pass/fail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Minimal fallback -- just what this script needs
    skippy_repo_root() {
        local root
        root="$(cd "$(dirname "$0")/.." && pwd)"
        if [[ -d "$root/skills" ]]; then echo "$root"; return 0; fi
        if [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]]; then echo "$SKIPPY_ROOT"; return 0; fi
        echo "$root"
    }
    skippy_is_installed() {
        [[ -L "$HOME/.claude/skills/$1" ]] || [[ -L "$HOME/.claude/commands/$1" ]]
    }
fi
REPO_ROOT="$(skippy_repo_root)"
```

### .gitattributes File
```gitattributes
# Distribution: exclude dev-only paths from git archive
.planning export-ignore
.planning/** export-ignore
.reports export-ignore
.reports/** export-ignore
docs export-ignore
docs/** export-ignore
tests export-ignore
tests/** export-ignore
.github export-ignore
.github/** export-ignore
upstreams export-ignore
upstreams/** export-ignore

# Exclude git metadata from archive
.gitattributes export-ignore
.gitignore export-ignore
```

### Per-Script Migration Map

| Script | Currently Uses | Will Use from common.sh | Notes |
|--------|---------------|------------------------|-------|
| verify.sh | `REPO_ROOT`, `pass/warn/fail/suggest`, `PASS/WARN/FAIL_COUNT`, `=== section ===` | `skippy_repo_root`, `skippy_pass/warn/fail/suggest`, `SKIPPY_PASS/WARN/FAIL`, `skippy_section`, `skippy_summary` | Heaviest user -- uses all 5 function groups |
| validate-hooks.sh | `REPO_ROOT`, `pass/fail`, `PASS/FAIL_COUNT` | `skippy_repo_root`, `skippy_pass/skippy_fail`, `SKIPPY_PASS/SKIPPY_FAIL`, `skippy_summary` | No warn/suggest currently -- will gain them |
| prereqs.sh | `ok_count/missing_count`, `report_ok/report_missing/report_outdated` | `skippy_pass/skippy_fail/skippy_warn` | Bash 3.2 fallback required; rename report_ok->skippy_pass, report_missing->skippy_fail, report_outdated->skippy_warn |
| index-sync.sh | `REPO_ROOT`, `is_installed()` | `skippy_repo_root`, `skippy_is_installed` | Doesn't use pass/fail counters |
| install.sh | `REPO_ROOT`, inline symlink checks | `skippy_repo_root`, `skippy_is_installed` | Doesn't use pass/fail counters |
| uninstall.sh | inline `REPO_SKILLS_DIR` derivation | `skippy_repo_root` | Only uses repo root in `--all` mode; no pass/fail |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-script `pass()/fail()` | Namespaced `skippy_pass()/skippy_fail()` | This phase | Prevents collision with shell builtins and other tools |
| Bare `REPO_ROOT=...` | `skippy_repo_root()` with validation | This phase | Handles edge cases: symlinks, /tmp execution, env override |
| No `.gitattributes` | `export-ignore` for dev paths | This phase | Clean `git archive` for distribution |

**Deprecated/outdated:**
- `report_ok`/`report_missing` in prereqs.sh: replaced by `skippy_pass`/`skippy_fail`
- `is_installed()` in index-sync.sh: replaced by `skippy_is_installed()`
- Bare `pass()`/`fail()` in verify.sh and validate-hooks.sh: replaced by `skippy_pass()`/`skippy_fail()`

## Open Questions

1. **prereqs.sh counter semantics change**
   - What we know: prereqs.sh currently uses `ok_count`/`missing_count` with `report_ok`/`report_missing`/`report_outdated` (where outdated increments missing_count). It also has a separate `final_ok`/`final_missing` recount after install prompts.
   - What's unclear: Should the install-prompt-and-recheck loop continue using its own final recount, or should the skippy_ counters be reset mid-script?
   - Recommendation: Keep the final recount pattern -- it's specific to prereqs.sh's interactive flow. The skippy_ counters from the initial scan inform the user; the final boolean flags (`git_ok`, `bash_ok`, etc.) drive the exit code. prereqs.sh may be the one script that uses `skippy_pass`/`skippy_fail` for display but keeps its own exit-code logic rather than `skippy_summary`.

2. **validate-hooks.sh counter behavior in `--full` mode**
   - What we know: validate-hooks.sh runs quick checks (5 sections) or full (9 sections). Total count is dynamic.
   - What's unclear: Currently prints `Results: $PASS_COUNT/$TOTAL passed`. `skippy_summary` uses a different format.
   - Recommendation: Use `skippy_summary` for consistency. The `X/Y passed` format can be reconstructed from `SKIPPY_PASS + SKIPPY_FAIL` if needed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bats-core (planned Phase 12, not yet installed) |
| Config file | none -- Phase 12 will create |
| Quick run command | `bats tests/common-lib.bats` |
| Full suite command | `bats tests/` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | common.sh functions work correctly | unit | `bats tests/common-lib.bats` | No -- Wave 0 / Phase 12 |
| FOUND-01 | All 6 scripts source common.sh | smoke | `bash tools/verify.sh` (existing) | Yes (verify.sh exists) |
| FOUND-01 | Scripts work when common.sh is missing | unit | `bats tests/common-lib.bats::fallback` | No -- Wave 0 / Phase 12 |
| FOUND-02 | .gitattributes excludes dev paths | smoke | `git archive HEAD \| tar t \| grep -c .planning` | Manual verification |

### Sampling Rate
- **Per task commit:** `bash tools/verify.sh` (smoke test existing scripts still work)
- **Per wave merge:** Run each of the 6 scripts individually to confirm no regressions
- **Phase gate:** All 6 scripts pass, `skippy_summary` exit codes correct, `.gitattributes` exists

### Wave 0 Gaps
- [ ] `tests/` directory -- does not exist yet (Phase 12 scope)
- [ ] bats-core not installed -- Phase 12 will handle
- [ ] Manual verification sufficient for this phase; automated tests come in Phase 12

*(Phase 12 will create `tests/common-lib.bats` covering these exact functions)*

## Sources

### Primary (HIGH confidence)
- Codebase analysis of all 6 `tools/*.sh` scripts (1,507 lines) -- direct inspection of duplicated patterns
- CONTEXT.md locked decisions -- all function names, signatures, and scope defined

### Secondary (MEDIUM confidence)
- [Git official docs - gitattributes](https://git-scm.com/docs/gitattributes) -- `export-ignore` syntax, directory matching behavior
- [Git Pro Book - Git Attributes](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes) -- export-ignore usage patterns
- [Designing Modular Bash](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) -- namespace prefixing, BASH_SOURCE patterns
- [Bash Libraries](https://gabrielstaples.com/bash-libraries/) -- sourcing patterns, relative imports
- [PHPWatch - GitAttributes](https://php.watch/articles/composer-gitattributes) -- export-ignore directory+glob pattern (both needed)
- [Excluding files from git archive](https://feeding.cloud.geek.nz/posts/excluding-files-from-git-archive/) -- verified directory exclusion syntax

### Tertiary (LOW confidence)
None -- all findings verified against official docs or direct codebase inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure shell, no external dependencies, patterns well-understood
- Architecture: HIGH -- CONTEXT.md locks all function names/signatures; only implementation details remain
- Pitfalls: HIGH -- identified from direct codebase analysis (Bash 3.2 compat, BASH_SOURCE vs $0, set -e interaction)

**Research date:** 2026-03-08
**Valid until:** Indefinite -- bash shell patterns and git attributes are stable specifications
