#!/usr/bin/env bash
set -euo pipefail

# verify.sh - Reusable health check for the PAI installation (brew doctor style)
#
# Usage:
#   bash tools/verify.sh       # Run all health checks
#
# Categories:
#   1. Prerequisites   - Required tools (bun, jq, git, bash 4+)
#   2. Skills          - Symlink status for each skill
#   3. Hooks           - Hook system integrity and registration
#   4. Commands        - Skippy-dev command accessibility
#
# Exit codes:
#   0 - All checks passed (or warnings only)
#   1 - One or more failures detected

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { echo "  WARN: $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "  FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
suggest() { echo "    Fix: $1"; }

# ---------------------------------------------------------------------------
# Category 1: Prerequisites
# ---------------------------------------------------------------------------

echo "=== Prerequisites ==="

# bun
if command -v bun >/dev/null 2>&1; then
    pass "bun $(bun --version)"
else
    fail "bun not found"
    suggest "macOS: brew install oven-sh/bun/bun | Linux: curl -fsSL https://bun.sh/install | bash"
fi

# jq
if command -v jq >/dev/null 2>&1; then
    pass "jq $(jq --version)"
else
    fail "jq not found"
    suggest "Install via your package manager (brew/apt/dnf/pacman)"
fi

# git
if command -v git >/dev/null 2>&1; then
    pass "git $(git --version | cut -d' ' -f3)"
else
    fail "git not found"
    suggest "Install via your package manager (brew/apt/dnf/pacman)"
fi

# bash 4+ (check PATH bash, not running shell)
bash_path="$(command -v bash 2>/dev/null || true)"
if [ -n "$bash_path" ]; then
    bash_version_str="$("$bash_path" -c 'echo $BASH_VERSION')"
    bash_major="$(echo "$bash_version_str" | cut -d. -f1)"
    if [ "$bash_major" -ge 4 ] 2>/dev/null; then
        pass "bash $bash_version_str ($bash_path)"
    else
        warn "bash $bash_version_str is outdated (need 4+)"
        suggest "macOS: brew install bash | Linux: install via package manager"
    fi
else
    fail "bash not found in PATH"
    suggest "Install bash via your package manager"
fi

echo ""

# ---------------------------------------------------------------------------
# Category 2: Skills
# ---------------------------------------------------------------------------

echo "=== Skills ==="

for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"

    # Check for symlink in either modern or legacy location
    modern_link="$HOME/.claude/skills/$name"
    legacy_link="$HOME/.claude/commands/$name"
    found_link=""

    if [ -L "$modern_link" ]; then
        found_link="$modern_link"
    elif [ -L "$legacy_link" ]; then
        found_link="$legacy_link"
    fi

    if [ -n "$found_link" ]; then
        # Symlink exists -- verify target resolves
        if [ -e "$found_link" ]; then
            pass "$name (installed at $found_link)"
        else
            fail "$name symlink is dangling: $found_link"
            suggest "Re-run tools/install.sh $name"
        fi
    else
        # Not installed
        if [ "$name" = "core" ]; then
            fail "core skill not installed (core is essential)"
            suggest "Run: tools/install.sh --core"
        else
            warn "$name not installed"
            suggest "Run: tools/install.sh $name"
        fi
    fi
done

echo ""

# ---------------------------------------------------------------------------
# Category 3: Hooks
# ---------------------------------------------------------------------------

echo "=== Hooks ==="

# Delegate structural checks to validate-hooks.sh
validate_script="$REPO_ROOT/tools/validate-hooks.sh"
if [ -f "$validate_script" ]; then
    if bash "$validate_script" >/dev/null 2>&1; then
        pass "hook structure validation (validate-hooks.sh)"
    else
        fail "hook structure validation failed"
        suggest "Run: bash tools/validate-hooks.sh for details"
    fi
else
    warn "validate-hooks.sh not found -- skipping structural checks"
fi

# Check hook registrations in settings.json
settings_file="$HOME/.claude/settings.json"
if [ -f "$settings_file" ]; then
    if command -v bun >/dev/null 2>&1; then
        # Derive expected hook count from manifest instead of hardcoding
        manifest_file="$REPO_ROOT/skills/core/hooks/manifest.json"
        if [ -f "$manifest_file" ]; then
            expected_hooks="$(bun -e "const m = JSON.parse(require('fs').readFileSync('$manifest_file','utf-8')); console.log(m.hooks.length)" 2>/dev/null || echo "0")"
        else
            expected_hooks="0"
            warn "hooks manifest not found at $manifest_file"
        fi

        pai_hook_count="$(bun -e "
            const fs = require('fs');
            const s = JSON.parse(fs.readFileSync('$settings_file', 'utf-8'));
            let c = 0;
            for (const gs of Object.values(s.hooks || {})) {
                for (const g of gs) {
                    for (const h of g.hooks || []) {
                        if ((h.command || '').includes('skills/core/hooks/')) c++;
                    }
                }
            }
            console.log(c);
        " 2>/dev/null || echo "0")"

        if [ "$pai_hook_count" = "$expected_hooks" ] && [ "$expected_hooks" != "0" ]; then
            pass "all $expected_hooks PAI hooks registered in settings.json"
        elif [ "$pai_hook_count" = "0" ]; then
            warn "no PAI hooks found in settings.json"
            suggest "Run: bash skills/core/hooks/install-hooks.sh"
        else
            warn "partial PAI hook registration ($pai_hook_count/$expected_hooks)"
            suggest "Re-run: bash skills/core/hooks/install-hooks.sh"
        fi
    else
        warn "bun not available -- cannot check hook registrations"
    fi
else
    warn "$HOME/.claude/settings.json not found"
    suggest "Run: bash skills/core/hooks/install-hooks.sh"
fi

echo ""

# ---------------------------------------------------------------------------
# Category 4: Commands
# ---------------------------------------------------------------------------

echo "=== Commands ==="

# Check skippy-dev skill accessibility
skippy_dev_dir="$SKILLS_DIR/skippy-dev"
if [ -d "$skippy_dev_dir" ]; then
    # Check each expected command file
    for cmd_name in reconcile update cleanup migrate upgrade; do
        cmd_file="$skippy_dev_dir/commands/${cmd_name}.md"
        if [ -f "$cmd_file" ]; then
            pass "command: /skippy:${cmd_name}"
        else
            warn "command file missing: skippy-dev/commands/${cmd_name}.md"
        fi
    done

    # Check if skippy-dev is installed (accessible via symlink)
    if [ -L "$HOME/.claude/skills/skippy-dev" ] || [ -L "$HOME/.claude/commands/skippy-dev" ]; then
        pass "skippy-dev skill installed (commands accessible)"
    else
        warn "skippy-dev skill not installed -- commands won't appear in Claude Code"
        suggest "Run: tools/install.sh skippy-dev"
    fi
else
    warn "skippy-dev skill directory not found"
fi

echo ""

# ---------------------------------------------------------------------------
# Additional check: INDEX.md consistency
# ---------------------------------------------------------------------------

echo "=== Index ==="

index_sync_script="$REPO_ROOT/tools/index-sync.sh"
if [ -f "$index_sync_script" ]; then
    if bash "$index_sync_script" --check >/dev/null 2>&1; then
        pass "INDEX.md is consistent with skills/"
    else
        warn "INDEX.md is out of sync"
        suggest "Run: bash tools/index-sync.sh --generate"
    fi
else
    warn "index-sync.sh not found -- skipping index check"
fi

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo "=== Summary ==="
echo "  $PASS_COUNT passed, $WARN_COUNT warnings, $FAIL_COUNT failures"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
