#!/usr/bin/env bats
# uninstall.bats -- Tests for tools/uninstall.sh
# Covers: no-args usage, single skill removal, --all safety, non-skippy preservation, error cases

setup() {
    load 'test_helper/common'
    _common_setup

    INSTALL_SCRIPT="$REPO_ROOT/tools/install.sh"
    UNINSTALL_SCRIPT="$REPO_ROOT/tools/uninstall.sh"

    # Pre-install core skill so most tests have something to uninstall
    bash "$INSTALL_SCRIPT" --core
}

# --- Usage display ---

@test "uninstall no args shows usage" {
    run bash "$UNINSTALL_SCRIPT"
    assert_success
    assert_output --partial "Usage"
}

# --- Single skill removal ---

@test "uninstall removes installed skill" {
    # core was installed in setup -- verify it exists
    [ -d "$HOME/.claude/skills/core" ] || [ -L "$HOME/.claude/skills/core" ]
    run bash "$UNINSTALL_SCRIPT" core
    assert_success
    # Skill should be gone
    [ ! -e "$HOME/.claude/skills/core" ]
}

# --- Uninstall --all removes skippy skills ---

@test "uninstall --all removes all skippy skills" {
    # Install all skills first
    bash "$INSTALL_SCRIPT" --all
    local before_count
    before_count=$(ls "$HOME/.claude/skills/" | wc -l | tr -d ' ')
    [ "$before_count" -ge 10 ]

    # Uninstall all -- pipe "n" to decline hook removal prompt
    run bash -c 'echo "n" | bash "'"$UNINSTALL_SCRIPT"'" --all'
    assert_success

    # All skippy skills should be gone
    local after_count
    after_count=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')
    [ "$after_count" -eq 0 ]
}

# --- CRITICAL SAFETY TEST: non-skippy symlinks preserved ---

@test "uninstall --all preserves non-skippy symlinks" {
    # Install all skippy skills
    bash "$INSTALL_SCRIPT" --all

    # Create a fake non-skippy symlink (simulates PAI or other project skills)
    ln -s /tmp/fake-other-project "$HOME/.claude/skills/other-project"

    # Verify both exist
    [ -d "$HOME/.claude/skills/core" ] || [ -L "$HOME/.claude/skills/core" ]
    [ -L "$HOME/.claude/skills/other-project" ]

    # Uninstall --all -- pipe "n" to decline hook removal prompt
    run bash -c 'echo "n" | bash "'"$UNINSTALL_SCRIPT"'" --all'
    assert_success

    # CRITICAL: non-skippy symlink MUST survive
    [ -L "$HOME/.claude/skills/other-project" ]

    # Skippy skills should be gone
    [ ! -e "$HOME/.claude/skills/core" ]
    [ ! -e "$HOME/.claude/skills/skippy" ]
}

# --- Error: not-installed skill ---

@test "uninstall fails for not-installed skill" {
    run bash "$UNINSTALL_SCRIPT" nonexistent-skill-xyz
    assert_failure
}

# --- Error: path traversal ---

@test "uninstall rejects path traversal" {
    run bash "$UNINSTALL_SCRIPT" "../etc"
    assert_failure
    assert_output --partial "Invalid"
}
