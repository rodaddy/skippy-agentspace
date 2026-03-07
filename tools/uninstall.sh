#!/usr/bin/env bash
set -euo pipefail

# uninstall -- Remove skill symlinks from Claude Code discovery paths
# Usage: uninstall.sh <skill-name> | uninstall.sh --all
#
# Checks both modern (~/.claude/skills/) and legacy (~/.claude/commands/) targets.
# Removes from whichever locations have symlinks. Source files are untouched.

SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"

list_installed() {
    local found=0

    if [[ -d "$SKILLS_DIR" ]]; then
        for link in "$SKILLS_DIR"/*/; do
            link="${link%/}"
            if [[ -L "$link" ]]; then
                found=1
                echo "  $(basename "$link") -> $(readlink "$link")  [skills]"
            fi
        done
    fi

    if [[ -d "$COMMANDS_DIR" ]]; then
        for link in "$COMMANDS_DIR"/*/; do
            link="${link%/}"
            if [[ -L "$link" ]]; then
                found=1
                echo "  $(basename "$link") -> $(readlink "$link")  [commands]"
            fi
        done
    fi

    if [[ "$found" -eq 0 ]]; then
        echo "  (none found)"
    fi
}

uninstall_skill() {
    local name="$1"
    local removed=0

    # Check modern target: ~/.claude/skills/<name>
    local skills_link="$SKILLS_DIR/$name"
    if [[ -L "$skills_link" ]]; then
        unlink "$skills_link"
        echo "  REMOVED: $name from $SKILLS_DIR/"
        removed=$((removed + 1))
    elif [[ -d "$skills_link" ]]; then
        echo "  WARN: $skills_link is a directory, not a symlink -- skipping (remove manually)"
    fi

    # Check legacy target: ~/.claude/commands/<name>
    local commands_link="$COMMANDS_DIR/$name"
    if [[ -L "$commands_link" ]]; then
        unlink "$commands_link"
        echo "  REMOVED: $name from $COMMANDS_DIR/"
        removed=$((removed + 1))
    elif [[ -d "$commands_link" ]]; then
        echo "  WARN: $commands_link is a directory, not a symlink -- skipping (remove manually)"
    fi

    if [[ "$removed" -eq 0 ]]; then
        echo "  WARN: $name not found in $SKILLS_DIR/ or $COMMANDS_DIR/ -- nothing to uninstall"
    fi

    return 0
}

case "${1:-}" in
    --all)
        echo "=== Uninstalling all symlinked skills ==="
        found_any=0

        if [[ -d "$SKILLS_DIR" ]]; then
            for link in "$SKILLS_DIR"/*/; do
                link="${link%/}"
                if [[ -L "$link" ]]; then
                    found_any=1
                    uninstall_skill "$(basename "$link")"
                fi
            done
        fi

        if [[ -d "$COMMANDS_DIR" ]]; then
            for link in "$COMMANDS_DIR"/*/; do
                link="${link%/}"
                if [[ -L "$link" ]]; then
                    found_any=1
                    uninstall_skill "$(basename "$link")"
                fi
            done
        fi

        if [[ "$found_any" -eq 0 ]]; then
            echo "  WARN: No symlinked skills found -- nothing to uninstall"
        fi

        echo "=== Done. Run /clear to refresh skill list. ==="
        ;;
    "")
        echo "Usage: uninstall.sh <skill-name> | uninstall.sh --all"
        echo ""
        echo "Installed skills (symlinked):"
        list_installed
        ;;
    *)
        echo "=== Uninstalling: $1 ==="
        uninstall_skill "$1"
        echo "Source files are untouched. Run /clear to refresh skill list."
        ;;
esac
