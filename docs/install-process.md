# skippy-agentspace Install Process

You are installing skippy-agentspace -- a skill curation engine for Claude Code. This document is your complete instruction set. Follow it end-to-end.

## What You're About To Do

1. Discover which marketplaces/plugins this repo consumes
2. Backup the user's entire current Claude Code setup with a restore script
3. Run the consume -> coalesce pipeline to produce skippy abilities
4. Remove the old marketplace commands that skippy replaces
5. Install skippy skills and abilities
6. Test the installation with Karpathy-style eval loops
7. Generate a handoff prompt for the user to verify in a fresh session

## Step 1: Discover Consumed Sources

Read `upstreams/*/upstream.json` to find which marketplaces are consumed. Each file lists:
- `repo` -- the GitHub repo URL
- `what_we_take` -- patterns absorbed from this source
- `what_we_reject` -- patterns explicitly rejected

Also read `.planning/audits/` for completed audit data. The audit tells you exactly which commands from each source are ESSENTIAL, USEFUL, CEREMONY, or CUT.

Key files:
- `.planning/audits/marketplace-audit-2026-03-13.md` -- full audit of GSD, OMC, Open Brain, PAUL
- `CLAUDE.md` "Consumed Sources" table -- summary of what was kept/cut per source

## Step 2: Full Backup With Restore Script

Before touching ANYTHING, snapshot the user's current setup:

```bash
BACKUP_DIR="$HOME/.cache/skippy-backups/pre-install-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup everything that will be modified
rsync -a "$HOME/.claude/" "$BACKUP_DIR/dot-claude/"
rsync -a "$HOME/.config/pai/" "$BACKUP_DIR/config-pai/" 2>/dev/null || true
```

Then create a restore script:

```bash
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE'
#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== Restoring from $BACKUP_DIR ==="
echo "This will overwrite ~/.claude/ and ~/.config/pai/ with the backup."
read -p "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0
rsync -a --delete "$BACKUP_DIR/dot-claude/" "$HOME/.claude/"
rsync -a --delete "$BACKUP_DIR/config-pai/" "$HOME/.config/pai/" 2>/dev/null || true
echo "=== Restored. Start a new Claude Code session to pick up changes. ==="
RESTORE
chmod +x "$BACKUP_DIR/restore.sh"
```

Report the backup location and confirm it completed before proceeding.

## Step 3: Ensure Symlink Architecture

Check if `~/.claude/skills` is a single symlink to `~/.config/pai/Skills`:

```bash
readlink "$HOME/.claude/skills"
```

- If it returns `~/.config/pai/Skills` or `/Users/*/config/pai/Skills`: good, skip ahead
- If `~/.claude/skills` is a directory (not a symlink): migrate it
  - Move any non-symlink skill dirs into `~/.config/pai/Skills/`
  - Remove individual symlinks (they all point to PAI already)
  - Remove the directory (handle .DS_Store by moving to /tmp)
  - Create single symlink: `ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`
- If it doesn't exist: `mkdir -p "$HOME/.config/pai/Skills" && ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`

## Step 4: Install Skippy Skills

For each skill directory in this repo's `skills/*/`:

```bash
REPO_SKILLS="$(pwd)/skills"
PAI_SKILLS="$HOME/.config/pai/Skills"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    # Use rsync for clean copy (avoids nested dir issues from cp -R)
    rsync -a --delete "$skill_dir" "$PAI_SKILLS/$name/"
    echo "INSTALLED: $name"
done
```

Report how many skills installed and list the commands each provides.

## Step 5: Remove Old Marketplace Commands

The audit data (Step 1) tells you exactly what skippy replaces. Remove the consumed sources:

**GSD commands** (replaced by skippy:plan, skippy:execute, skippy:verify, skippy:quick, skippy:progress):
```bash
# Move to /tmp for safety (not rm)
mv "$HOME/.claude/commands/gsd" "/tmp/gsd-commands-backup-$$" 2>/dev/null || true
mv "$HOME/.claude/get-shit-done" "/tmp/gsd-core-backup-$$" 2>/dev/null || true
```

**OMC commands that skippy replaces** (keep OMC hooks -- they provide skill injection):
Do NOT uninstall the OMC plugin entirely. Only the commands that overlap with skippy abilities are superseded. The OMC hooks (skill-injector, session-start, pre-tool-enforcer) still provide value. Leave the plugin installed but note that `skippy:plan` replaces `gsd:plan-phase`, etc.

Report what was removed and what was kept.

## Step 6: Test With Eval Loops

For each installed skill that has an `evals/` directory:

1. Read `evals/evals.json` for assertions
2. Run the eval prompt (dry-run execution of the skill's test_prompt)
3. Score against all assertions (PASS/FAIL)
4. If any FAIL: make ONE targeted fix to the skill, re-eval
5. Loop until perfect or max 20 iterations
6. Write results to `evals/results.md`

If a skill has no `evals/` directory, skip testing for now and report it as untested.

Check existing eval results:
```bash
find "$HOME/.config/pai/Skills" -name "results.md" -path "*/evals/*"
```

## Step 7: Generate Handoff Prompt

Create a prompt the user can paste into a NEW Claude Code session to verify the install:

The handoff should include:
- What was installed (skill count, command list)
- What was removed (GSD commands, etc.)
- Where the backup lives (for rollback)
- A specific test to run: "Try `/skippy:progress` in any project with a `.planning/` directory"
- Instructions to run `/skippy:plan` on a real phase to verify end-to-end

Write this handoff to the terminal AND save it to `$BACKUP_DIR/verify-prompt.md`.

## Done

Tell the user:
1. Where the backup + restore script lives
2. How many skills installed, how many commands available
3. What was removed
4. Paste the handoff prompt into a new session to verify

The user should NOT need to do anything else manually.
