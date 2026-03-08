#!/usr/bin/env bash
# common.sh -- Shared functions for skippy-agentspace tools/
# Sourced by tools/*.sh, never executed directly.
#
# Provides:
#   skippy_repo_root     - Resolve repository root path
#   skippy_pass          - Print pass message, increment counter
#   skippy_warn          - Print warning message, increment counter
#   skippy_fail          - Print failure message, increment counter
#   skippy_suggest       - Print suggestion (no counter)
#   skippy_section       - Print section header
#   skippy_summary       - Print totals, return 0 if no failures
#   skippy_is_installed  - Check if a skill is symlinked

# --- Direct execution guard ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "ERROR: common.sh should be sourced, not executed directly." >&2
    echo "Usage: source tools/lib/common.sh" >&2
    exit 1
fi

# --- Counter initialization ---
# Use :- so re-sourcing in bats test harnesses doesn't reset counters mid-test.
SKIPPY_PASS=${SKIPPY_PASS:-0}
SKIPPY_WARN=${SKIPPY_WARN:-0}
SKIPPY_FAIL=${SKIPPY_FAIL:-0}

# --- ANSI colors ---
_SKIPPY_GREEN='\033[0;32m'
_SKIPPY_YELLOW='\033[0;33m'
_SKIPPY_RED='\033[0;31m'
_SKIPPY_CYAN='\033[0;36m'
_SKIPPY_BOLD='\033[1m'
_SKIPPY_RESET='\033[0m'

# Disable colors if stdout is not a terminal
if [[ ! -t 1 ]]; then
    _SKIPPY_GREEN=''
    _SKIPPY_YELLOW=''
    _SKIPPY_RED=''
    _SKIPPY_CYAN=''
    _SKIPPY_BOLD=''
    _SKIPPY_RESET=''
fi

# --- Repo root detection ---
# Primary: derive from BASH_SOURCE (tools/lib/common.sh -> ../../)
# Validate: check for skills/ directory
# Fallback: $SKIPPY_ROOT env var
# Last resort: return unvalidated path with return code 1
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
skippy_pass() {
    : "${1:?skippy_pass requires a message argument}"
    echo -e "  ${_SKIPPY_GREEN}PASS:${_SKIPPY_RESET} $1"
    SKIPPY_PASS=$((SKIPPY_PASS + 1))
}

skippy_warn() {
    : "${1:?skippy_warn requires a message argument}"
    echo -e "  ${_SKIPPY_YELLOW}WARN:${_SKIPPY_RESET} $1"
    SKIPPY_WARN=$((SKIPPY_WARN + 1))
}

skippy_fail() {
    : "${1:?skippy_fail requires a message argument}"
    echo -e "  ${_SKIPPY_RED}FAIL:${_SKIPPY_RESET} $1"
    SKIPPY_FAIL=$((SKIPPY_FAIL + 1))
}

skippy_suggest() {
    : "${1:?skippy_suggest requires a message argument}"
    echo -e "    ${_SKIPPY_CYAN}Fix:${_SKIPPY_RESET} $1"
}

# --- Section header ---
skippy_section() {
    : "${1:?skippy_section requires a section name}"
    echo -e "\n${_SKIPPY_BOLD}=== $1 ===${_SKIPPY_RESET}"
}

# --- Summary with exit code ---
# Prints pass/warn/fail totals. Returns 0 if no failures, 1 otherwise.
# Scripts should end with this as their last line.
skippy_summary() {
    echo ""
    echo "  $SKIPPY_PASS passed, $SKIPPY_WARN warnings, $SKIPPY_FAIL failures"
    if [[ "$SKIPPY_FAIL" -gt 0 ]]; then
        return 1
    fi
    return 0
}

# --- Input validation ---
# Validates a skill name: must be non-empty, no path separators, no leading dot.
skippy_validate_skill_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: Skill name cannot be empty" >&2
        return 1
    fi
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid skill name '$name' -- must contain only alphanumerics, hyphens, and underscores" >&2
        return 1
    fi
    return 0
}

# --- Install detection ---
# Returns 0 if skill is installed (symlink exists), 1 otherwise.
skippy_is_installed() {
    local skill_name="$1"
    [[ -L "$HOME/.claude/skills/$skill_name" ]] || [[ -L "$HOME/.claude/commands/$skill_name" ]]
}
