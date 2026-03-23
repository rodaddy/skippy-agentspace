#!/usr/bin/env bash
# Remove security gate local install.
# Reverses everything done by local-install.sh.

set -euo pipefail

HOOKS_DIR="$HOME/.config/pai/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_FILE="pre-exec-guard.ts"
HOOK_DST="$HOOKS_DIR/$HOOK_FILE"
SCAN_LINK="$HOME/.local/bin/scan-skill"

echo "=== Security Gate Local Uninstall ==="

# 1. Remove hook from settings.json
if grep -q "pre-exec-guard.ts" "$SETTINGS" 2>/dev/null; then
  bun -e "
    const fs = require('node:fs');
    const settings = JSON.parse(fs.readFileSync('$SETTINGS', 'utf-8'));
    const preToolUse = settings.hooks?.PreToolUse || [];
    const bashEntry = preToolUse.find(e => e.matcher === 'Bash');
    if (bashEntry) {
      bashEntry.hooks = bashEntry.hooks.filter(h => !h.command.includes('pre-exec-guard.ts'));
      fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2));
      console.log('  DEL   Hook removed from settings.json');
    }
  "
else
  echo "  SKIP  Hook not in settings.json"
fi

# 2. Remove hook file
if [[ -f "$HOOK_DST" ]]; then
  rm "$HOOK_DST"
  echo "  DEL   $HOOK_DST"
else
  echo "  SKIP  $HOOK_FILE not found"
fi

# 3. Remove scan-skill CLI
if [[ -L "$SCAN_LINK" || -f "$SCAN_LINK" ]]; then
  rm "$SCAN_LINK"
  echo "  DEL   $SCAN_LINK"
else
  echo "  SKIP  scan-skill not found"
fi

echo ""
echo "Uninstalled. Security gate is fully removed from local setup."
