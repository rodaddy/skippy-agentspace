#!/usr/bin/env bash
# common.bash -- Shared test setup for bats tests
# Loaded via: load 'test_helper/common'
#
# Provides _common_setup() which:
#   - Sandboxes HOME to BATS_TEST_TMPDIR (prevents touching real ~/.claude/)
#   - Creates fixture directories in sandboxed HOME
#   - Sets REPO_ROOT to the actual repo root
#   - Exports SKIPPY_ROOT as fallback for common.sh repo root detection
#   - Loads bats-support and bats-assert

_common_setup() {
    # Sandbox HOME -- CRITICAL: prevents tests from touching real ~/.claude/
    export HOME="$BATS_TEST_TMPDIR"

    # Create standard directories tests expect
    mkdir -p "$HOME/.claude/skills"
    mkdir -p "$HOME/.claude/commands"

    # Resolve repo root from this file's location (tests/test_helper/common.bash -> ../../)
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export REPO_ROOT

    # Fallback for common.sh repo root detection when BASH_SOURCE path differs
    export SKIPPY_ROOT="$REPO_ROOT"

    # Load bats helpers (paths relative to the .bats test file, not this helper)
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}
