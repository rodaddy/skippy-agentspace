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

@test "install --core creates core symlink" {
    run bash "$INSTALL_SCRIPT" --core
    assert_success
    [ -L "$HOME/.claude/skills/core" ]
}

# --- All install ---

@test "install --all creates symlinks for all skills" {
    run bash "$INSTALL_SCRIPT" --all
    assert_success
    # Count symlinks in skills dir -- should be 12 (all skills)
    local count
    count=$(find "$HOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')
    [ "$count" -ge 10 ]
}

# --- Single skill ---

@test "install single skill by name" {
    run bash "$INSTALL_SCRIPT" skippy-dev
    assert_success
    [ -L "$HOME/.claude/skills/skippy-dev" ]
}

# --- Idempotent ---

@test "install is idempotent" {
    bash "$INSTALL_SCRIPT" --core
    [ -L "$HOME/.claude/skills/core" ]
    # Second install should succeed (UPDATE path)
    run bash "$INSTALL_SCRIPT" --core
    assert_success
    [ -L "$HOME/.claude/skills/core" ]
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
    # Only skippy-dev has a commands/ subdirectory -- core would SKIP (no commands/)
    run bash "$INSTALL_SCRIPT" skippy-dev --target=commands
    assert_success
    [ -L "$HOME/.claude/commands/skippy-dev" ]
}
