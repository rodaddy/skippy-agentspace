# skippy-agentspace Update Process

Incremental update of an existing installation. For first-time install, see `install-process.md`.

**Shared procedures (backup, logging, diff, smoke test, etc.) are in `process.md`. Read it first.**

**If any step fails: run `$BACKUP_DIR/restore.sh --force` to roll back. See process.md Failure Protocol.**

## How This Update Works

Same interactive Q/A pattern as install. For each step:

1. **Explain** -- what this step does
2. **Ask** -- use `AskUserQuestion` with predefined options. Click-only, no typing.
3. **Execute** -- run the step, one bash call per action
4. **Show** -- display results
5. **Confirm** -- ready for next?

All steps logged to `$BACKUP_DIR/update-log.md` with exact commands and results. See process.md "Install Log" for format.

## Step 1: Present Overview

**DO NOT run any commands yet.** Present the update steps:

| Step | Action |
|------|--------|
| 2 | Backup changed skills with restore script |
| 3 | Capture current skill/command counts + eval baseline |
| 4 | Pull latest from repo |
| 5 | Identify which skills changed |
| 6 | Pre-update diff (compare repo vs installed for changed skills) |
| 7 | Copy changed skills (additive) |
| 8 | Reference doc completeness check |
| 9 | Run evals on changed skills |
| 10 | After inventory |
| 11 | OMC hook audit |
| 12 | Post-update smoke test |
| 13 | Change manifest + summary |

**Ask (AskUserQuestion):** "Ready to update?" -- options: Proceed / Show what changed since last update first / Cancel

Then read `docs/process.md` silently.

## Step 2: Backup

Follow process.md "Backup" section. Backup location determined by process.md (Desktop if exists, ~/.cache/ fallback).

Write state file:
```bash
STATE_FILE="/tmp/skippy-install-state.txt"
source "$STATE_FILE" 2>/dev/null || true  # load existing SKILLS_TARGET if set
echo "BACKUP_DIR=$BACKUP_DIR" > "$STATE_FILE"
echo "SKILLS_TARGET=${SKILLS_TARGET:-$HOME/.config/pai/Skills}" >> "$STATE_FILE"
```

Start update log: `$BACKUP_DIR/update-log.md`.

**Ask (AskUserQuestion):** "Backup complete." -- options: Continue / Show backup details / Rollback

## Step 3: Before Inventory + Eval Baseline

Follow process.md "Before/After Inventory" (capture "before") and "Eval Baseline" sections.

**Show the user:** current skill count, command count, eval scores.

**Ask (AskUserQuestion):** "Current state captured." -- options: Continue / Show details

## Step 4: Pull Latest

```bash
OLD_HEAD=$(git rev-parse HEAD)
git pull origin main
```

- Report new commits: `git log --oneline $OLD_HEAD..HEAD`
- If pull fails due to local changes: `git stash`, pull, then `git stash pop`
- If merge conflicts: report conflicting files and STOP

If no new commits: "Already up to date." -- stop here.

**Show the user:** commit list, files changed summary.

**Ask (AskUserQuestion):** "N new commits pulled." -- options: Continue / Show commit details / Rollback

## Step 5: Identify Changed Skills

```bash
git diff --name-only $OLD_HEAD..HEAD -- skills/ | cut -d/ -f2 | sort -u
```

**Show the user:** table of changed skills.

**Ask (AskUserQuestion):** "N skills changed." -- options: Update all / Select which to update / Skip update

## Step 6: Pre-Update Diff

Follow process.md "Pre-Install/Update Diff" section, but ONLY for changed skills.

Use AI judgment: read installed-only files, recommend merge vs replace per skill.

For skills with installed-only files at risk:
**Ask (AskUserQuestion) per skill:** "Skill X has Y installed-only files." -- options: Merge (additive) / Clean replace / Skip this skill

**Default is Merge. NEVER clean-replace without per-skill approval.**

## Step 7: Copy Changed Skills Only

```bash
source /tmp/skippy-install-state.txt
REPO_ROOT="$(git rev-parse --show-toplevel)"
PAI_SKILLS="${SKILLS_TARGET:-$HOME/.config/pai/Skills}"

for name in <changed-skills-from-step-5>; do
    skill_dir="$REPO_ROOT/skills/$name"
    if command -v rsync >/dev/null 2>&1; then
        # ADDITIVE: copies repo files in, preserves installed-only files
        rsync -a "$skill_dir/" "$PAI_SKILLS/$name/"
    else
        cp -R "$skill_dir/" "$PAI_SKILLS/$name/"
    fi
    echo "UPDATED: $name"
done
```

**Show the user:** each skill updated with files changed.

**Ask (AskUserQuestion):** "N skills updated." -- options: Continue to verification / Show details

## Step 8: Reference Doc Completeness

Follow process.md "Reference Doc Completeness Check". Only check changed skills.

**Show the user:** OK/MISSING table.

**Ask (AskUserQuestion, only if MISSING):** "Missing references found." -- options: Investigate / Continue anyway / Rollback

## Step 9: Run Evals On Changed Skills

For each changed skill that has `evals/evals.json`:

1. Read the assertions
2. Dry-run the test_prompt using only the skill files
3. Score PASS/FAIL
4. If FAIL: ONE targeted fix, re-eval, loop (max 20)
5. Write results to `evals/results.md`

Compare to eval baseline (Step 3). Score dropped? Flag it.

**Show the user:** eval results table with before/after scores.

**Ask (AskUserQuestion):** "Eval results shown." -- options: Continue / Investigate drops / Rollback

## Step 10: After Inventory

Follow process.md "Before/After Inventory" (capture "after"). Report delta.

**Show the user:** before/after comparison.

## Step 11: OMC Hook Audit

Follow process.md "OMC Hook Audit" section. Skip if no OMC.

## Step 12: Post-Update Smoke Test

Follow process.md "Post-Install Smoke Test" section.

**Ask (AskUserQuestion):** "Smoke test results." -- options: Continue / Investigate failures / Rollback

## Step 13: Change Manifest

Follow process.md "Change Manifest" section. Write to `$BACKUP_DIR/changes.md`.

## Done

Tell the user:
1. Backup + restore: `$BACKUP_DIR/` (location shown during Step 2)
2. Update log: `$BACKUP_DIR/update-log.md`
3. What changed (skills updated, commands added/removed)
4. Eval results (scores held, dropped, or untested)
5. "Start a new session and run `/skippy:progress` to verify"
