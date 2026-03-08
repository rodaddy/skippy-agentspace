#!/usr/bin/env bats
# index-sync.bats -- Tests for tools/index-sync.sh
# Covers: --check mode, --generate mode, invalid arguments, category sections

setup() {
    load 'test_helper/common'
    _common_setup

    # Create a sandboxed repo structure so we never touch real INDEX.md.
    # Copy the script INTO the sandbox so BASH_SOURCE resolves to sandbox root.
    SANDBOX_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$SANDBOX_REPO/tools/lib"
    mkdir -p "$SANDBOX_REPO/skills"

    # Copy tool scripts
    cp "$REPO_ROOT/tools/index-sync.sh" "$SANDBOX_REPO/tools/"
    cp "$REPO_ROOT/tools/lib/common.sh" "$SANDBOX_REPO/tools/lib/"

    # Copy skills directory structure (dirs with SKILL.md for detection)
    for skill_dir in "$REPO_ROOT"/skills/*/; do
        skill_name="$(basename "$skill_dir")"
        mkdir -p "$SANDBOX_REPO/skills/$skill_name"
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            cp "$skill_dir/SKILL.md" "$SANDBOX_REPO/skills/$skill_name/"
        fi
    done

    # Copy current INDEX.md as baseline
    cp "$REPO_ROOT/INDEX.md" "$SANDBOX_REPO/INDEX.md"

    INDEX_SCRIPT="$SANDBOX_REPO/tools/index-sync.sh"
}

# --- Check mode ---

@test "index-sync --check passes with current INDEX.md" {
    run bash "$INDEX_SCRIPT" --check
    assert_success
}

@test "index-sync --check detects missing skill in INDEX.md" {
    # Create an empty INDEX.md so no skills are found
    echo "# Empty Index" > "$SANDBOX_REPO/INDEX.md"
    run bash "$INDEX_SCRIPT" --check
    assert_failure
}

# --- Generate mode ---

@test "index-sync --generate creates INDEX.md with category sections" {
    # Remove INDEX.md, then regenerate
    rm -f "$SANDBOX_REPO/INDEX.md"
    run bash "$INDEX_SCRIPT" --generate
    assert_success

    # Verify file was recreated with category headers
    [[ -f "$SANDBOX_REPO/INDEX.md" ]]
    run cat "$SANDBOX_REPO/INDEX.md"
    assert_output --partial "Core"
    assert_output --partial "Workflow"
}

@test "index-sync --generate includes all skills from skills/ directory" {
    run bash "$INDEX_SCRIPT" --generate
    assert_success

    # Check that generated INDEX.md mentions key skills
    run cat "$SANDBOX_REPO/INDEX.md"
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
