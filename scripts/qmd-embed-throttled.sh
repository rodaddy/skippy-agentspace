#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.config/pai/logs/qmd-embed.log"
QMD="$HOME/Library/Application Support/reflex/bun/bin/qmd"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting throttled embed" >> "$LOG"

# Update index first (pick up new/changed files)
"$QMD" update >> "$LOG" 2>&1

# Check how many need embedding
PENDING=$("$QMD" status 2>/dev/null | grep -o '[0-9]* need embedding' | grep -o '[0-9]*' || echo "0")

if [ "$PENDING" = "0" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nothing to embed" >> "$LOG"
  exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] $PENDING chunks need embedding" >> "$LOG"

# Run embed at lowest priority
nice -n 19 "$QMD" embed >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Embed complete" >> "$LOG"
