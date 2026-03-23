#!/usr/bin/env bats
# install.bats -- Tests for tools/install.sh
# Covers: no-args status, --core, --all, positional, idempotent, error cases, legacy target

setup() {
    load 'test_helper/common'
    _common_setup

    INSTALL_SCRIPT="$REPO_ROOT/tools/install.sh"
}

# --- Status display ---

@test "install no args shows status table" {
    run bash "$INSTALL_SCRIPT"
    assert_success
    assert_output --partial "SKILL"
}

# --- Core install ---

@test "install --core installs core skill" {
    run bash "$INSTALL_SCRIPT" --core
    assert_success
    [ -d "$HOME/.claude/skills/core" ] || [ -L "$HOME/.claude/skills/core" ]
}

# --- All install ---

@test "install --all installs all skills" {
    run bash "$INSTALL_SCRIPT" --all
    assert_success
    # Count installed skills (follow symlink, count entries)
    local count
    count=$(ls "$HOME/.claude/skills/" | wc -l | tr -d ' ')
    [ "$count" -ge 10 ]
}

# --- Single skill ---

@test "install single skill by name" {
    run bash "$INSTALL_SCRIPT" skippy
    assert_success
    [ -d "$HOME/.claude/skills/skippy" ] || [ -L "$HOME/.claude/skills/skippy" ]
}

# --- Idempotent ---

@test "install is idempotent" {
    bash "$INSTALL_SCRIPT" --core
    [ -d "$HOME/.claude/skills/core" ] || [ -L "$HOME/.claude/skills/core" ]
    # Second install should succeed (UPDATE path)
    run bash "$INSTALL_SCRIPT" --core
    assert_success
    [ -d "$HOME/.claude/skills/core" ] || [ -L "$HOME/.claude/skills/core" ]
}

# --- Error: nonexistent skill ---

@test "install fails for nonexistent skill" {
    run bash "$INSTALL_SCRIPT" nonexistent-skill-xyz
    assert_failure
}

# --- Error: path traversal ---

@test "install rejects path traversal" {
    run bash "$INSTALL_SCRIPT" "../etc"
    assert_failure
    assert_output --partial "Invalid"
}

# --- Legacy target ---

@test "install --target=commands uses legacy path" {
    # Only skippy has a commands/ subdirectory -- core would SKIP (no commands/)
    run bash "$INSTALL_SCRIPT" skippy --target=commands
    assert_success
    [ -d "$HOME/.claude/commands/skippy" ] || [ -L "$HOME/.claude/commands/skippy" ]
}
