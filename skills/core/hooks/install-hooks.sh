#!/usr/bin/env bash
# install-hooks.sh - Install PAI LAW enforcement hooks into Claude Code settings.json
#
# Usage:
#   bash skills/core/hooks/install-hooks.sh [--dry-run] [--settings=PATH]
#
# Options:
#   --dry-run           Show what would change without writing
#   --settings=PATH     Override settings.json location (default: ~/.claude/settings.json)
#
# Prerequisites:
#   - bun (required -- all hook scripts use #!/usr/bin/env bun)

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

DRY_RUN=false
SETTINGS_PATH="${HOME}/.claude/settings.json"

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --settings=*)
      SETTINGS_PATH="${arg#--settings=}"
      ;;
    --help|-h)
      head -14 "$0" | tail -12
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash install-hooks.sh [--dry-run] [--settings=PATH]"
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
# Ensure settings.json exists
# ---------------------------------------------------------------------------

if [ ! -f "$SETTINGS_PATH" ]; then
  echo "Creating new settings.json at $SETTINGS_PATH"
  mkdir -p "$(dirname "$SETTINGS_PATH")"
  echo '{}' > "$SETTINGS_PATH"
  BACKUP_SKIPPED=true
else
  BACKUP_SKIPPED=false
fi

# ---------------------------------------------------------------------------
# Backup (HOOK-05)
# ---------------------------------------------------------------------------

if [ "$BACKUP_SKIPPED" = false ]; then
  BACKUP_PATH="${SETTINGS_PATH}.backup-$(date +%Y-%m-%d-%H%M%S)"
  cp "$SETTINGS_PATH" "$BACKUP_PATH"
  echo "Backup created: $BACKUP_PATH"
fi

# ---------------------------------------------------------------------------
# Merge hooks
# ---------------------------------------------------------------------------

if [ "$DRY_RUN" = true ]; then
  # Dry run: work on a temp copy, show diff
  TEMP_SETTINGS="$(mktemp)"
  cp "$SETTINGS_PATH" "$TEMP_SETTINGS"
  bun run "$MERGE_SCRIPT" merge "$TEMP_SETTINGS" "$MANIFEST" "$HOOKS_DIR"
  echo ""
  echo "--- Dry run diff ---"
  diff "$SETTINGS_PATH" "$TEMP_SETTINGS" || true
  rm -f "$TEMP_SETTINGS"
  echo ""
  echo "No changes written (dry run)."
else
  bun run "$MERGE_SCRIPT" merge "$SETTINGS_PATH" "$MANIFEST" "$HOOKS_DIR"
  echo "Installation complete."
fi
