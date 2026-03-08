#!/usr/bin/env bats
# verify.bats -- Tests for tools/verify.sh
# Covers: prerequisites check, skill detection, section headers, exit codes

setup() {
    load 'test_helper/common'
    _common_setup

    VERIFY_SCRIPT="$REPO_ROOT/tools/verify.sh"
    INSTALL_SCRIPT="$REPO_ROOT/tools/install.sh"
}

# --- Prerequisites ---

@test "verify checks prerequisites (bun, jq, git, bash)" {
    run bash "$VERIFY_SCRIPT"
    # Should mention prerequisite tools regardless of pass/fail
    assert_output --partial "bun"
    assert_output --partial "jq"
    assert_output --partial "git"
    assert_output --partial "bash"
}

# --- Section headers ---

@test "verify output includes section headers" {
    run bash "$VERIFY_SCRIPT"
    assert_output --partial "Prerequisites"
    assert_output --partial "Skills"
    assert_output --partial "Hooks"
    assert_output --partial "Commands"
}

# --- Skill detection ---

@test "verify runs successfully with all skills installed" {
    # Install all skills into sandboxed HOME
    bash "$INSTALL_SCRIPT" --all >/dev/null 2>&1

    run bash "$VERIFY_SCRIPT"
    assert_success
}

@test "verify detects missing core skill" {
    # Do NOT install anything -- sandboxed HOME has no symlinks
    # Core missing = failure
    run bash "$VERIFY_SCRIPT"
    assert_failure
    assert_output --partial "core"
}
