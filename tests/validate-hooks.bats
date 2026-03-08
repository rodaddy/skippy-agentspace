#!/usr/bin/env bats
# validate-hooks.bats -- Tests for tools/validate-hooks.sh
# Covers: quick mode checks (manifest, file existence, structure, shared lib)

setup() {
    load 'test_helper/common'
    _common_setup

    VALIDATE_SCRIPT="$REPO_ROOT/tools/validate-hooks.sh"
}

# --- Quick mode ---

@test "validate-hooks quick mode succeeds" {
    run bash "$VALIDATE_SCRIPT"
    assert_success
}

@test "validate-hooks checks manifest" {
    run bash "$VALIDATE_SCRIPT"
    assert_output --partial "manifest"
}

@test "validate-hooks checks hook file existence" {
    run bash "$VALIDATE_SCRIPT"
    assert_output --partial "hook scripts exist"
}

@test "validate-hooks checks shared lib" {
    run bash "$VALIDATE_SCRIPT"
    assert_output --partial "shared lib"
}
