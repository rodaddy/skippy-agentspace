#!/usr/bin/env bats
# common-lib.bats -- Tests for tools/lib/common.sh
# Covers: repo_root, pass/warn/fail counters, summary exit codes, is_installed detection, colors

setup() {
    load 'test_helper/common'
    _common_setup

    # Reset counters BEFORE sourcing so common.sh's ${VAR:-0} initializes fresh
    unset SKIPPY_PASS SKIPPY_WARN SKIPPY_FAIL

    # Source the library under test
    source "$REPO_ROOT/tools/lib/common.sh"
}

# --- Repo root detection ---

@test "skippy_repo_root returns repo root containing skills/ directory" {
    run skippy_repo_root
    assert_success
    # The returned path should contain a skills/ directory
    [ -d "$output/skills" ]
}

@test "skippy_repo_root falls back to SKIPPY_ROOT env var" {
    # SKIPPY_ROOT is already set by _common_setup -- verify it works
    run skippy_repo_root
    assert_success
    assert_output "$SKIPPY_ROOT"
}

# --- Counter functions ---

@test "skippy_pass increments counter and outputs message" {
    run skippy_pass "thing works"
    assert_success
    assert_output --partial "PASS:"
    assert_output --partial "thing works"
    # Counter incremented in subshell from run -- check directly
    skippy_pass "direct call"
    [ "$SKIPPY_PASS" -eq 1 ]
}

@test "skippy_warn increments counter and outputs message" {
    run skippy_warn "something iffy"
    assert_success
    assert_output --partial "WARN:"
    assert_output --partial "something iffy"
    skippy_warn "direct call"
    [ "$SKIPPY_WARN" -eq 1 ]
}

@test "skippy_fail increments counter and outputs message" {
    run skippy_fail "thing broke"
    assert_success
    assert_output --partial "FAIL:"
    assert_output --partial "thing broke"
    skippy_fail "direct call"
    [ "$SKIPPY_FAIL" -eq 1 ]
}

# --- Summary exit codes ---

@test "skippy_summary returns 0 with no failures" {
    SKIPPY_PASS=3
    SKIPPY_WARN=1
    SKIPPY_FAIL=0
    run skippy_summary
    assert_success
    assert_output --partial "3 passed"
    assert_output --partial "1 warnings"
    assert_output --partial "0 failures"
}

@test "skippy_summary returns 1 with failures" {
    SKIPPY_PASS=2
    SKIPPY_WARN=0
    SKIPPY_FAIL=1
    run skippy_summary
    assert_failure
    assert_output --partial "1 failures"
}

# --- Install detection ---

@test "skippy_is_installed detects existing symlink" {
    # Create a fake skill symlink in the sandboxed HOME
    mkdir -p "$HOME/.claude/skills"
    ln -s "$REPO_ROOT/skills/core" "$HOME/.claude/skills/core"
    run skippy_is_installed "core"
    assert_success
}

@test "skippy_is_installed returns 1 for missing skill" {
    run skippy_is_installed "nonexistent-skill"
    assert_failure
}

# --- Color detection ---

@test "colors are disabled when stdout is not a terminal" {
    # bats runs non-interactively, so colors should be empty strings
    [ -z "$_SKIPPY_GREEN" ]
    [ -z "$_SKIPPY_RED" ]
    [ -z "$_SKIPPY_YELLOW" ]
    [ -z "$_SKIPPY_RESET" ]
}
