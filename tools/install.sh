#!/usr/bin/env bash
set -euo pipefail

# install -- Install a skill into Claude Code's command discovery
# Usage: install.sh <skill-name> | install.sh --all
#
# Creates symlink: ~/.claude/commands/<skill-name> -> <repo>/skills/<skill-name>/commands/
# If skill has no commands/ dir, only registers in AGENT-INDEX (no slash commands).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
COMMANDS_DIR="$HOME/.claude/commands"
SKILL_NAME="${1:-}"

install_skill() {
    local name="$1"
    local skill_dir="$SKILLS_DIR/$name"
    local commands_src="$skill_dir/commands"
    local commands_dest="$COMMANDS_DIR/$name"

    if [[ ! -d "$skill_dir" ]]; then
        echo "ERROR: Skill '$name' not found in $SKILLS_DIR/"
        return 1
    fi

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        echo "ERROR: $name/ has no SKILL.md"
        return 1
    fi

    # Symlink commands/ if it exists
    if [[ -d "$commands_src" ]]; then
        if [[ -L "$commands_dest" ]]; then
            echo "  UPDATE: $name (removing old symlink)"
            unlink "$commands_dest"
        elif [[ -d "$commands_dest" ]]; then
            echo "  WARN: $commands_dest exists as directory, skipping (remove manually)"
            return 1
        fi

        ln -s "$commands_src" "$commands_dest"
        echo "  INSTALLED: $name -> $commands_dest"
        echo "    Commands: $(ls "$commands_src"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')"
    else
        echo "  REGISTERED: $name (no commands/ -- skill loaded via SKILL.md only)"
    fi
}

case "${SKILL_NAME}" in
    --all)
        echo "=== Installing all skills ==="
        for skill_dir in "$SKILLS_DIR"/*/; do
            install_skill "$(basename "$skill_dir")"
        done
        echo "=== Done. Run /clear to refresh skill list. ==="
        ;;
    "")
        echo "Usage: install.sh <skill-name> | install.sh --all"
        echo ""
        echo "Available skills:"
        for skill_dir in "$SKILLS_DIR"/*/; do
            name="$(basename "$skill_dir")"
            desc="$(sed -n '/^description:/s/^description: *//p' "$skill_dir/SKILL.md" 2>/dev/null | head -1)"
            echo "  $name -- $desc"
        done
        ;;
    *)
        install_skill "$SKILL_NAME"
        echo "Run /clear to refresh skill list."
        ;;
esac
