#!/usr/bin/env bash
set -euo pipefail

# uninstall -- Remove skill symlinks from Claude Code discovery paths
#
# Usage:
#   uninstall.sh                            Show usage and installed skills
#   uninstall.sh <skill-name> [skill...]    Uninstall one or more skills
#   uninstall.sh --all                      Uninstall all symlinked skills
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
        return 1
    fi

    return 0
}

# --- Argument parsing ---

SKILL_NAMES=()
UNINSTALL_ALL=false

for arg in "$@"; do
    case "$arg" in
        --all)
            UNINSTALL_ALL=true
            ;;
        -h|--help)
            echo "Usage: uninstall.sh <skill-name> [skill-name...]"
            echo "       uninstall.sh --all"
            echo ""
            echo "Modes:"
            echo "  (no args)            Show usage and list installed skills"
            echo "  <skill> [skill...]   Uninstall one or more skills by name"
            echo "  --all                Uninstall all symlinked skills"
            echo ""
            echo "Examples:"
            echo "  uninstall.sh skippy-dev               Uninstall one skill"
            echo "  uninstall.sh skippy-dev excalidraw    Uninstall multiple skills"
            echo "  uninstall.sh --all                    Uninstall everything"
            echo ""
            echo "Installed skills:"
            list_installed
            exit 0
            ;;
        *)
            SKILL_NAMES+=("$arg")
            ;;
    esac
done

# --- Main ---

if [[ "$UNINSTALL_ALL" == true ]]; then
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

    # --- Hook cleanup ---
    # After removing all skills, offer to remove PAI hooks from settings.json
    SETTINGS_FILE="$HOME/.claude/settings.json"
    if [[ -f "$SETTINGS_FILE" ]] && grep -q 'skills/core/hooks/' "$SETTINGS_FILE" 2>/dev/null; then
        echo ""
        echo "PAI hooks detected in $SETTINGS_FILE."
        read -r -p "Also remove PAI hooks from settings.json? (y/n) " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            HOOK_UNINSTALLER="$(cd "$(dirname "$0")/.." && pwd)/skills/core/hooks/uninstall-hooks.sh"
            if [[ -f "$HOOK_UNINSTALLER" ]]; then
                bash "$HOOK_UNINSTALLER"
            else
                echo "  WARN: Hook uninstaller not found at $HOOK_UNINSTALLER"
                echo "  Manual removal: edit $SETTINGS_FILE and remove entries containing 'skills/core/hooks/'"
            fi
        else
            echo "  Skipped hook removal. Hooks remain in $SETTINGS_FILE."
        fi
    fi

    echo "=== Done. Run /clear to refresh skill list. ==="
elif [[ ${#SKILL_NAMES[@]} -gt 0 ]]; then
    echo "=== Uninstalling ${#SKILL_NAMES[@]} skill(s) ==="
    failed=0
    succeeded=0
    for name in "${SKILL_NAMES[@]}"; do
        if uninstall_skill "$name"; then
            succeeded=$((succeeded + 1))
        else
            failed=$((failed + 1))
        fi
    done
    echo "=== Done: $succeeded removed, $failed not found. Run /clear to refresh skill list. ==="
    if [[ "$failed" -gt 0 ]]; then
        exit 1
    fi
else
    echo "Usage: uninstall.sh <skill-name> [skill-name...]"
    echo "       uninstall.sh --all"
    echo ""
    echo "Installed skills (symlinked):"
    list_installed
fi
