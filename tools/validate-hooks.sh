#!/usr/bin/env bash
# validate-hooks.sh - Validate PAI hook system integrity
#
# Usage:
#   bash tools/validate-hooks.sh           # Quick mode (< 5 seconds)
#   bash tools/validate-hooks.sh --full    # Full mode (includes install/uninstall tests)
#
# Quick mode checks:
#   1. Manifest completeness (15 hooks, required fields)
#   2. Hook file existence
#   3. Hook file structure (shebang, imports, fail-open)
#   4. No camelCase field access
#   5. Shared lib completeness
#
# Full mode adds:
#   6. Install safety (HOOK-02)
#   7. Uninstall safety (HOOK-03)
#   8. Idempotency (HOOK-04)
#   9. Backup creation (HOOK-05)

set -euo pipefail

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/skills/core/hooks"
MANIFEST="$HOOKS_DIR/manifest.json"

FULL_MODE=false
PASS_COUNT=0
FAIL_COUNT=0

for arg in "$@"; do
  case "$arg" in
    --full) FULL_MODE=true ;;
  esac
done

pass() {
  echo "  PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# ---------------------------------------------------------------------------
# Check 1: Manifest completeness
# ---------------------------------------------------------------------------

echo "Check 1: Manifest completeness"

if [ ! -f "$MANIFEST" ]; then
  fail "manifest.json not found"
else
  HOOK_COUNT=$(bun -e "const m = JSON.parse(require('fs').readFileSync('$MANIFEST','utf-8')); console.log(m.hooks.length)")
  if [ "$HOOK_COUNT" = "15" ]; then
    pass "manifest has 15 hooks"
  else
    fail "manifest has $HOOK_COUNT hooks (expected 15)"
  fi

  # Check required fields
  FIELD_CHECK=$(bun -e "
    const m = JSON.parse(require('fs').readFileSync('$MANIFEST','utf-8'));
    const required = ['id','law','name','event','script','blocking'];
    let missing = 0;
    for (const h of m.hooks) {
      for (const f of required) {
        if (h[f] === undefined) { missing++; console.error('Missing ' + f + ' in ' + h.id); }
      }
    }
    console.log(missing);
  ")
  if [ "$FIELD_CHECK" = "0" ]; then
    pass "all hooks have required fields (id, law, name, event, script, blocking)"
  else
    fail "$FIELD_CHECK missing required fields"
  fi
fi

# ---------------------------------------------------------------------------
# Check 2: Hook file existence
# ---------------------------------------------------------------------------

echo "Check 2: Hook file existence"

MISSING_FILES=0
while IFS= read -r script; do
  if [ ! -f "$HOOKS_DIR/$script" ]; then
    fail "missing script: $script"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done < <(bun -e "const m = JSON.parse(require('fs').readFileSync('$MANIFEST','utf-8')); m.hooks.forEach(h => console.log(h.script))")

if [ "$MISSING_FILES" = "0" ]; then
  pass "all 15 hook scripts exist"
fi

# ---------------------------------------------------------------------------
# Check 3: Hook file structure
# ---------------------------------------------------------------------------

echo "Check 3: Hook file structure"

STRUCT_ISSUES=0
for hookfile in "$HOOKS_DIR"/law-*.ts; do
  name=$(basename "$hookfile")

  # Check shebang
  if ! head -1 "$hookfile" | grep -q '^#!/usr/bin/env bun'; then
    fail "$name: missing #!/usr/bin/env bun shebang"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check imports from lib
  if ! grep -q 'from "./lib/' "$hookfile"; then
    fail "$name: no imports from ./lib/"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check isSubagent usage
  if ! grep -q 'isSubagent' "$hookfile"; then
    fail "$name: missing isSubagent check"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check fail-open (allowDecision in catch block)
  if ! grep -q 'allowDecision' "$hookfile"; then
    fail "$name: missing allowDecision (fail-open)"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi
done

if [ "$STRUCT_ISSUES" = "0" ]; then
  pass "all hooks: correct shebang, lib imports, isSubagent, fail-open"
fi

# ---------------------------------------------------------------------------
# Check 4: No camelCase field access
# ---------------------------------------------------------------------------

echo "Check 4: No camelCase field access"

CAMEL_FILES=$(grep -l 'input\.toolName\|input\.toolInput\|raw\.toolName\|raw\.toolInput' "$HOOKS_DIR"/law-*.ts 2>/dev/null || true)
if [ -z "$CAMEL_FILES" ]; then
  pass "no camelCase field access (toolName/toolInput) in hook scripts"
else
  fail "camelCase field access found in: $CAMEL_FILES"
fi

# ---------------------------------------------------------------------------
# Check 5: Shared lib completeness
# ---------------------------------------------------------------------------

echo "Check 5: Shared lib completeness"

LIB_ISSUES=0
for libfile in types.ts context.ts feedback.ts merge.ts; do
  if [ ! -f "$HOOKS_DIR/lib/$libfile" ]; then
    fail "missing lib/$libfile"
    LIB_ISSUES=$((LIB_ISSUES + 1))
  fi
done

if [ "$LIB_ISSUES" = "0" ]; then
  pass "shared lib complete: types.ts, context.ts, feedback.ts, merge.ts"
fi

# ---------------------------------------------------------------------------
# Full mode checks
# ---------------------------------------------------------------------------

if [ "$FULL_MODE" = true ]; then

  TMPDIR=$(mktemp -d)
  SETTINGS="$TMPDIR/settings.json"
  trap 'rm -rf "$TMPDIR"' EXIT

  # Create test fixture with GSD/OMC hooks
  cat > "$SETTINGS" << 'FIXTURE'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node ~/.claude/hooks/gsd-pre-bash.js" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "node ~/.claude/plugins/cache/omc/hooks/post-tool.js" }
        ]
      }
    ]
  },
  "permissions": {
    "allow": ["Read", "Glob", "Grep"]
  }
}
FIXTURE

  # -------------------------------------------------------------------------
  # Check 6: Install safety (HOOK-02)
  # -------------------------------------------------------------------------

  echo "Check 6: Install safety (HOOK-02)"
  bash "$HOOKS_DIR/install-hooks.sh" --settings="$SETTINGS" >/dev/null

  GSD_PRESERVED=$(bun -e "
    const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf-8'));
    const found = s.hooks.PreToolUse?.some(g => g.hooks.some(h => h.command.includes('gsd-pre-bash')));
    console.log(found ? 'yes' : 'no');
  ")

  OMC_PRESERVED=$(bun -e "
    const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf-8'));
    const found = s.hooks.PostToolUse?.some(g => g.hooks.some(h => h.command.includes('omc')));
    console.log(found ? 'yes' : 'no');
  ")

  PAI_COUNT=$(bun -e "
    const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf-8'));
    let c = 0;
    for (const gs of Object.values(s.hooks || {})) { for (const g of gs) { for (const h of g.hooks) { if (h.command.includes('skills/core/hooks/')) c++; } } }
    console.log(c);
  ")

  if [ "$GSD_PRESERVED" = "yes" ]; then pass "GSD hooks preserved after install"; else fail "GSD hooks lost after install"; fi
  if [ "$OMC_PRESERVED" = "yes" ]; then pass "OMC hooks preserved after install"; else fail "OMC hooks lost after install"; fi
  if [ "$PAI_COUNT" = "15" ]; then pass "15 PAI hooks installed"; else fail "expected 15 PAI hooks, got $PAI_COUNT"; fi

  # -------------------------------------------------------------------------
  # Check 7: Uninstall safety (HOOK-03)
  # -------------------------------------------------------------------------

  echo "Check 7: Uninstall safety (HOOK-03)"
  cp "$SETTINGS" "$TMPDIR/pre-uninstall.json"
  bash "$HOOKS_DIR/uninstall-hooks.sh" --settings="$SETTINGS" >/dev/null

  PAI_AFTER=$(bun -e "
    const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf-8'));
    let c = 0;
    for (const gs of Object.values(s.hooks || {})) { for (const g of gs) { for (const h of g.hooks) { if (h.command.includes('skills/core/hooks/')) c++; } } }
    console.log(c);
  ")

  GSD_AFTER=$(bun -e "
    const s = JSON.parse(require('fs').readFileSync('$SETTINGS','utf-8'));
    const found = s.hooks?.PreToolUse?.some(g => g.hooks.some(h => h.command.includes('gsd-pre-bash')));
    console.log(found ? 'yes' : 'no');
  ")

  if [ "$PAI_AFTER" = "0" ]; then pass "all PAI hooks removed"; else fail "$PAI_AFTER PAI hooks remain after uninstall"; fi
  if [ "$GSD_AFTER" = "yes" ]; then pass "GSD hooks preserved after uninstall"; else fail "GSD hooks lost after uninstall"; fi

  # -------------------------------------------------------------------------
  # Check 8: Idempotency (HOOK-04)
  # -------------------------------------------------------------------------

  echo "Check 8: Idempotency (HOOK-04)"

  # Reset fixture
  cat > "$SETTINGS" << 'FIXTURE2'
{
  "hooks": {},
  "permissions": { "allow": ["Read"] }
}
FIXTURE2

  bash "$HOOKS_DIR/install-hooks.sh" --settings="$SETTINGS" >/dev/null
  cp "$SETTINGS" "$TMPDIR/first-install.json"
  bash "$HOOKS_DIR/install-hooks.sh" --settings="$SETTINGS" >/dev/null

  if diff -q "$TMPDIR/first-install.json" "$SETTINGS" >/dev/null 2>&1; then
    pass "install is idempotent (identical after two runs)"
  else
    fail "install is NOT idempotent (diff detected)"
  fi

  # -------------------------------------------------------------------------
  # Check 9: Backup creation (HOOK-05)
  # -------------------------------------------------------------------------

  echo "Check 9: Backup creation (HOOK-05)"

  BACKUP_COUNT=$(ls -1 "$TMPDIR"/settings.json.backup-* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$BACKUP_COUNT" -ge "1" ]; then
    pass "backup files created ($BACKUP_COUNT found)"
  else
    fail "no backup files found"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
else
  echo "All checks passed."
  exit 0
fi
