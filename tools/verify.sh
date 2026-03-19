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

# Source shared library with graceful fallback
_COMMON_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    SKIPPY_PASS=${SKIPPY_PASS:-0}; SKIPPY_WARN=${SKIPPY_WARN:-0}; SKIPPY_FAIL=${SKIPPY_FAIL:-0}
    skippy_repo_root() { local d; d="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"; [[ -d "$d/skills" ]] && echo "$d" && return 0; [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]] && echo "$SKIPPY_ROOT" && return 0; return 1; }
    skippy_pass() { printf '  \033[32m✓\033[0m %s\n' "${1:?requires message}"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn() { printf '  \033[33m⚠\033[0m %s\n' "${1:?requires message}"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail() { printf '  \033[31m✗\033[0m %s\n' "${1:?requires message}"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_suggest() { printf '  \033[36m💡\033[0m %s\n' "${1:?requires message}"; }
    skippy_section() { printf '\n=== %s ===\n\n' "${1:?requires section name}"; }
    skippy_summary() { printf '\n%d passed, %d warnings, %d failures\n' "$SKIPPY_PASS" "$SKIPPY_WARN" "$SKIPPY_FAIL"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
    skippy_is_installed() { [[ -L "$HOME/.claude/skills/${1:?}" ]] || [[ -L "$HOME/.claude/commands/${1:?}" ]]; }
fi

REPO_ROOT="$(skippy_repo_root)"
SKILLS_DIR="$REPO_ROOT/skills"

# ---------------------------------------------------------------------------
# Category 1: Prerequisites
# ---------------------------------------------------------------------------

skippy_section "Prerequisites"

# bun
if command -v bun >/dev/null 2>&1; then
    skippy_pass "bun $(bun --version)"
else
    skippy_fail "bun not found"
    skippy_suggest "macOS: brew install oven-sh/bun/bun | Linux: curl -fsSL https://bun.sh/install | bash"
fi

# jq
if command -v jq >/dev/null 2>&1; then
    skippy_pass "jq $(jq --version)"
else
    skippy_fail "jq not found"
    skippy_suggest "Install via your package manager (brew/apt/dnf/pacman)"
fi

# git
if command -v git >/dev/null 2>&1; then
    skippy_pass "git $(git --version | cut -d' ' -f3)"
else
    skippy_fail "git not found"
    skippy_suggest "Install via your package manager (brew/apt/dnf/pacman)"
fi

# bash 4+ (check PATH bash, not running shell)
bash_path="$(command -v bash 2>/dev/null || true)"
if [ -n "$bash_path" ]; then
    bash_version_str="$("$bash_path" -c 'echo $BASH_VERSION')"
    bash_major="$(echo "$bash_version_str" | cut -d. -f1)"
    if [ "$bash_major" -ge 4 ] 2>/dev/null; then
        skippy_pass "bash $bash_version_str ($bash_path)"
    else
        skippy_warn "bash $bash_version_str is outdated (need 4+)"
        skippy_suggest "macOS: brew install bash | Linux: install via package manager"
    fi
else
    skippy_fail "bash not found in PATH"
    skippy_suggest "Install bash via your package manager"
fi

echo ""

# ---------------------------------------------------------------------------
# Category 2: Skills
# ---------------------------------------------------------------------------

skippy_section "Skills"

PAI_SKILLS_DIR="${PAI_SKILLS_DIR:-$HOME/.config/pai/Skills}"

for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"

    # Check for install in: SAS symlink, PAI Skills, or legacy commands
    modern_link="$HOME/.claude/skills/$name"
    legacy_link="$HOME/.claude/commands/$name"
    pai_dir="$PAI_SKILLS_DIR/$name"
    found_at=""

    if [ -L "$modern_link" ] && [ -e "$modern_link" ]; then
        found_at="$modern_link (SAS symlink)"
    elif [ -L "$pai_dir" ] && [ -e "$pai_dir" ]; then
        found_at="$pai_dir (PAI symlink)"
    elif [ -d "$pai_dir" ] && [ -f "$pai_dir/SKILL.md" ]; then
        found_at="$pai_dir (PAI installed)"
    elif [ -L "$legacy_link" ] && [ -e "$legacy_link" ]; then
        found_at="$legacy_link (legacy)"
    fi

    if [ -n "$found_at" ]; then
        skippy_pass "$name (installed at $found_at)"
    elif [ -L "$modern_link" ] && [ ! -e "$modern_link" ]; then
        skippy_fail "$name symlink is dangling: $modern_link"
        skippy_suggest "Re-run tools/install.sh $name"
    else
        # Not installed anywhere
        if [ "$name" = "core" ]; then
            skippy_fail "core skill not installed (core is essential)"
            skippy_suggest "Run: tools/install.sh --core"
        else
            skippy_warn "$name not installed"
            skippy_suggest "Run: tools/install.sh $name"
        fi
    fi
done

echo ""

# ---------------------------------------------------------------------------
# Category 3: Hooks
# ---------------------------------------------------------------------------

skippy_section "Hooks"

# Delegate structural checks to validate-hooks.sh
validate_script="$REPO_ROOT/tools/validate-hooks.sh"
if [ -f "$validate_script" ]; then
    if bash "$validate_script" >/dev/null 2>&1; then
        skippy_pass "hook structure validation (validate-hooks.sh)"
    else
        skippy_fail "hook structure validation failed"
        skippy_suggest "Run: bash tools/validate-hooks.sh for details"
    fi
else
    skippy_warn "validate-hooks.sh not found -- skipping structural checks"
fi

# Check hook registrations in settings.json
settings_file="$HOME/.claude/settings.json"
if [ -f "$settings_file" ]; then
    if command -v bun >/dev/null 2>&1; then
        # Derive expected hook count from manifest instead of hardcoding
        manifest_file="$REPO_ROOT/skills/core/hooks/manifest.json"
        if [ -f "$manifest_file" ]; then
            expected_hooks="$(MANIFEST="$manifest_file" bun -e "const m = JSON.parse(require('fs').readFileSync(process.env.MANIFEST,'utf-8')); console.log(m.hooks.length)" 2>/dev/null || echo "0")"
        else
            expected_hooks="0"
            skippy_warn "hooks manifest not found at $manifest_file"
        fi

        pai_hook_count="$(SETTINGS="$settings_file" bun -e "
            const fs = require('fs');
            const s = JSON.parse(fs.readFileSync(process.env.SETTINGS, 'utf-8'));
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
            skippy_pass "all $expected_hooks PAI hooks registered in settings.json"
        elif [ "$pai_hook_count" = "0" ]; then
            skippy_warn "no PAI hooks found in settings.json"
            skippy_suggest "Run: bash skills/core/hooks/install-hooks.sh"
        else
            skippy_warn "partial PAI hook registration ($pai_hook_count/$expected_hooks)"
            skippy_suggest "Re-run: bash skills/core/hooks/install-hooks.sh"
        fi
    else
        skippy_warn "bun not available -- cannot check hook registrations"
    fi
else
    skippy_warn "$HOME/.claude/settings.json not found"
    skippy_suggest "Run: bash skills/core/hooks/install-hooks.sh"
fi

echo ""

# ---------------------------------------------------------------------------
# Category 4: Commands
# ---------------------------------------------------------------------------

skippy_section "Commands"

# Check skippy skill accessibility
skippy_dev_dir="$SKILLS_DIR/skippy"
if [ -d "$skippy_dev_dir" ]; then
    # Check each expected command file
    for cmd_name in reconcile update cleanup migrate upgrade review; do
        cmd_file="$skippy_dev_dir/commands/${cmd_name}.md"
        if [ -f "$cmd_file" ]; then
            skippy_pass "command: /skippy:${cmd_name}"
        else
            skippy_warn "command file missing: skippy/commands/${cmd_name}.md"
        fi
    done

    # Check if skippy is installed (accessible via symlink)
    if [ -L "$HOME/.claude/skills/skippy" ] || [ -L "$HOME/.claude/commands/skippy" ]; then
        skippy_pass "skippy skill installed (commands accessible)"
    else
        skippy_warn "skippy skill not installed -- commands won't appear in Claude Code"
        skippy_suggest "Run: tools/install.sh skippy"
    fi
else
    skippy_warn "skippy skill directory not found"
fi

echo ""

# ---------------------------------------------------------------------------
# Additional check: INDEX.md consistency
# ---------------------------------------------------------------------------

skippy_section "Index"

index_sync_script="$REPO_ROOT/tools/index-sync.sh"
if [ -f "$index_sync_script" ]; then
    if bash "$index_sync_script" --check >/dev/null 2>&1; then
        skippy_pass "INDEX.md is consistent with skills/"
    else
        skippy_warn "INDEX.md is out of sync"
        skippy_suggest "Run: bash tools/index-sync.sh --generate"
    fi
else
    skippy_warn "index-sync.sh not found -- skipping index check"
fi

echo ""

# ---------------------------------------------------------------------------
# Category 5: Open Brain Integration
# ---------------------------------------------------------------------------

skippy_section "Open Brain Integration"

# Check OPEN_BRAIN_AGENT_TOKEN
if [ -n "${OPEN_BRAIN_AGENT_TOKEN:-}" ]; then
    skippy_pass "OPEN_BRAIN_AGENT_TOKEN is set"
else
    skippy_warn "OPEN_BRAIN_AGENT_TOKEN not set -- OB hooks will silently skip"
    skippy_suggest "Fetch from vaultwarden: mcp2cli vaultwarden-secrets get_credential --params '{\"query\": \"Open Brain\"}'"
    skippy_suggest "Add to ~/.zshrc or settings.json env block"
fi

# Check mcp2cli open-brain service
if command -v mcp2cli >/dev/null 2>&1; then
    if mcp2cli open-brain --help >/dev/null 2>&1; then
        skippy_pass "mcp2cli open-brain service configured"
    else
        skippy_warn "mcp2cli open-brain service not registered"
        skippy_suggest "Register in ~/.config/mcp2cli/services.json"
    fi
else
    skippy_warn "mcp2cli not found -- Open Brain CLI integration unavailable"
fi

# Check OB server reachability via mcp2cli (uses actual auth + transport)
if command -v mcp2cli >/dev/null 2>&1; then
    if mcp2cli open-brain search_brain --params '{"query": "test", "limit": 1}' >/dev/null 2>&1; then
        skippy_pass "Open Brain server reachable (via mcp2cli)"
    else
        skippy_warn "Open Brain server not responding via mcp2cli"
        skippy_suggest "Check LXC 208 is running: ssh root@10.71.20.15 systemctl status open-brain"
    fi
fi

# Check OB hooks registered in settings.json
if [ -f "$settings_file" ] && command -v bun >/dev/null 2>&1; then
    ob_hook_count="$(SETTINGS="$settings_file" bun -e "
        const fs = require('fs');
        const s = JSON.parse(fs.readFileSync(process.env.SETTINGS, 'utf-8'));
        let c = 0;
        for (const gs of Object.values(s.hooks || {})) {
            for (const g of gs) {
                for (const h of g.hooks || []) {
                    if ((h.command || '').includes('open-brain')) c++;
                }
            }
        }
        console.log(c);
    " 2>/dev/null || echo "0")"

    if [ "$ob_hook_count" -ge 3 ] 2>/dev/null; then
        skippy_pass "all 3 Open Brain hooks registered (SessionStart, PreCompact, SessionEnd)"
    elif [ "$ob_hook_count" = "0" ]; then
        skippy_fail "no Open Brain hooks in settings.json"
        skippy_suggest "Run: bash tools/setup-integrations.sh"
    else
        skippy_warn "partial OB hook registration ($ob_hook_count/3)"
        skippy_suggest "Run: bash tools/setup-integrations.sh"
    fi
fi

# Check PAI Skills symlinks (not copies)
for skill_name in session-wrap capture-session brain session-start; do
    pai_skill="$HOME/.config/pai/Skills/$skill_name"
    if [ -L "$pai_skill" ]; then
        skippy_pass "PAI Skills/$skill_name is symlink (source of truth: SAS)"
    elif [ -d "$pai_skill" ]; then
        skippy_warn "PAI Skills/$skill_name is a copy (should be symlink to SAS)"
        skippy_suggest "Replace with: ln -sfn $SKILLS_DIR/$skill_name $pai_skill"
    fi
done

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

skippy_section "Summary"
skippy_summary
