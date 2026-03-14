# skippy-agentspace Update Process

Incremental update of an existing installation. For first-time install, see `install-process.md`.

**Shared procedures (backup, logging, diff, smoke test, etc.) are in `process.md`. Read it first.**

**If any step fails: run `$BACKUP_DIR/restore.sh --force` to roll back. See process.md Failure Protocol.**

## Step 1: Read Shared Process

Read `docs/process.md` for shared SOPs. All apply here.

## Step 2: Backup

Follow process.md "Backup" section. Backup goes to `~/Desktop/skippy-backup-{timestamp}/`.

Start the install log: `$BACKUP_DIR/update-log.md`.

## Step 3: Before Inventory + Eval Baseline

Follow process.md "Before/After Inventory" (capture "before") and "Eval Baseline" sections.

## Step 4: Pull Latest

From the repo root:

```bash
OLD_HEAD=$(git rev-parse HEAD)
git pull origin main
```

- Report new commits: `git log --oneline $OLD_HEAD..HEAD`
- If pull fails due to local changes: `git stash`, pull, then `git stash pop`
- If merge conflicts: report conflicting files and STOP -- do not force-resolve

If no new commits: "Already up to date. Nothing to update." -- stop here.

## Step 5: Identify Changed Skills

```bash
git diff --name-only $OLD_HEAD..HEAD -- skills/
```

Group by skill name. Only these skills need updating -- skip unchanged skills.

## Step 6: Pre-Update Diff

Follow process.md "Pre-Install/Update Diff" section, but ONLY for changed skills (from Step 5).

Warn if installed version has files the repo doesn't (e.g., evals/results.md). Get user approval before overwriting.

## Step 7: Copy Changed Skills Only

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
PAI_SKILLS="$HOME/.config/pai/Skills"

for name in <changed-skills-from-step-5>; do
    skill_dir="$REPO_ROOT/skills/$name"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$skill_dir" "$PAI_SKILLS/$name/"
    else
        [[ -d "$PAI_SKILLS/$name" ]] && mv "$PAI_SKILLS/$name" "/tmp/skippy-replaced-$name-$$"
        cp -R "$skill_dir" "$PAI_SKILLS/$name"
    fi
    echo "UPDATED: $name"
done
```

## Step 8: Reference Doc Completeness

Follow process.md "Reference Doc Completeness Check". Only check changed skills.

## Step 9: Run Evals On Changed Skills

For each changed skill that has `evals/evals.json`:

1. Read the assertions
2. Dry-run the test_prompt using only the skill files as instructions
3. Score PASS/FAIL against all assertions
4. If any FAIL: make ONE targeted fix, re-eval, loop (max 20 iterations)
5. Write results to `evals/results.md`

Compare scores to eval baseline (from Step 3). Score dropped? Flag it to user.

Skills without `evals/` -- report as untested.

## Step 10: After Inventory

Follow process.md "Before/After Inventory" (capture "after"). Report delta.

## Step 11: OMC Hook Audit

Follow process.md "OMC Hook Audit" section.

## Step 12: Post-Update Smoke Test

Follow process.md "Post-Install Smoke Test" section.

## Step 13: Change Manifest

Follow process.md "Change Manifest" section. Write to `$BACKUP_DIR/changes.md`.

## Done

Tell the user:
1. Backup location (Desktop)
2. Update log location
3. What changed (skills updated, commands added/removed)
4. Eval results (scores held, dropped, or untested)
5. Suggest: "Start a new session and run `/skippy:progress` to verify"
