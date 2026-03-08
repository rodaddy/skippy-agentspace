#!/usr/bin/env bash
# uninstall-hooks.sh - Remove PAI LAW enforcement hooks from Claude Code settings.json
#
# Usage:
#   bash skills/core/hooks/uninstall-hooks.sh [--settings=PATH]
#
# Options:
#   --settings=PATH     Override settings.json location (default: ~/.claude/settings.json)
#
# Safety: Only removes hooks matching BOTH:
#   1. Command path contains "skills/core/hooks/" (identifier)
#   2. Script name matches an entry in manifest.json (cross-reference)
#
# Prerequisites:
#   - bun (required)

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

SETTINGS_PATH="${HOME}/.claude/settings.json"

for arg in "$@"; do
  case "$arg" in
    --settings=*)
      SETTINGS_PATH="${arg#--settings=}"
      ;;
    --help|-h)
      head -16 "$0" | tail -14
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash uninstall-hooks.sh [--settings=PATH]"
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate prerequisites
# ---------------------------------------------------------------------------

if ! command -v bun >/dev/null 2>&1; then
  echo "ERROR: bun is required but not found."
  echo "Install: curl -fsSL https://bun.sh/install | bash"
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR"
MANIFEST="$SCRIPT_DIR/manifest.json"
MERGE_SCRIPT="$SCRIPT_DIR/lib/merge.ts"

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: manifest.json not found at $MANIFEST"
  exit 1
fi

if [ ! -f "$MERGE_SCRIPT" ]; then
  echo "ERROR: lib/merge.ts not found at $MERGE_SCRIPT"
  exit 1
fi

# ---------------------------------------------------------------------------
# Validate settings.json exists
# ---------------------------------------------------------------------------

if [ ! -f "$SETTINGS_PATH" ]; then
  echo "ERROR: settings.json not found at $SETTINGS_PATH"
  echo "Nothing to uninstall."
  exit 1
fi

# ---------------------------------------------------------------------------
# Backup before removal (HOOK-05)
# ---------------------------------------------------------------------------

BACKUP_PATH="${SETTINGS_PATH}.backup-$(date +%Y-%m-%d-%H%M%S)"
cp "$SETTINGS_PATH" "$BACKUP_PATH"
echo "Backup created: $BACKUP_PATH"

# ---------------------------------------------------------------------------
# Remove hooks
# ---------------------------------------------------------------------------

bun run "$MERGE_SCRIPT" remove "$SETTINGS_PATH" "$MANIFEST" "$HOOKS_DIR"
echo "Uninstallation complete."
