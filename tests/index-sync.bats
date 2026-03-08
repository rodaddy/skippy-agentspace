#!/usr/bin/env bats
# index-sync.bats -- Tests for tools/index-sync.sh
# Covers: --check mode, --generate mode, invalid arguments, category sections

setup() {
    load 'test_helper/common'
    _common_setup

    INDEX_SCRIPT="$REPO_ROOT/tools/index-sync.sh"

    # Backup INDEX.md so --generate tests don't corrupt the real file
    cp "$REPO_ROOT/INDEX.md" "$BATS_TEST_TMPDIR/INDEX.md.bak"
}

teardown() {
    # Restore original INDEX.md after every test
    if [[ -f "$BATS_TEST_TMPDIR/INDEX.md.bak" ]]; then
        cp "$BATS_TEST_TMPDIR/INDEX.md.bak" "$REPO_ROOT/INDEX.md"
    fi
}

# --- Check mode ---

@test "index-sync --check passes with current INDEX.md" {
    run bash "$INDEX_SCRIPT" --check
    assert_success
}

@test "index-sync --check detects missing skill in INDEX.md" {
    # Create an empty INDEX.md so no skills are found
    echo "# Empty Index" > "$REPO_ROOT/INDEX.md"
    run bash "$INDEX_SCRIPT" --check
    assert_failure
}

# --- Generate mode ---

@test "index-sync --generate creates INDEX.md with category sections" {
    # Remove INDEX.md, then regenerate
    rm -f "$REPO_ROOT/INDEX.md"
    run bash "$INDEX_SCRIPT" --generate
    assert_success

    # Verify file was recreated with category headers
    [[ -f "$REPO_ROOT/INDEX.md" ]]
    run cat "$REPO_ROOT/INDEX.md"
    assert_output --partial "Core"
    assert_output --partial "Workflow"
}

@test "index-sync --generate includes all skills from skills/ directory" {
    run bash "$INDEX_SCRIPT" --generate
    assert_success

    # Check that generated INDEX.md mentions key skills
    run cat "$REPO_ROOT/INDEX.md"
    assert_output --partial "core"
    assert_output --partial "skippy-dev"
    assert_output --partial "browser"
}

# --- Invalid arguments ---

@test "index-sync invalid mode shows usage and exits 1" {
    run bash "$INDEX_SCRIPT" --invalid
    assert_failure
    assert_output --partial "Usage"
}
