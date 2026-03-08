#!/usr/bin/env bash
set -euo pipefail

# bump-version.sh -- Atomically bump version across all version locations in the repo.
#
# Usage:
#   bash tools/bump-version.sh --patch|--minor|--major [--dry-run]
#
# Canonical version source: .claude-plugin/marketplace.json metadata.version
# Targets:
#   - .claude-plugin/marketplace.json  (13 version fields -- 1 metadata + 12 plugins)
#   - skills/*/SKILL.md                (12 files -- YAML frontmatter version)
#   - skills/skippy-dev/commands/migrate.md  (1 template instruction)
#
# Exit codes:
#   0 - All locations updated (or dry run completed)
#   1 - Error or old version references remain after bump

# ---------------------------------------------------------------------------
# Setup -- source shared library with graceful fallback
# ---------------------------------------------------------------------------

_COMMON_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    # Canonical fallback stubs (use $0 for path derivation per project gotcha #6)
    SKIPPY_PASS=${SKIPPY_PASS:-0}; SKIPPY_WARN=${SKIPPY_WARN:-0}; SKIPPY_FAIL=${SKIPPY_FAIL:-0}
    skippy_repo_root() { local d; d="$(cd "$(dirname "$0")/.." && pwd)"; [[ -d "$d/skills" ]] && echo "$d" && return 0; [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]] && echo "$SKIPPY_ROOT" && return 0; return 1; }
    skippy_pass() { printf '  \033[32m✓\033[0m %s\n' "${1:?requires message}"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn() { printf '  \033[33m⚠\033[0m %s\n' "${1:?requires message}"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail() { printf '  \033[31m✗\033[0m %s\n' "${1:?requires message}"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_section() { printf '\n=== %s ===\n\n' "${1:?requires section name}"; }
    skippy_summary() { printf '\n%d passed, %d warnings, %d failures\n' "$SKIPPY_PASS" "$SKIPPY_WARN" "$SKIPPY_FAIL"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
fi

# ---------------------------------------------------------------------------
# Portable sed -i (GNU vs BSD)
# ---------------------------------------------------------------------------

_sed_inplace() {
    if sed --version 2>/dev/null | grep -q 'GNU sed'; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: bump-version.sh --patch|--minor|--major [--dry-run]"
    echo ""
    echo "Options:"
    echo "  --patch     Bump patch version (0.1.0 -> 0.1.1)"
    echo "  --minor     Bump minor version (0.1.0 -> 0.2.0)"
    echo "  --major     Bump major version (0.1.0 -> 1.0.0)"
    echo "  --dry-run   Show what would change without modifying files"
    exit 1
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

DRY_RUN=false
BUMP_TYPE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --patch)   BUMP_TYPE="patch"; shift ;;
        --minor)   BUMP_TYPE="minor"; shift ;;
        --major)   BUMP_TYPE="major"; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *)         usage ;;
    esac
done

[[ -z "$BUMP_TYPE" ]] && usage

# ---------------------------------------------------------------------------
# Read canonical version from marketplace.json
# ---------------------------------------------------------------------------

REPO_ROOT="$(skippy_repo_root)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

if [[ ! -f "$MARKETPLACE" ]]; then
    echo "ERROR: marketplace.json not found at $MARKETPLACE" >&2
    exit 1
fi

CURRENT=$(jq -r '.metadata.version' "$MARKETPLACE")

# Validate semver format N.N.N
if [[ ! "$CURRENT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid version format in marketplace.json: '$CURRENT'" >&2
    echo "  Expected semver format: N.N.N (e.g., 0.1.0)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Compute new version
# ---------------------------------------------------------------------------

IFS='.' read -r major minor patch <<< "$CURRENT"
case "$BUMP_TYPE" in
    patch) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
esac
NEW="$major.$minor.$patch"

echo "Version bump: $CURRENT -> $NEW ($BUMP_TYPE)"

# ---------------------------------------------------------------------------
# Collect target files
# ---------------------------------------------------------------------------

FILES=()
FILES+=("$MARKETPLACE")

for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] && FILES+=("$skill_md")
done

MIGRATE_MD="$REPO_ROOT/skills/skippy-dev/commands/migrate.md"
[[ -f "$MIGRATE_MD" ]] && FILES+=("$MIGRATE_MD")

# ---------------------------------------------------------------------------
# Dry-run mode
# ---------------------------------------------------------------------------

if $DRY_RUN; then
    echo ""
    echo "Files that would change:"
    for f in "${FILES[@]}"; do
        echo "  ${f#"$REPO_ROOT"/}"
    done
    echo ""
    echo "No files modified (dry run)."
    exit 0
fi

# ---------------------------------------------------------------------------
# Execute bump
# ---------------------------------------------------------------------------

# 1. marketplace.json -- update all version fields via jq (temp file + mv)
jq --arg v "$NEW" '(.metadata.version = $v) | (.plugins[].version = $v)' \
    "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"

# 2. SKILL.md files -- update YAML frontmatter version (two-space indent anchor)
for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] && _sed_inplace "s/  version: $CURRENT/  version: $NEW/" "$skill_md"
done

# 3. migrate.md -- update template instruction version (no indent anchor)
if [[ -f "$MIGRATE_MD" ]]; then
    _sed_inplace "s/version: $CURRENT/version: $NEW/" "$MIGRATE_MD"
fi

# ---------------------------------------------------------------------------
# Verify -- count remaining old version references in production files
# ---------------------------------------------------------------------------

skippy_section "Version Bump"

# Build grep target list (marketplace dir + individual SKILL.md files + migrate.md)
GREP_TARGETS=("$REPO_ROOT/.claude-plugin/")
for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] && GREP_TARGETS+=("$skill_md")
done
[[ -f "$MIGRATE_MD" ]] && GREP_TARGETS+=("$MIGRATE_MD")

REMAINING=$( (grep -rF "$CURRENT" "${GREP_TARGETS[@]}" 2>/dev/null || true) | wc -l | tr -d ' ')

if [[ "$REMAINING" -eq 0 ]]; then
    skippy_pass "All ${#FILES[@]} locations updated: $CURRENT -> $NEW"
else
    skippy_fail "$REMAINING old version references remain"
    # Show what's left for debugging
    grep -rF "$CURRENT" "${GREP_TARGETS[@]}" 2>/dev/null || true
fi

skippy_summary
