#!/usr/bin/env bash
# Install security gate locally for testing.
# Copies hook + scanner, wires into CC settings.json.
# Reverse with: ./tools/local-uninstall.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$HOME/.config/pai/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_FILE="pre-exec-guard.ts"
HOOK_SRC="$REPO_ROOT/hooks/$HOOK_FILE"
HOOK_DST="$HOOKS_DIR/$HOOK_FILE"
SCAN_LINK="$HOME/.local/bin/scan-skill"

echo "=== Security Gate Local Install ==="

# 1. Copy hook
if [[ -f "$HOOK_DST" ]]; then
  echo "  SKIP  $HOOK_FILE already exists at $HOOK_DST"
else
  cp "$HOOK_SRC" "$HOOK_DST"
  chmod +x "$HOOK_DST"
  echo "  COPY  $HOOK_FILE -> $HOOKS_DIR/"
fi

# 2. Add hook to settings.json (Bash PreToolUse matcher)
if grep -q "pre-exec-guard.ts" "$SETTINGS" 2>/dev/null; then
  echo "  SKIP  Hook already in settings.json"
else
  # Use bun to safely insert into the Bash hooks array
  bun -e "
    const fs = require('node:fs');
    const settings = JSON.parse(fs.readFileSync('$SETTINGS', 'utf-8'));
    const preToolUse = settings.hooks?.PreToolUse || [];
    const bashEntry = preToolUse.find(e => e.matcher === 'Bash');
    if (bashEntry) {
      bashEntry.hooks.push({
        type: 'command',
        command: 'bun run ~/.config/pai/hooks/pre-exec-guard.ts'
      });
      fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2));
      console.log('  ADD   Hook wired into Bash PreToolUse');
    } else {
      console.log('  WARN  No Bash matcher found in PreToolUse -- add manually');
    }
  "
fi

# 3. Create scan-skill CLI symlink
mkdir -p "$(dirname "$SCAN_LINK")"
if [[ -L "$SCAN_LINK" || -f "$SCAN_LINK" ]]; then
  echo "  SKIP  $SCAN_LINK already exists"
else
  cat > "$SCAN_LINK" << 'WRAPPER'
#!/usr/bin/env bash
exec bun run /Volumes/ThunderBolt/Development/skippy-agentspace/tools/security/scan-cli.ts "$@"
WRAPPER
  chmod +x "$SCAN_LINK"
  echo "  LINK  scan-skill -> scan-cli.ts"
fi

echo ""
echo "Installed. Test with:"
echo "  scan-skill ~/.config/pai/Skills/add-todo"
echo "  scan-skill ~/.config/pai/Skills/add-todo --compact"
echo ""
echo "Remove with: ./tools/local-uninstall.sh"
