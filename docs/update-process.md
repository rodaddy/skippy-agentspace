# skippy-agentspace Update Process

You are updating an existing skippy-agentspace installation. This document is your complete instruction set. Follow it end-to-end.

**Prerequisite:** skippy-agentspace was previously installed via `docs/install-process.md`. If this is a first-time install, read that file instead.

## What You're About To Do

1. Snapshot current state for comparison
2. Pull latest changes from the repo
3. Backup existing skills with restore script
4. Copy updated skills into PAI
5. Run eval loops on changed skills
6. Report what changed

## Step 1: Pre-Update Snapshot

Capture current state for comparison after update:

```bash
# Record installed skills and their command counts
echo "=== Pre-update snapshot ===" > /tmp/skippy-pre-update.txt
for skill_dir in "$HOME/.config/pai/Skills"/*/; do
    name="$(basename "$skill_dir")"
    cmd_count=$(ls "$skill_dir/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "$name ($cmd_count commands)" >> /tmp/skippy-pre-update.txt
done
cat /tmp/skippy-pre-update.txt
```

Record the current HEAD commit:
```bash
git rev-parse HEAD
```

## Step 2: Pull Latest

From the repo root:

```bash
git pull origin main
```

- Report new commits: `git log --oneline <old-HEAD>..HEAD`
- If pull fails due to local changes: `git stash`, pull, then `git stash pop`
- If merge conflicts: report conflicting files and STOP -- do not force-resolve

## Step 3: Backup Changed Skills

Only backup skills that will be overwritten (not the full system -- that was done at install time):

```bash
BACKUP_DIR="$HOME/.cache/skippy-backups/pre-update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
REPO_SKILLS="$(pwd)/skills"
PAI_SKILLS="$HOME/.config/pai/Skills"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    if [[ -d "$PAI_SKILLS/$name" ]]; then
        cp -R "$PAI_SKILLS/$name" "$BACKUP_DIR/$name"
        echo "BACKUP: $name"
    fi
done
```

Create a restore script:
```bash
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE'
#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"
PAI_SKILLS="$HOME/.config/pai/Skills"
echo "=== Restoring skills from $BACKUP_DIR ==="
for skill_dir in "$BACKUP_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"
    rsync -a --delete "$skill_dir" "$PAI_SKILLS/$name/"
    echo "RESTORED: $name"
done
echo "=== Done. Start a new Claude Code session to pick up changes. ==="
RESTORE
chmod +x "$BACKUP_DIR/restore.sh"
```

## Step 4: Copy Updated Skills

```bash
REPO_SKILLS="$(pwd)/skills"
PAI_SKILLS="$HOME/.config/pai/Skills"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    rsync -a --delete "$skill_dir" "$PAI_SKILLS/$name/"
    echo "UPDATED: $name"
done
```

## Step 5: Run Evals On Changed Skills

Check which skills changed in the pull:

```bash
git diff --name-only <old-HEAD>..HEAD -- skills/
```

For each changed skill that has `evals/evals.json`:
1. Read the assertions
2. Dry-run the test_prompt using only the skill files as instructions
3. Score PASS/FAIL against all assertions
4. If any FAIL: make ONE targeted fix, re-eval, loop (max 20 iterations)
5. Write results to `evals/results.md`

If no evals exist for a changed skill, report it as untested.

## Step 6: Report

Compare pre-update snapshot to current state:

- List new skills (in repo but not in pre-update snapshot)
- List removed skills (in snapshot but not in repo)
- List updated skills (existed before, changed in this pull)
- List new/changed commands per skill
- Report eval results for changed skills

Tell the user:
1. What changed (skills, commands, reference docs)
2. Where the backup lives
3. Whether evals passed
4. Suggest: "Start a new session and run `/skippy:progress` to verify"
