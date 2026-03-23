# Lifecycle: install/update/uninstall functional tests
# Runs in a sandboxed HOME to avoid affecting real installation
# Sourced by runner.sh -- check() and assert_empty() available

SANDBOX_HOME="$(mktemp -d)"
SANDBOX_CLAUDE="$SANDBOX_HOME/.claude/skills"
mkdir -p "$SANDBOX_CLAUDE"
trap 'rm -rf "$SANDBOX_HOME"' EXIT

echo "--- lifecycle (sandboxed) ---"

check 104 "lifecycle" "install.sh --all installs all skills to sandbox" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/install.sh --all >/dev/null 2>&1 && [ \"\$(ls -d '$SANDBOX_CLAUDE'/*/ 2>/dev/null | wc -l | tr -d ' ')\" -ge 20 ]"

check 105 "lifecycle" "Installed skills have SKILL.md" \
  bash -c '
    fails=0
    for d in '"$SANDBOX_CLAUDE"'/*/; do
      [ -d "$d" ] || continue
      [ -f "$d/SKILL.md" ] || { echo "MISSING SKILL.md: $d"; fails=1; }
    done; exit $fails
  '

check 106 "lifecycle" "Reinstall over existing does not error" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/install.sh skippy >/dev/null 2>&1"

check 107 "lifecycle" "uninstall.sh removes a single skill" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/uninstall.sh trace >/dev/null 2>&1 && [ ! -d '$SANDBOX_CLAUDE/trace' ]"

check 108 "lifecycle" "uninstall.sh --all removes all skills" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/uninstall.sh --all >/dev/null 2>&1 && [ \"\$(ls '$SANDBOX_CLAUDE' 2>/dev/null | wc -l | tr -d ' ')\" -eq 0 ]"

check 109 "lifecycle" "Install after uninstall works cleanly" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/install.sh core skippy >/dev/null 2>&1 && [ -f '$SANDBOX_CLAUDE/core/SKILL.md' ] && [ -f '$SANDBOX_CLAUDE/skippy/SKILL.md' ]"

check 110 "lifecycle" "Uninstall is idempotent (no error on second run)" \
  bash -c "HOME='$SANDBOX_HOME' bash tools/uninstall.sh --all >/dev/null 2>&1 && HOME='$SANDBOX_HOME' bash tools/uninstall.sh --all >/dev/null 2>&1"

check 111 "lifecycle" "Install invalid skill name gives error" \
  bash -c "! HOME='$SANDBOX_HOME' bash tools/install.sh nonexistent-skill-xyz >/dev/null 2>&1"

# Cleanup
rm -rf "$SANDBOX_HOME"

echo ""
