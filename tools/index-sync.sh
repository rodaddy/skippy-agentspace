#!/usr/bin/env bash
set -euo pipefail

# index-sync -- Validate or regenerate INDEX.md from skills/*/SKILL.md frontmatter
# Usage: index-sync.sh [--check|--generate]

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$REPO_ROOT/INDEX.md"
SKILLS_DIR="$REPO_ROOT/skills"
MODE="${1:---check}"

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
        done

        # Check for INDEX entries with no matching directory
        # Extract skill names from INDEX.md table rows (pipe-delimited)
        grep "^\| " "$INDEX_FILE" 2>/dev/null | grep -v "^\| Skill" | grep -v "^\|---" | while IFS='|' read -r _ name _rest; do
            name="$(echo "$name" | xargs)"  # trim whitespace
            if [[ -n "$name" && ! -d "$SKILLS_DIR/$name" ]]; then
                echo "  ORPHAN: $name in INDEX.md but no directory"
                errors=$((errors + 1))
            fi
        done

        if [[ "$errors" -eq 0 ]]; then
            echo "=== All skills indexed ==="
        else
            echo "=== $errors issues found. Run --generate to rebuild. ==="
            exit 1
        fi
        ;;

    --generate)
        echo "=== Index Sync: Generating ==="

        # Header
        cat > "$INDEX_FILE" <<'HEADER'
# Skill Index

Auto-generated from `skills/*/SKILL.md` frontmatter. Run `tools/index-sync.sh --generate` to rebuild.

**Base path:** `skills/`

HEADER

        current_section=""

        for skill_dir in "$SKILLS_DIR"/*/; do
            skill_name="$(basename "$skill_dir")"
            skill_file="$skill_dir/SKILL.md"

            if [[ ! -f "$skill_file" ]]; then
                continue
            fi

            # Extract frontmatter fields
            description="$(sed -n '/^description:/s/^description: *//p' "$skill_file" | head -1)"

            # Extract triggers (lines starting with "  - /" after "triggers:")
            commands="$(sed -n '/^triggers:/,/^[^ -]/{ /^  - \//s/^  - //p }' "$skill_file" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"

            # List reference files
            refs=""
            if [[ -d "$skill_dir/references" ]]; then
                refs="$(ls "$skill_dir/references/" 2>/dev/null | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
            fi

            echo "| $skill_name | \`$skill_name/SKILL.md\` | $commands | $refs | $description |"
        done >> "$INDEX_FILE"

        # Wrap in table
        # We need to add the table header before the rows
        # Read back, insert header, rewrite
        tmp="$(mktemp)"
        head -6 "$INDEX_FILE" > "$tmp"
        echo "| Skill | Path | Commands | References | Use When |" >> "$tmp"
        echo "|-------|------|----------|------------|----------|" >> "$tmp"
        tail -n +7 "$INDEX_FILE" >> "$tmp"
        mv "$tmp" "$INDEX_FILE"

        echo "=== INDEX.md regenerated with $(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ') skills ==="
        ;;

    *)
        echo "Usage: index-sync.sh [--check|--generate]"
        exit 1
        ;;
esac
