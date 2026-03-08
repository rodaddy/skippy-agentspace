# Testing Checkpoint -- skippy-agentspace v1.1

> Paste this into a fresh Claude Code session to run comprehensive testing.
> Branch: `wip/post-audit-testing` (or create new)
> Backup exists: `~/.cache/skippy-backups/pre-testing`

## Context

skippy-agentspace is a portable Claude Code skill repo with 12 skills, 15 reference docs, 3 tracked upstreams (GSD/PAUL/OMC). v1.1 just completed with 7 rounds of multi-agent audit. All known blockers fixed. This session is for independent verification.

## CRITICAL RULES

1. **ALWAYS backup first:** `bash tools/backup-restore.sh backup --name pre-test-session`
2. **ALWAYS sandbox destructive tests:** `export HOME=$(mktemp -d) && mkdir -p $HOME/.claude/skills $HOME/.claude/commands`
3. **NEVER run install.sh, uninstall.sh, or install-hooks.sh against real ~/.claude/**
4. **Restore if anything breaks:** `bash tools/backup-restore.sh restore --name pre-testing`

## Test Suite

### T1: Validation Tools (safe, read-only)
```bash
bash tools/verify.sh
bash tools/index-sync.sh --check
bash tools/validate-hooks.sh
bash tools/validate-hooks.sh --full
bash tools/prereqs.sh < /dev/null
```
**Expected:** All pass. verify.sh 24/24 (1 warning about hooks ok). index-sync 12/12. validate-hooks 6/6 basic, 13/13 full.

### T2: Fresh Clone Install (SANDBOXED)
```bash
SANDBOX=$(mktemp -d) && REAL_HOME="$HOME"
CLONE=$(mktemp -d)/skippy-agentspace
git clone /Volumes/ThunderBolt/Development/skippy-agentspace "$CLONE"
export HOME="$SANDBOX" && mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cd "$CLONE"
bash tools/install.sh --all
echo "Installed: $(ls $HOME/.claude/skills/ | wc -l)"  # expect 12
bash tools/verify.sh
export HOME="$REAL_HOME"
rm -rf "$SANDBOX" "$(dirname $CLONE)"
```

### T3: Install/Uninstall Round-Trip + Blast Radius (SANDBOXED)
```bash
SANDBOX=$(mktemp -d) && REAL_HOME="$HOME"
export HOME="$SANDBOX" && mkdir -p "$HOME/.claude/skills"
cd /Volumes/ThunderBolt/Development/skippy-agentspace
bash tools/install.sh --all
ln -s /tmp "$HOME/.claude/skills/foreign-skill"  # plant a foreign symlink
echo "Before: $(ls $HOME/.claude/skills/ | wc -l)"  # expect 13
bash tools/uninstall.sh --all < <(echo "n")
echo "After: $(ls $HOME/.claude/skills/)"  # expect only "foreign-skill"
export HOME="$REAL_HOME"
rm -rf "$SANDBOX"
```
**CRITICAL:** foreign-skill MUST survive uninstall --all.

### T4: Upgrade Path (SANDBOXED -- copies real setup)
```bash
SANDBOX=$(mktemp -d) && REAL_HOME="$HOME"
cp -R "$REAL_HOME/.claude" "$SANDBOX/.claude"
export HOME="$SANDBOX"
cd /Volumes/ThunderBolt/Development/skippy-agentspace
echo "Before: $(ls $HOME/.claude/skills/ | wc -l)"
bash tools/install.sh --all
echo "After: $(ls $HOME/.claude/skills/ | wc -l)"
bash tools/verify.sh
# PAI skills should still be there
for s in n8n proxmox litellm homeassistant Git Research; do
  test -e "$HOME/.claude/skills/$s" && echo "OK: $s" || echo "MISSING: $s"
done
bash tools/uninstall.sh --all < <(echo "n")
# PAI skills should survive
for s in n8n proxmox litellm homeassistant Git Research; do
  test -e "$HOME/.claude/skills/$s" && echo "SURVIVED: $s" || echo "LOST: $s (BUG!)"
done
export HOME="$REAL_HOME"
rm -rf "$SANDBOX"
```

### T5: Individual Install Modes (SANDBOXED)
```bash
SANDBOX=$(mktemp -d) && REAL_HOME="$HOME"
export HOME="$SANDBOX" && mkdir -p "$HOME/.claude/skills"
cd /Volumes/ThunderBolt/Development/skippy-agentspace
bash tools/install.sh --core  # just core
echo "Core only: $(ls $HOME/.claude/skills/)"  # expect: core
bash tools/install.sh skippy-dev add-todo  # positional args
echo "Added: $(ls $HOME/.claude/skills/)"  # expect: core, skippy-dev, add-todo
bash tools/uninstall.sh add-todo  # individual uninstall
echo "Removed: $(ls $HOME/.claude/skills/)"  # expect: core, skippy-dev
export HOME="$REAL_HOME"
rm -rf "$SANDBOX"
```

### T6: Idempotency (SANDBOXED)
```bash
SANDBOX=$(mktemp -d) && REAL_HOME="$HOME"
export HOME="$SANDBOX" && mkdir -p "$HOME/.claude/skills"
cd /Volumes/ThunderBolt/Development/skippy-agentspace
bash tools/install.sh --all
bash tools/install.sh --all  # second time -- should be clean, no errors
echo "Still 12: $(ls $HOME/.claude/skills/ | wc -l)"
export HOME="$REAL_HOME"
rm -rf "$SANDBOX"
```

### T7: Backup/Restore Round-Trip
```bash
bash tools/backup-restore.sh list  # should show pre-testing
bash tools/backup-restore.sh diff  # should show no missing skills
```

### T8: Upstream Tracking
```bash
# Verify SHAs are populated
for f in upstreams/*/upstream.json; do
  echo "$f: $(grep last_checked_sha "$f" | head -1)"
done
# All should have real SHAs, not "none"
```

### T9: Cross-Reference Consistency
```bash
echo "Skills on disk: $(ls -d skills/*/ | wc -l)"
echo "INDEX.md: $(grep -c '\[' INDEX.md)"
echo "marketplace.json: $(bun -e "console.log(require('./.claude-plugin/marketplace.json').plugins.length)")"
echo "Source URLs: $(grep -c 'rodaddy/skippy' skills/*/SKILL.md)"  # expect 12
echo "Stale rico/: $(grep -rn 'rico/skippy' skills/*/SKILL.md | wc -l)"  # expect 0
echo "Stale owner/: $(grep -rn 'owner/skippy' --include='*.md' . | grep -v .planning/ | wc -l)"  # expect 0
```

### T10: Shellcheck
```bash
find . -name "*.sh" -not -path "./.planning/*" | while read f; do
  echo "=== $f ==="
  shellcheck -x -s bash "$f" 2>&1 | head -5
done
```

## Known Issues (not blockers, next milestone)
- No automated test suite (bats-core) -- these manual tests are the only quality gate
- deploy-service has 12 hardcoded placeholders with no config mechanism
- Only 7/12 skills truly portable (5 need infrastructure)
- No CONTRIBUTING.md
- 96 planning files committed (need .gitattributes export-ignore)
- index-sync.sh doesn't validate CLAUDE.md/README.md consistency (only INDEX.md)

## If Something Breaks
```bash
bash tools/backup-restore.sh restore --name pre-testing
```
