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

# Source shared library with graceful fallback
_COMMON_SH="$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    # Fallback: define all stubs when common.sh is missing
    SKIPPY_PASS=${SKIPPY_PASS:-0}; SKIPPY_WARN=${SKIPPY_WARN:-0}; SKIPPY_FAIL=${SKIPPY_FAIL:-0}
    skippy_repo_root() { local d; d="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"; [[ -d "$d/skills" ]] && echo "$d" && return 0; [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]] && echo "$SKIPPY_ROOT" && return 0; return 1; }
    skippy_pass() { printf '  \033[32m✓\033[0m %s\n' "${1:?requires message}"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn() { printf '  \033[33m⚠\033[0m %s\n' "${1:?requires message}"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail() { printf '  \033[31m✗\033[0m %s\n' "${1:?requires message}"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_suggest() { printf '  \033[36m💡\033[0m %s\n' "${1:?requires message}"; }
    skippy_section() { printf '\n=== %s ===\n\n' "${1:?requires section name}"; }
    skippy_summary() { printf '\n%d passed, %d warnings, %d failures\n' "$SKIPPY_PASS" "$SKIPPY_WARN" "$SKIPPY_FAIL"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
    skippy_is_installed() { [[ -d "$HOME/.claude/skills/${1:?}" ]] || [[ -d "$HOME/.claude/commands/${1:?}" ]] || [[ -d "${PAI_SKILLS_DIR:-$HOME/.config/pai/Skills}/${1:?}" ]]; }
    skippy_validate_skill_name() { local n="$1"; [[ -z "$n" ]] && { echo "Error: Skill name cannot be empty" >&2; return 1; }; ! [[ "$n" =~ ^[a-zA-Z0-9_-]+$ ]] && { echo "Error: Invalid skill name '$n'" >&2; return 1; }; return 0; }
fi

REPO_ROOT="$(skippy_repo_root)"
SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"
PAI_DIR="${PAI_SKILLS_DIR:-$HOME/.config/pai/Skills}"

list_installed() {
    local found=0

    if [[ -d "$SKILLS_DIR" ]]; then
        for entry in "$SKILLS_DIR"/*/; do
            entry="${entry%/}"
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            if [[ -L "$entry" ]]; then
                found=1
                echo "  $name -> $(readlink "$entry")  [skills/symlink]"
            elif [[ -d "$entry" && -f "$entry/SKILL.md" ]]; then
                found=1
                echo "  $name  [skills/copied]"
            fi
        done
    fi

    if [[ -d "$COMMANDS_DIR" ]]; then
        for entry in "$COMMANDS_DIR"/*/; do
            entry="${entry%/}"
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            if [[ -L "$entry" ]]; then
                found=1
                echo "  $name -> $(readlink "$entry")  [commands/symlink]"
            elif [[ -d "$entry" && -f "$entry/SKILL.md" ]]; then
                found=1
                echo "  $name  [commands/copied]"
            fi
        done
    fi

    # Also check PAI directory (where install.sh copies to)
    if [[ -d "$PAI_DIR" ]]; then
        for entry in "$PAI_DIR"/*/; do
            entry="${entry%/}"
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            # Only list if this skill exists in our repo
            if [[ -d "$REPO_ROOT/skills/$name" && -d "$entry" && -f "$entry/SKILL.md" ]]; then
                found=1
                echo "  $name  [pai/copied]"
            fi
        done
    fi

    if [[ "$found" -eq 0 ]]; then
        echo "  (none found)"
    fi
}

uninstall_skill() {
    local name="$1"
    validate_skill_name "$name" || return 1
    local removed=0

    # Check modern target: ~/.claude/skills/<name>
    local skills_path="$SKILLS_DIR/$name"
    if [[ -L "$skills_path" ]]; then
        unlink "$skills_path"
        echo "  REMOVED: $name symlink from $SKILLS_DIR/"
        removed=$((removed + 1))
    elif [[ -d "$skills_path" && -f "$skills_path/SKILL.md" ]]; then
        rm -rf "$skills_path"
        echo "  REMOVED: $name directory from $SKILLS_DIR/"
        removed=$((removed + 1))
    fi

    # Check legacy target: ~/.claude/commands/<name>
    local commands_path="$COMMANDS_DIR/$name"
    if [[ -L "$commands_path" ]]; then
        unlink "$commands_path"
        echo "  REMOVED: $name symlink from $COMMANDS_DIR/"
        removed=$((removed + 1))
    elif [[ -d "$commands_path" && -f "$commands_path/SKILL.md" ]]; then
        rm -rf "$commands_path"
        echo "  REMOVED: $name directory from $COMMANDS_DIR/"
        removed=$((removed + 1))
    fi

    # Check PAI target: ~/.config/pai/Skills/<name>
    local pai_path="$PAI_DIR/$name"
    if [[ -d "$pai_path" && -f "$pai_path/SKILL.md" ]]; then
        # Safety: only remove if this skill exists in our repo
        if [[ -d "$REPO_ROOT/skills/$name" ]]; then
            rm -rf "$pai_path"
            echo "  REMOVED: $name directory from $PAI_DIR/"
            removed=$((removed + 1))
        else
            echo "  WARN: $pai_path exists but '$name' not in repo -- skipping for safety"
        fi
    fi

    if [[ "$removed" -eq 0 ]]; then
        echo "  WARN: $name not found in any target directory -- nothing to uninstall"
        return 1
    fi

    return 0
}

# --- Input validation ---

# validate_skill_name delegates to common.sh skippy_validate_skill_name
validate_skill_name() { skippy_validate_skill_name "$@"; }

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
            echo "  uninstall.sh skippy               Uninstall one skill"
            echo "  uninstall.sh skippy excalidraw    Uninstall multiple skills"
            echo "  uninstall.sh --all                    Uninstall everything"
            echo ""
            echo "Installed skills:"
            list_installed
            exit 0
            ;;
        *)
            validate_skill_name "$arg" || exit 1
            SKILL_NAMES+=("$arg")
            ;;
    esac
done

# --- Main ---

if [[ "$UNINSTALL_ALL" == true ]]; then
    echo "=== Uninstalling all skippy-agentspace skills ==="
    found_any=0

    # Iterate over skills in our repo and remove matching installations
    # This handles BOTH symlinks and copied directories safely
    REPO_SKILLS_DIR="$REPO_ROOT/skills"

    for skill_dir in "$REPO_SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local_name="$(basename "$skill_dir")"

        # Check all target locations for this skill
        for target_dir in "$SKILLS_DIR" "$COMMANDS_DIR" "$PAI_DIR"; do
            [[ -d "$target_dir" ]] || continue
            target_path="$target_dir/$local_name"

            if [[ -L "$target_path" ]]; then
                # Symlink -- only remove if it points into our repo
                link_target="$(readlink "$target_path")"
                if [[ "$link_target" == "$REPO_SKILLS_DIR"/* ]]; then
                    unlink "$target_path"
                    echo "  REMOVED: $local_name symlink from $target_dir/"
                    found_any=1
                fi
            elif [[ -d "$target_path" && -f "$target_path/SKILL.md" ]]; then
                # Copied directory -- safe to remove since the skill exists in our repo
                rm -rf "$target_path"
                echo "  REMOVED: $local_name directory from $target_dir/"
                found_any=1
            fi
        done
    done

    if [[ "$found_any" -eq 0 ]]; then
        echo "  WARN: No installed skills found -- nothing to uninstall"
    fi

    # --- Hook cleanup ---
    # After removing all skills, offer to remove PAI hooks from settings.json
    SETTINGS_FILE="$HOME/.claude/settings.json"
    if [[ -f "$SETTINGS_FILE" ]] && grep -q 'skills/core/hooks/' "$SETTINGS_FILE" 2>/dev/null; then
        echo ""
        echo "PAI hooks detected in $SETTINGS_FILE."
        if [[ -t 0 ]]; then
            # Interactive terminal -- ask the user
            read -r -p "Also remove PAI hooks from settings.json? (y/n) " answer || answer="n"
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                HOOK_UNINSTALLER="$REPO_ROOT/skills/core/hooks/uninstall-hooks.sh"
                if [[ -f "$HOOK_UNINSTALLER" ]]; then
                    bash "$HOOK_UNINSTALLER"
                else
                    echo "  WARN: Hook uninstaller not found at $HOOK_UNINSTALLER"
                    echo "  Manual removal: edit $SETTINGS_FILE and remove entries containing 'skills/core/hooks/'"
                fi
            else
                echo "  Skipped hook removal. Hooks remain in $SETTINGS_FILE."
            fi
        else
            # Non-interactive -- skip the prompt
            echo "  INFO: Non-interactive mode. Skipping hook removal prompt."
            echo "  To remove hooks: edit $SETTINGS_FILE and remove entries containing 'skills/core/hooks/'"
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
