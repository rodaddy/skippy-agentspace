#!/usr/bin/env bash
set -euo pipefail

# skippy-cleanup -- Manage ephemeral files (debug, telemetry, history, logs)
# Usage: skippy-cleanup.sh [--quarantine|--nuke]
#   --quarantine (default): Move to quarantine directory
#   --nuke: Delete permanently

MODE="${1:---quarantine}"
QUARANTINE_BASE="${SKIPPY_QUARANTINE_DIR:-${TMPDIR:-/tmp}/skippy-cleanup}"
QUARANTINE_DIR="${QUARANTINE_BASE}/$(date +%Y-%m-%d_%H%M%S)"
TOTAL_FREED=0

# Ephemeral directories to clean
TARGETS=(
    "$HOME/.claude/debug"
    "$HOME/.claude/telemetry"
    "$HOME/.config/pai/history"
    "$HOME/.config/pai/logs"
)

echo "=== skippy-cleanup ($MODE) ==="
echo ""

for target in "${TARGETS[@]}"; do
    if [[ ! -d "$target" ]]; then
        echo "  SKIP: $target (not found)"
        continue
    fi

    # Calculate size
    size_bytes=$(du -sk "$target" 2>/dev/null | awk '{print $1}')
    size_human=$(du -sh "$target" 2>/dev/null | awk '{print $1}')

    if [[ "$size_bytes" -eq 0 ]]; then
        echo "  SKIP: $target (empty)"
        continue
    fi

    TOTAL_FREED=$((TOTAL_FREED + size_bytes))

    case "$MODE" in
        --quarantine)
            mkdir -p "$QUARANTINE_DIR"
            # Preserve directory structure in quarantine
            dest="$QUARANTINE_DIR/$(echo "$target" | sed "s|$HOME/||" | tr '/' '_')"
            mv "$target" "$dest"
            mkdir -p "$target"  # Recreate empty dir
            echo "  MOVED: $target ($size_human) -> $dest"
            ;;
        --nuke)
            rm -rf "$target"
            mkdir -p "$target"  # Recreate empty dir
            echo "  NUKED: $target ($size_human)"
            ;;
        *)
            echo "ERROR: Unknown mode '$MODE'. Use --quarantine or --nuke."
            exit 1
            ;;
    esac
done

echo ""

# Convert KB to human-readable
if [[ "$TOTAL_FREED" -gt 1048576 ]]; then
    freed_human="$((TOTAL_FREED / 1048576)) GB"
elif [[ "$TOTAL_FREED" -gt 1024 ]]; then
    freed_human="$((TOTAL_FREED / 1024)) MB"
else
    freed_human="${TOTAL_FREED} KB"
fi

echo "=== Total freed: $freed_human ==="

if [[ "$MODE" == "--quarantine" && "$TOTAL_FREED" -gt 0 ]]; then
    echo "Quarantined to: $QUARANTINE_DIR"
    echo "Delete quarantine when satisfied: rm -rf $QUARANTINE_DIR"
fi
