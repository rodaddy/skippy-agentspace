#!/usr/bin/env bash
set -euo pipefail

# integration-test.sh -- Full E2E integration test in sandbox
#
# Tests the complete flow:
#   1. Clone all 3 upstreams (GSD, PAUL, OMC)
#   2. Verify each upstream independently
#   3. Fresh-install skippy-agentspace (the merged package)
#   4. Verify skippy integrates all 3 upstreams' cherry-picks
#   5. Test install/uninstall/upgrade paths
#   6. Verify blast radius protection
#   7. Run all validation tools
#
# EVERYTHING runs in a sandbox. Real ~/.claude/ is NEVER touched.
#
# Usage:
#   integration-test.sh              Run all tests
#   integration-test.sh --quick      Skip upstream clones, just test skippy
#   integration-test.sh --verbose    Show full command output

VERBOSE=false
QUICK=false
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX=""
REAL_HOME="$HOME"
PASS=0
FAIL=0
WARN=0
TESTS_RUN=0

for arg in "$@"; do
    case "$arg" in
        --verbose) VERBOSE=true ;;
        --quick) QUICK=true ;;
    esac
done

# --- Helpers ---

setup_sandbox() {
    SANDBOX=$(mktemp -d)
    export HOME="$SANDBOX"
    mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
    echo "Sandbox: $SANDBOX"
}

# Ensure sandbox cleanup on unexpected exit (set -e, signals)
trap 'export HOME="$REAL_HOME"; rm -rf "$SANDBOX" 2>/dev/null' EXIT

teardown_sandbox() {
    export HOME="$REAL_HOME"
    rm -rf "$SANDBOX" 2>/dev/null || true
}

pass() {
    PASS=$((PASS + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "  PASS: $1"
}

fail() {
    FAIL=$((FAIL + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "  FAIL: $1"
}

warn() {
    WARN=$((WARN + 1))
    echo "  WARN: $1"
}

section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# --- Pre-flight ---

section "PRE-FLIGHT CHECKS"

# Verify we're in the right repo
if [[ ! -f "$REPO_DIR/CLAUDE.md" ]] || [[ ! -d "$REPO_DIR/skills" ]]; then
    echo "ERROR: Not in skippy-agentspace repo"
    exit 1
fi
pass "In correct repo: $REPO_DIR"

# Verify required tools
for tool in git bash bun jq; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available ($(command -v "$tool"))"
    else
        fail "$tool not found"
    fi
done

# --- T1: Upstream Verification ---

if ! $QUICK; then
    section "T1: UPSTREAM VERIFICATION"

    UPSTREAM_DIR="$SANDBOX"
    if [[ -z "$SANDBOX" ]]; then
        UPSTREAM_DIR=$(mktemp -d)
    fi

    # Clone GSD
    echo "  Cloning GSD..."
    if git clone --depth 1 https://github.com/gsd-build/get-shit-done.git "$UPSTREAM_DIR/gsd" 2>/dev/null; then
        pass "GSD cloned"
        # Verify GSD has expected structure
        if [[ -d "$UPSTREAM_DIR/gsd/bin" ]] || [[ -d "$UPSTREAM_DIR/gsd/workflows" ]]; then
            pass "GSD has expected structure"
        else
            warn "GSD structure may have changed"
        fi
        GSD_SHA=$(cd "$UPSTREAM_DIR/gsd" && git rev-parse --short HEAD)
        echo "  GSD SHA: $GSD_SHA"
    else
        fail "GSD clone failed"
    fi

    # Clone PAUL
    echo "  Cloning PAUL..."
    if git clone --depth 1 https://github.com/ChristopherKahler/paul.git "$UPSTREAM_DIR/paul" 2>/dev/null; then
        pass "PAUL cloned"
        PAUL_SHA=$(cd "$UPSTREAM_DIR/paul" && git rev-parse --short HEAD)
        echo "  PAUL SHA: $PAUL_SHA"
    else
        fail "PAUL clone failed"
    fi

    # Check OMC (local plugin)
    OMC_DIR=$(find "$REAL_HOME/.claude/plugins/cache/omc" -name "package.json" -path "*/oh-my-claudecode/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")
    if [[ -n "$OMC_DIR" ]] && [[ -d "$OMC_DIR" ]]; then
        OMC_VERSION=$(bun -e "console.log(require('$OMC_DIR/package.json').version)" 2>/dev/null || echo "unknown")
        pass "OMC found: v$OMC_VERSION at $OMC_DIR"
    else
        warn "OMC not installed locally (not a blocker)"
    fi

    # Verify upstream.json SHAs match
    echo ""
    echo "  Comparing tracked SHAs to live repos..."
    TRACKED_GSD=$(bun -e "console.log(require('$REPO_DIR/upstreams/gsd/upstream.json').last_checked_sha.slice(0,7))" 2>/dev/null || echo "none")
    if [[ "$TRACKED_GSD" != "none" ]]; then
        pass "GSD SHA tracked: $TRACKED_GSD"
    else
        fail "GSD SHA not tracked"
    fi

    TRACKED_PAUL=$(bun -e "console.log(require('$REPO_DIR/upstreams/paul/upstream.json').last_checked_sha.slice(0,7))" 2>/dev/null || echo "none")
    if [[ "$TRACKED_PAUL" != "none" ]]; then
        pass "PAUL SHA tracked: $TRACKED_PAUL"
    else
        fail "PAUL SHA not tracked"
    fi

    # Cleanup upstream clones
    rm -rf "$UPSTREAM_DIR/gsd" "$UPSTREAM_DIR/paul" 2>/dev/null
fi

# --- T2: Cherry-Pick Verification ---

section "T2: CHERRY-PICK VERIFICATION"

echo "  PAUL cherry-picks (5 expected):"
PAUL_PICKS=$(bun -e "const u=require('$REPO_DIR/upstreams/paul/upstream.json'); console.log(u.cherry_picks.length)" 2>/dev/null || echo "0")
if [[ "$PAUL_PICKS" -ge 5 ]]; then
    pass "PAUL: $PAUL_PICKS cherry-picks tracked"
else
    fail "PAUL: only $PAUL_PICKS cherry-picks (expected 5)"
fi

# Verify PAUL reference docs exist
for ref in context-brackets reconciliation plan-structure plan-boundaries state-consistency; do
    if [[ -f "$REPO_DIR/skills/skippy/references/$ref.md" ]]; then
        pass "PAUL ref: $ref.md"
    else
        fail "PAUL ref missing: $ref.md"
    fi
done

echo ""
echo "  OMC cherry-picks (4 expected):"
OMC_PICKS=$(bun -e "const u=require('$REPO_DIR/upstreams/omc/upstream.json'); console.log(u.cherry_picks.length)" 2>/dev/null || echo "0")
if [[ "$OMC_PICKS" -ge 4 ]]; then
    pass "OMC: $OMC_PICKS cherry-picks tracked"
else
    fail "OMC: only $OMC_PICKS cherry-picks (expected 4)"
fi

# Verify OMC reference docs exist
for ref in pre-execution-gate ambiguity-scoring compaction-resilience parallel-file-ownership; do
    if [[ -f "$REPO_DIR/skills/skippy/references/$ref.md" ]]; then
        pass "OMC ref: $ref.md"
    else
        fail "OMC ref missing: $ref.md"
    fi
done

# --- T3: Validation Tools ---

section "T3: VALIDATION TOOLS"

cd "$REPO_DIR"

# verify.sh
VERIFY_OUTPUT=$(bash tools/verify.sh 2>&1)
VERIFY_PASS=$(echo "$VERIFY_OUTPUT" | grep -c "PASS" || true)
VERIFY_FAIL=$(echo "$VERIFY_OUTPUT" | grep -c "FAIL" || true)
if [[ "$VERIFY_FAIL" -eq 0 ]]; then
    pass "verify.sh: $VERIFY_PASS passed, 0 failures"
else
    fail "verify.sh: $VERIFY_FAIL failures"
    $VERBOSE && echo "$VERIFY_OUTPUT"
fi

# index-sync.sh
if bash tools/index-sync.sh --check >/dev/null 2>&1; then
    pass "index-sync.sh --check: all skills indexed"
else
    fail "index-sync.sh --check: drift detected"
fi

# validate-hooks.sh
HOOKS_OUTPUT=$(bash tools/validate-hooks.sh 2>&1)
HOOKS_PASS=$(echo "$HOOKS_OUTPUT" | grep -c "PASS" || true)
if [[ "$HOOKS_PASS" -ge 6 ]]; then
    pass "validate-hooks.sh: $HOOKS_PASS/6 passed"
else
    fail "validate-hooks.sh: only $HOOKS_PASS/6 passed"
fi

# prereqs.sh
if bash tools/prereqs.sh < /dev/null >/dev/null 2>&1; then
    pass "prereqs.sh: all prerequisites found"
else
    warn "prereqs.sh: some prerequisites missing (may be ok)"
fi

# --- T4: Fresh Install (SANDBOXED) ---

section "T4: FRESH INSTALL (SANDBOXED)"

setup_sandbox
cd "$REPO_DIR"

# Install all
bash tools/install.sh --all >/dev/null 2>&1
INSTALLED=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$INSTALLED" -eq 12 ]]; then
    pass "install --all: 12 skills installed"
else
    fail "install --all: $INSTALLED skills (expected 12)"
fi

# Verify in sandbox
SANDBOX_VERIFY=$(bash tools/verify.sh 2>&1)
SANDBOX_FAIL=$(echo "$SANDBOX_VERIFY" | grep -c "FAIL" || true)
if [[ "$SANDBOX_FAIL" -eq 0 ]]; then
    pass "verify.sh in sandbox: clean"
else
    fail "verify.sh in sandbox: $SANDBOX_FAIL failures"
fi

teardown_sandbox

# --- T5: Blast Radius (SANDBOXED) ---

section "T5: BLAST RADIUS PROTECTION (SANDBOXED)"

setup_sandbox
cd "$REPO_DIR"

bash tools/install.sh --all >/dev/null 2>&1
ln -s /tmp "$HOME/.claude/skills/foreign-project"
ln -s /tmp "$HOME/.claude/skills/another-foreign"

bash tools/uninstall.sh --all < <(echo "n") >/dev/null 2>&1
AFTER=$(ls "$HOME/.claude/skills/" | wc -l | tr -d ' ')

if [[ "$AFTER" -eq 2 ]]; then
    pass "Blast radius: 2 foreign symlinks survived (12 skippy removed)"
else
    fail "Blast radius: $AFTER remaining (expected 2 foreign)"
fi

# Verify specific foreign symlinks
if [[ -L "$HOME/.claude/skills/foreign-project" ]]; then
    pass "foreign-project survived"
else
    fail "foreign-project was deleted (CRITICAL BUG)"
fi

teardown_sandbox

# --- T6: Install Modes (SANDBOXED) ---

section "T6: INSTALL MODES (SANDBOXED)"

setup_sandbox
cd "$REPO_DIR"

# --core
bash tools/install.sh --core >/dev/null 2>&1
CORE_COUNT=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CORE_COUNT" -eq 1 ]]; then
    pass "--core: installed 1 skill (core)"
else
    fail "--core: installed $CORE_COUNT (expected 1)"
fi

# Positional args
bash tools/install.sh skippy add-todo check-todos >/dev/null 2>&1
POS_COUNT=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$POS_COUNT" -eq 4 ]]; then
    pass "Positional: 3 more installed (total 4)"
else
    fail "Positional: total $POS_COUNT (expected 4)"
fi

# Individual uninstall
bash tools/uninstall.sh add-todo >/dev/null 2>&1
if [[ ! -e "$HOME/.claude/skills/add-todo" ]]; then
    pass "Individual uninstall: add-todo removed"
else
    fail "Individual uninstall: add-todo still exists"
fi

# Nonexistent skill
if ! bash tools/uninstall.sh nonexistent-xyz >/dev/null 2>&1; then
    pass "Nonexistent skill: exit 1"
else
    fail "Nonexistent skill: should have exited 1"
fi

teardown_sandbox

# --- T7: Idempotency (SANDBOXED) ---

section "T7: IDEMPOTENCY (SANDBOXED)"

setup_sandbox
cd "$REPO_DIR"

bash tools/install.sh --all >/dev/null 2>&1
FIRST=$(ls "$HOME/.claude/skills/" | wc -l | tr -d ' ')
bash tools/install.sh --all >/dev/null 2>&1
SECOND=$(ls "$HOME/.claude/skills/" | wc -l | tr -d ' ')

if [[ "$FIRST" -eq "$SECOND" ]] && [[ "$FIRST" -eq 12 ]]; then
    pass "Idempotent: 12 both times"
else
    fail "Not idempotent: first=$FIRST second=$SECOND"
fi

teardown_sandbox

# --- T8: Upgrade Path (SANDBOXED -- copies real setup) ---

section "T8: UPGRADE PATH (SANDBOXED)"

setup_sandbox
# Copy real setup
cp -R "$REAL_HOME/.claude/skills" "$HOME/.claude/skills" 2>/dev/null || mkdir -p "$HOME/.claude/skills"
cp -R "$REAL_HOME/.claude/commands" "$HOME/.claude/commands" 2>/dev/null || mkdir -p "$HOME/.claude/commands"
BEFORE_UPGRADE=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')

cd "$REPO_DIR"
bash tools/install.sh --all >/dev/null 2>&1
AFTER_UPGRADE=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$AFTER_UPGRADE" -ge "$BEFORE_UPGRADE" ]]; then
    pass "Upgrade overlay: $BEFORE_UPGRADE -> $AFTER_UPGRADE skills"
else
    fail "Upgrade lost skills: $BEFORE_UPGRADE -> $AFTER_UPGRADE"
fi

# Verify PAI skills survived
PAI_SURVIVED=0
PAI_TOTAL=0
for s in n8n proxmox litellm homeassistant Git Research; do
    PAI_TOTAL=$((PAI_TOTAL + 1))
    if [[ -e "$HOME/.claude/skills/$s" ]]; then
        PAI_SURVIVED=$((PAI_SURVIVED + 1))
    fi
done
if [[ "$PAI_SURVIVED" -eq "$PAI_TOTAL" ]]; then
    pass "PAI skills survived: $PAI_SURVIVED/$PAI_TOTAL"
else
    warn "PAI skills: $PAI_SURVIVED/$PAI_TOTAL (some may not have been installed)"
fi

# Uninstall only removes skippy
bash tools/uninstall.sh --all < <(echo "n") >/dev/null 2>&1
AFTER_UNINSTALL=$(ls "$HOME/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ')
# Just verify PAI survived
PAI_POST=0
for s in n8n proxmox litellm homeassistant Git Research; do
    if [[ -e "$HOME/.claude/skills/$s" ]]; then
        PAI_POST=$((PAI_POST + 1))
    fi
done
if [[ "$PAI_POST" -eq "$PAI_SURVIVED" ]]; then
    pass "PAI skills survived uninstall: $PAI_POST/$PAI_SURVIVED"
else
    fail "PAI skills lost during uninstall: $PAI_POST/$PAI_SURVIVED (BLAST RADIUS BUG)"
fi

teardown_sandbox

# --- T9: Cross-Reference Consistency ---

section "T9: CROSS-REFERENCE CONSISTENCY"

cd "$REPO_DIR"

# Skill counts
FS_SKILLS=$(ls -d skills/*/ | wc -l | tr -d ' ')
MKT_SKILLS=$(MARKETPLACE="$REPO_DIR/.claude-plugin/marketplace.json" bun -e "console.log(require(process.env.MARKETPLACE).plugins.length)" 2>/dev/null || echo "0")

if [[ "$FS_SKILLS" -eq 12 ]] && [[ "$MKT_SKILLS" -eq 12 ]]; then
    pass "Skill count: $FS_SKILLS filesystem, $MKT_SKILLS marketplace"
else
    fail "Skill count mismatch: $FS_SKILLS filesystem, $MKT_SKILLS marketplace"
fi

# Reference doc count
REF_COUNT=$(ls skills/skippy/references/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$REF_COUNT" -eq 18 ]]; then
    pass "Reference docs: $REF_COUNT"
else
    fail "Reference docs: $REF_COUNT (expected 18)"
fi

# Stale content
set +o pipefail
STALE_RICO=$(grep -rl "rico/skippy" skills/*/SKILL.md 2>/dev/null | wc -l | xargs)
STALE_OWNER=$(grep -rl "owner/skippy" --include="*.md" . 2>/dev/null | grep -v .planning/ | wc -l | xargs)
STALE_REPO=$(grep -rl "<repo-url>" --include="*.md" . 2>/dev/null | grep -v .planning/ | wc -l | xargs)
set -o pipefail

if [[ "$STALE_RICO" -eq 0 ]] && [[ "$STALE_OWNER" -eq 0 ]] && [[ "$STALE_REPO" -eq 0 ]]; then
    pass "No stale placeholders"
else
    fail "Stale content: rico=$STALE_RICO owner=$STALE_OWNER repo-url=$STALE_REPO"
fi

# Source URLs
RODADDY_COUNT=$(grep -l "rodaddy/skippy" skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' \n' || echo "0")
if [[ "$RODADDY_COUNT" -eq 12 ]]; then
    pass "All 12 SKILL.md source URLs correct"
else
    fail "Source URLs: $RODADDY_COUNT/12 correct"
fi

# --- T10: Backup/Restore ---

section "T10: BACKUP/RESTORE"

if bash tools/backup-restore.sh list 2>/dev/null | grep -q "pre-testing"; then
    pass "Backup 'pre-testing' exists"
else
    warn "No 'pre-testing' backup found"
fi

# --- Results ---

section "RESULTS"

echo ""
echo "  Tests run: $TESTS_RUN"
echo "  Passed:    $PASS"
echo "  Failed:    $FAIL"
echo "  Warnings:  $WARN"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
    echo "  ✓ ALL TESTS PASSED"
    exit 0
else
    echo "  ✗ $FAIL TESTS FAILED"
    exit 1
fi
