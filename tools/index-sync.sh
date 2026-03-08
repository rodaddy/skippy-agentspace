#!/usr/bin/env bash
set -euo pipefail

# index-sync -- Validate or regenerate INDEX.md from skills/*/SKILL.md frontmatter
# Usage: index-sync.sh [--check|--generate]

# Source shared library with graceful fallback
_COMMON_SH="$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    # Fallback: define minimal stubs (only repo_root and is_installed needed)
    skippy_repo_root() { local r; r="$(cd "$(dirname "$0")/.." && pwd)"; echo "$r"; }
    skippy_is_installed() { [[ -L "$HOME/.claude/skills/$1" ]] || [[ -L "$HOME/.claude/commands/$1" ]]; }
fi

REPO_ROOT="$(skippy_repo_root)"
INDEX_FILE="$REPO_ROOT/INDEX.md"
SKILLS_DIR="$REPO_ROOT/skills"
MODE="${1:---check}"

# Known category display order
CATEGORY_ORDER=("core" "workflow" "utility" "domain")

# Capitalize first letter for section headers
capitalize() {
    local word="$1"
    echo "$(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')${word:1}"
}

# Extract category from SKILL.md frontmatter
get_category() {
    local skill_file="$1"
    local cat
    cat="$(sed -n '/^  category:/s/^  category: *//p' "$skill_file" | head -1 | tr -d '[:space:]')"
    echo "${cat:-uncategorized}"
}

case "$MODE" in
    --check)
        echo "=== Index Sync: Checking ==="
        errors=0

        # Scan each skill directory for SKILL.md
        for skill_dir in "$SKILLS_DIR"/*/; do
            skill_name="$(basename "$skill_dir")"
            skill_file="$skill_dir/SKILL.md"

            if [[ ! -f "$skill_file" ]]; then
                echo "  WARN: $skill_name/ has no SKILL.md"
                continue
            fi

            # Check if skill is in INDEX.md
            if ! grep -q "$skill_name" "$INDEX_FILE" 2>/dev/null; then
                echo "  MISSING: $skill_name not in INDEX.md"
                errors=$((errors + 1))
            else
                echo "  OK: $skill_name"
            fi

            # Check for category field (informational, non-fatal)
            category="$(get_category "$skill_file")"
            if [[ "$category" == "uncategorized" ]]; then
                echo "  INFO: $skill_name has no category in frontmatter"
            fi
        done

        # Check for INDEX entries with no matching directory
        # Extract skill names from INDEX.md table rows (pipe-delimited)
        # Skip non-skill rows: table headers, separators, and badge legend entries
        while IFS='|' read -r _ name _rest; do
            # Strip badges and whitespace from name
            name="$(echo "$name" | sed 's/\[installed\]//' | xargs)"
            # Skip empty names, table headers/separators, and badge legend rows
            if [[ -z "$name" ]]; then
                continue
            fi
            case "$name" in
                Badge|Standalone|"Needs bun"|"Needs infra"|---*|"**"*)
                    continue
                    ;;
            esac
            if [[ ! -d "$SKILLS_DIR/$name" ]]; then
                echo "  ORPHAN: $name in INDEX.md but no directory"
                errors=$((errors + 1))
            fi
        done < <(grep "^| " "$INDEX_FILE" 2>/dev/null | grep -v "^| Skill" | grep -v "^|---")

        if [[ "$errors" -eq 0 ]]; then
            echo "=== All skills indexed ==="
        else
            echo "=== $errors issues found. Run --generate to rebuild. ==="
            exit 1
        fi
        ;;

    --generate)
        echo "=== Index Sync: Generating ==="

        # Collect skill data grouped by category
        # Use temp files per category since bash associative arrays can't hold multiline values portably
        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT

        # Track which categories we find
        found_categories=()

        for skill_dir in "$SKILLS_DIR"/*/; do
            skill_name="$(basename "$skill_dir")"
            skill_file="$skill_dir/SKILL.md"

            if [[ ! -f "$skill_file" ]]; then
                continue
            fi

            # Extract fields
            category="$(get_category "$skill_file")"

            # Extract commands from commands/*.md frontmatter (name: field)
            commands=""
            if [[ -d "$skill_dir/commands" ]]; then
                commands="$(for cmd_file in "$skill_dir"/commands/*.md; do
                    [[ -f "$cmd_file" ]] || continue
                    sed -n '/^name:/s/^name: *//p' "$cmd_file" | head -1
                done | sed 's/^/\//' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
            fi
            if [[ -z "$commands" ]]; then
                commands="(none)"
            fi

            # Build display name with install badge
            display_name="$skill_name"
            if skippy_is_installed "$skill_name"; then
                display_name="$skill_name [installed]"
            fi

            # Track category
            if [[ ! -f "$tmpdir/$category" ]]; then
                found_categories+=("$category")
                touch "$tmpdir/$category"
            fi

            # Append row to category file
            echo "| $display_name | \`$skill_name/SKILL.md\` | $commands |" >> "$tmpdir/$category"
        done

        # Build INDEX.md
        cat > "$INDEX_FILE" <<'HEADER'
# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

HEADER

        # Output categories in defined order first, then any extras
        outputted=()

        for cat in "${CATEGORY_ORDER[@]}"; do
            if [[ -f "$tmpdir/$cat" ]]; then
                section_name="$(capitalize "$cat")"
                echo "## $section_name" >> "$INDEX_FILE"
                echo "" >> "$INDEX_FILE"
                echo "| Skill | Path | Commands |" >> "$INDEX_FILE"
                echo "|-------|------|----------|" >> "$INDEX_FILE"
                cat "$tmpdir/$cat" >> "$INDEX_FILE"
                echo "" >> "$INDEX_FILE"
                outputted+=("$cat")
            fi
        done

        # Output any categories not in the predefined order
        for cat in "${found_categories[@]}"; do
            skip=false
            for done_cat in "${outputted[@]}"; do
                if [[ "$cat" == "$done_cat" ]]; then
                    skip=true
                    break
                fi
            done
            if [[ "$skip" == "false" ]]; then
                section_name="$(capitalize "$cat")"
                echo "## $section_name" >> "$INDEX_FILE"
                echo "" >> "$INDEX_FILE"
                echo "| Skill | Path | Commands |" >> "$INDEX_FILE"
                echo "|-------|------|----------|" >> "$INDEX_FILE"
                cat "$tmpdir/$cat" >> "$INDEX_FILE"
                echo "" >> "$INDEX_FILE"
            fi
        done

        # Append Plugin Distribution footer
        cat >> "$INDEX_FILE" <<'FOOTER'
## Plugin Distribution

This repo is also a Claude Code plugin marketplace. Install via:

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Plugin manifest: `.claude-plugin/marketplace.json` (strict: false -- no plugin.json needed).

Manual install still supported via `tools/install.sh` (dual-target: `~/.claude/skills/` or `~/.claude/commands/`).
FOOTER

        echo "=== INDEX.md regenerated with $(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ') skills ==="
        ;;

    *)
        echo "Usage: index-sync.sh [--check|--generate]"
        exit 1
        ;;
esac
