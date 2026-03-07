#!/usr/bin/env bash
set -euo pipefail

# uninstall -- Remove a skill's symlink from Claude Code command discovery
# Usage: uninstall.sh <skill-name>
#
# Only removes the symlink. Does NOT delete the skill source files.

COMMANDS_DIR="$HOME/.claude/commands"
SKILL_NAME="${1:-}"

if [[ -z "$SKILL_NAME" ]]; then
    echo "Usage: uninstall.sh <skill-name>"
    echo ""
    echo "Installed skills (symlinked):"
    for link in "$COMMANDS_DIR"/*/; do
        if [[ -L "${link%/}" ]]; then
            name="$(basename "$link")"
            target="$(readlink "${link%/}")"
            echo "  $name -> $target"
        fi
    done
    exit 0
fi

COMMANDS_DEST="$COMMANDS_DIR/$SKILL_NAME"

if [[ -L "$COMMANDS_DEST" ]]; then
    unlink "$COMMANDS_DEST"
    echo "UNINSTALLED: $SKILL_NAME (symlink removed)"
    echo "Source files are untouched. Run /clear to refresh skill list."
elif [[ -d "$COMMANDS_DEST" ]]; then
    echo "ERROR: $COMMANDS_DEST is a directory, not a symlink. Remove manually if intended."
    exit 1
else
    echo "NOT INSTALLED: $SKILL_NAME (no symlink found at $COMMANDS_DEST)"
    exit 1
fi
