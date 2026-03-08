#!/usr/bin/env bash
# validate-hooks.sh - Validate PAI hook system integrity
#
# Usage:
#   bash tools/validate-hooks.sh           # Quick mode (< 5 seconds)
#   bash tools/validate-hooks.sh --full    # Full mode (includes install/uninstall tests)
#
# Quick mode checks:
#   1. Manifest completeness (hook count, required fields)
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

# Source shared library with graceful fallback
_COMMON_SH="$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    SKIPPY_PASS=${SKIPPY_PASS:-0}; SKIPPY_WARN=${SKIPPY_WARN:-0}; SKIPPY_FAIL=${SKIPPY_FAIL:-0}
    skippy_repo_root() { local d; d="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"; [[ -d "$d/skills" ]] && echo "$d" && return 0; [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]] && echo "$SKIPPY_ROOT" && return 0; return 1; }
    skippy_pass() { printf '  \033[32m✓\033[0m %s\n' "${1:?requires message}"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn() { printf '  \033[33m⚠\033[0m %s\n' "${1:?requires message}"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail() { printf '  \033[31m✗\033[0m %s\n' "${1:?requires message}"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_suggest() { printf '  \033[36m💡\033[0m %s\n' "${1:?requires message}"; }
    skippy_section() { printf '\n=== %s ===\n\n' "${1:?requires section name}"; }
    skippy_summary() { printf '\n%d passed, %d warnings, %d failures\n' "$SKIPPY_PASS" "$SKIPPY_WARN" "$SKIPPY_FAIL"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
    skippy_is_installed() { [[ -L "$HOME/.claude/skills/${1:?}" ]] || [[ -L "$HOME/.claude/commands/${1:?}" ]]; }
fi

REPO_ROOT="$(skippy_repo_root)"
HOOKS_DIR="$REPO_ROOT/skills/core/hooks"
MANIFEST="$HOOKS_DIR/manifest.json"

FULL_MODE=false

for arg in "$@"; do
  case "$arg" in
    --full) FULL_MODE=true ;;
  esac
done

# ---------------------------------------------------------------------------
# Check 1: Manifest completeness
# ---------------------------------------------------------------------------

echo "Check 1: Manifest completeness"

if [ ! -f "$MANIFEST" ]; then
  skippy_fail "manifest.json not found"
else
  HOOK_COUNT=$(MANIFEST_FILE="$MANIFEST" bun -e "const m = JSON.parse(require('fs').readFileSync(process.env.MANIFEST_FILE,'utf-8')); console.log(m.hooks.length)")
  if [ "$HOOK_COUNT" -gt 0 ] 2>/dev/null; then
    skippy_pass "manifest has $HOOK_COUNT hooks"
  else
    skippy_fail "manifest has 0 hooks"
  fi

  # Check required fields
  FIELD_CHECK=$(MANIFEST_FILE="$MANIFEST" bun -e "
    const m = JSON.parse(require('fs').readFileSync(process.env.MANIFEST_FILE,'utf-8'));
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
    skippy_pass "all hooks have required fields (id, law, name, event, script, blocking)"
  else
    skippy_fail "$FIELD_CHECK missing required fields"
  fi
fi

# ---------------------------------------------------------------------------
# Check 2: Hook file existence
# ---------------------------------------------------------------------------

echo "Check 2: Hook file existence"

MISSING_FILES=0
while IFS= read -r script; do
  if [ ! -f "$HOOKS_DIR/$script" ]; then
    skippy_fail "missing script: $script"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done < <(MANIFEST_FILE="$MANIFEST" bun -e "const m = JSON.parse(require('fs').readFileSync(process.env.MANIFEST_FILE,'utf-8')); m.hooks.forEach(h => console.log(h.script))")

if [ "$MISSING_FILES" = "0" ]; then
  skippy_pass "all $HOOK_COUNT hook scripts exist"
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
    skippy_fail "$name: missing #!/usr/bin/env bun shebang"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check imports from lib
  if ! grep -q 'from "./lib/' "$hookfile"; then
    skippy_fail "$name: no imports from ./lib/"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check isSubagent usage
  if ! grep -q 'isSubagent' "$hookfile"; then
    skippy_fail "$name: missing isSubagent check"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi

  # Check fail-open (allowDecision in catch block)
  if ! grep -q 'allowDecision' "$hookfile"; then
    skippy_fail "$name: missing allowDecision (fail-open)"
    STRUCT_ISSUES=$((STRUCT_ISSUES + 1))
  fi
done

if [ "$STRUCT_ISSUES" = "0" ]; then
  skippy_pass "all hooks: correct shebang, lib imports, isSubagent, fail-open"
fi

# ---------------------------------------------------------------------------
# Check 4: No camelCase field access
# ---------------------------------------------------------------------------

echo "Check 4: No camelCase field access"

CAMEL_FILES=$(grep -l 'input\.toolName\|input\.toolInput\|raw\.toolName\|raw\.toolInput' "$HOOKS_DIR"/law-*.ts 2>/dev/null || true)
if [ -z "$CAMEL_FILES" ]; then
  skippy_pass "no camelCase field access (toolName/toolInput) in hook scripts"
else
  skippy_fail "camelCase field access found in: $CAMEL_FILES"
fi

# ---------------------------------------------------------------------------
# Check 5: Shared lib completeness
# ---------------------------------------------------------------------------

echo "Check 5: Shared lib completeness"

LIB_ISSUES=0
for libfile in types.ts context.ts feedback.ts merge.ts; do
  if [ ! -f "$HOOKS_DIR/lib/$libfile" ]; then
    skippy_fail "missing lib/$libfile"
    LIB_ISSUES=$((LIB_ISSUES + 1))
  fi
done

if [ "$LIB_ISSUES" = "0" ]; then
  skippy_pass "shared lib complete: types.ts, context.ts, feedback.ts, merge.ts"
fi

# ---------------------------------------------------------------------------
# Full mode checks
# ---------------------------------------------------------------------------

if [ "$FULL_MODE" = true ]; then

  HOOK_TMPDIR=$(mktemp -d)
  SETTINGS="$HOOK_TMPDIR/settings.json"
  trap 'rm -rf "$HOOK_TMPDIR"' EXIT

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

  GSD_PRESERVED=$(SETTINGS_FILE="$SETTINGS" bun -e "
    const s = JSON.parse(require('fs').readFileSync(process.env.SETTINGS_FILE,'utf-8'));
    const found = s.hooks.PreToolUse?.some(g => g.hooks.some(h => h.command.includes('gsd-pre-bash')));
    console.log(found ? 'yes' : 'no');
  ")

  OMC_PRESERVED=$(SETTINGS_FILE="$SETTINGS" bun -e "
    const s = JSON.parse(require('fs').readFileSync(process.env.SETTINGS_FILE,'utf-8'));
    const found = s.hooks.PostToolUse?.some(g => g.hooks.some(h => h.command.includes('omc')));
    console.log(found ? 'yes' : 'no');
  ")

  PAI_COUNT=$(SETTINGS_FILE="$SETTINGS" bun -e "
    const s = JSON.parse(require('fs').readFileSync(process.env.SETTINGS_FILE,'utf-8'));
    let c = 0;
    for (const gs of Object.values(s.hooks || {})) { for (const g of gs) { for (const h of g.hooks) { if (h.command.includes('skills/core/hooks/')) c++; } } }
    console.log(c);
  ")

  if [ "$GSD_PRESERVED" = "yes" ]; then skippy_pass "GSD hooks preserved after install"; else skippy_fail "GSD hooks lost after install"; fi
  if [ "$OMC_PRESERVED" = "yes" ]; then skippy_pass "OMC hooks preserved after install"; else skippy_fail "OMC hooks lost after install"; fi
  if [ "$PAI_COUNT" = "$HOOK_COUNT" ]; then skippy_pass "$HOOK_COUNT PAI hooks installed"; else skippy_fail "expected $HOOK_COUNT PAI hooks, got $PAI_COUNT"; fi

  # -------------------------------------------------------------------------
  # Check 7: Uninstall safety (HOOK-03)
  # -------------------------------------------------------------------------

  echo "Check 7: Uninstall safety (HOOK-03)"
  cp "$SETTINGS" "$HOOK_TMPDIR/pre-uninstall.json"
  bash "$HOOKS_DIR/uninstall-hooks.sh" --settings="$SETTINGS" >/dev/null

  PAI_AFTER=$(SETTINGS_FILE="$SETTINGS" bun -e "
    const s = JSON.parse(require('fs').readFileSync(process.env.SETTINGS_FILE,'utf-8'));
    let c = 0;
    for (const gs of Object.values(s.hooks || {})) { for (const g of gs) { for (const h of g.hooks) { if (h.command.includes('skills/core/hooks/')) c++; } } }
    console.log(c);
  ")

  GSD_AFTER=$(SETTINGS_FILE="$SETTINGS" bun -e "
    const s = JSON.parse(require('fs').readFileSync(process.env.SETTINGS_FILE,'utf-8'));
    const found = s.hooks?.PreToolUse?.some(g => g.hooks.some(h => h.command.includes('gsd-pre-bash')));
    console.log(found ? 'yes' : 'no');
  ")

  if [ "$PAI_AFTER" = "0" ]; then skippy_pass "all PAI hooks removed"; else skippy_fail "$PAI_AFTER PAI hooks remain after uninstall"; fi
  if [ "$GSD_AFTER" = "yes" ]; then skippy_pass "GSD hooks preserved after uninstall"; else skippy_fail "GSD hooks lost after uninstall"; fi

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
  cp "$SETTINGS" "$HOOK_TMPDIR/first-install.json"
  bash "$HOOKS_DIR/install-hooks.sh" --settings="$SETTINGS" >/dev/null

  if diff -q "$HOOK_TMPDIR/first-install.json" "$SETTINGS" >/dev/null 2>&1; then
    skippy_pass "install is idempotent (identical after two runs)"
  else
    skippy_fail "install is NOT idempotent (diff detected)"
  fi

  # -------------------------------------------------------------------------
  # Check 9: Backup creation (HOOK-05)
  # -------------------------------------------------------------------------

  echo "Check 9: Backup creation (HOOK-05)"

  BACKUP_COUNT=$(ls -1 "$HOOK_TMPDIR"/settings.json.backup-* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$BACKUP_COUNT" -ge "1" ]; then
    skippy_pass "backup files created ($BACKUP_COUNT found)"
  else
    skippy_fail "no backup files found"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
skippy_summary
