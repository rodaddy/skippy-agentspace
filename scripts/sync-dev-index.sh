#!/usr/bin/env bash
set -euo pipefail

DEST="user@<NAS_IP>:/mnt/big_pool/dev-index"
EXCLUDES="$HOME/.config/pai/rsync/dev-index-excludes.txt"
LOG="$HOME/.config/pai/logs/dev-index-sync.log"

mkdir -p "$(dirname "$LOG")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sync" >> "$LOG"

# Sync Development directory
rsync -az --delete \
  --exclude-from="$EXCLUDES" \
  "${DEV_DIR:-$HOME/Development}/" \
  "$DEST/Development/" \
  >> "$LOG" 2>&1

# Sync PAI public config
rsync -az --delete \
  --exclude-from="$EXCLUDES" \
  "$HOME/.config/pai/" \
  "$DEST/pai/" \
  >> "$LOG" 2>&1

# Sync PAI private config (secrets excluded via exclude file)
rsync -az --delete \
  --exclude-from="$EXCLUDES" \
  "$HOME/.config/pai-private/" \
  "$DEST/pai-private/" \
  >> "$LOG" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync complete" >> "$LOG"
