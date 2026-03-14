# skippy-agentspace Install Process

First-time installation. For updates, see `update-process.md`.

**Shared procedures (backup, logging, diff, smoke test, etc.) are in `process.md`. Read it first.**

**If any step fails: run `$BACKUP_DIR/restore.sh --force` to roll back. See process.md Failure Protocol.**

## How This Install Works

This is an **interactive, step-by-step** install. You do NOT run all steps automatically. For each step:

1. **Explain** -- tell the user what this step does and why
2. **Ask** -- "Proceed with defaults, customize, or skip?"
3. **Execute** -- run the step
4. **Show** -- display the log output / results
5. **Confirm** -- "Looks good? Ready for next step?"

### Step 0: Install Mode

Before anything else, ask the user:

> **How would you like to install?**
> 1. **Follow defaults** -- standard paths, standard backup, recommended settings. I'll still show you each step but won't ask unless something looks wrong.
> 2. **Guided** -- walk me through every step with explanations. I approve each one before it runs. (recommended for first install)
> 3. **Discover** -- scan my system first, show me what you find, then we decide together what to do.

Default: Guided (option 2).

In all modes, EVERY step is logged to `$BACKUP_DIR/install-log.md`. The log captures what was done even if the user chose defaults.

---

## Step 1: Read Shared Process

Read `docs/process.md` -- it defines the shared SOPs referenced throughout this install.

**Show the user:** "I've read the shared process docs. Here's what the install will do:" followed by a numbered summary of all steps. Ask: "Shall I proceed?"

## Step 2: Backup

Follow process.md "Backup" section. Backup location is determined by process.md (Desktop if it exists, otherwise ~/.cache/).

**Show the user:**
- What directories will be backed up (discovered, not assumed)
- Total size estimate
- Backup location
- Restore command: `bash $BACKUP_DIR/restore.sh`

**Ask:** "Proceed with backup?"

**After:** Show backup results -- files copied, sizes, restore.sh location. Confirm rollback smoke test passed.

Start the install log: `$BACKUP_DIR/install-log.md`.

## Step 3: Discover Consumed Sources

Read `upstreams/*/upstream.json` for marketplace definitions. Read `.planning/audits/` for audit data. Read `CLAUDE.md` "Consumed Sources" table.

**Show the user:**
- Table of consumed sources (GSD, OMC, PAUL, Open Brain)
- What skippy takes from each
- What skippy replaces

**Ask:** "These are the sources skippy consumes. Any questions before we continue?"

## Step 4: Pre-Install Diff

Follow process.md "Pre-Install/Update Diff" section.

**Show the user:**
- Table: each skill, whether it's NEW / IDENTICAL / DIFFERS
- For DIFFERS: which side is newer, what files differ
- Warning if installed version has extra files (evals, custom config) that would be lost

**Ask:** "Approve overwriting these skills? (any you want to keep as-is?)"

**NEVER overwrite without approval on DIFFERS skills.**

## Step 5: Before Inventory

Follow process.md "Before/After Inventory" -- capture the "before" snapshot.

**Show the user:**
- Current skill count
- Current command count
- Where skills live (symlink target or direct directory)

**Ask:** "This is your current setup. Ready to proceed with changes?"

## Step 6: Ensure Symlink Architecture

Check if `~/.claude/skills` is a single symlink to `~/.config/pai/Skills`.

```bash
target=$(readlink "$HOME/.claude/skills" 2>/dev/null || echo "NOT_A_SYMLINK")
```

**Show the user** what was found:
- "Already using single symlink architecture -- no changes needed" OR
- "Found N individual symlinks -- need to migrate to single symlink" OR
- "No skills directory found -- will create from scratch"

**Ask:** "Proceed with symlink setup?" (only if changes are needed)

**Execute:**
- If already correct: skip
- If directory of individual symlinks: migrate (move real dirs to PAI, remove individual symlinks, move .DS_Store to /tmp, create single symlink)
- If doesn't exist: `mkdir -p "$HOME/.config/pai/Skills" && ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`

**Show:** result and verification (`readlink ~/.claude/skills`)

## Step 7: Command Collision Check

Follow process.md "Command Collision Check" section.

**Show the user:**
- Table of any collisions found
- Which commands coexist safely (different names) vs actual conflicts (same name)

**Ask:** "Any collisions you want to resolve before we remove old commands?"

## Step 8: Remove Old Marketplace Commands

Only remove what exists. Move to /tmp, never rm.

**Show the user** what will be removed:
```
GSD: ~/.claude/commands/gsd (32 commands) -> /tmp/gsd-commands-backup-XXXX
GSD: ~/.claude/get-shit-done (core) -> /tmp/gsd-core-backup-XXXX
OMC: keeping (hooks provide value, commands coexist)
```
Or: "No GSD/OMC found -- nothing to remove."

**Ask:** "Proceed with removal? (moved to /tmp, not deleted -- recoverable)"

**Execute:**
```bash
if [[ -d "$HOME/.claude/commands/gsd" ]]; then
    mv "$HOME/.claude/commands/gsd" "/tmp/gsd-commands-backup-$$"
fi
if [[ -d "$HOME/.claude/get-shit-done" ]]; then
    mv "$HOME/.claude/get-shit-done" "/tmp/gsd-core-backup-$$"
fi
```

**OMC:** If installed, report what's kept and why. If not installed, skip. **No OMC required** -- Claude Code discovers skills natively.

**Show:** what was removed, what was kept.

## Step 9: Copy Skippy Skills

**Show the user:**
- List of skills to install with command counts
- Install target directory (`$SKILLS_TARGET` from discovery)

**Ask:** "Proceed with skill installation?"

**Execute:**
```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_SKILLS="$REPO_ROOT/skills"
PAI_SKILLS="$HOME/.config/pai/Skills"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$skill_dir" "$PAI_SKILLS/$name/"
    else
        [[ -d "$PAI_SKILLS/$name" ]] && mv "$PAI_SKILLS/$name" "/tmp/skippy-replaced-$name-$$"
        cp -R "$skill_dir" "$PAI_SKILLS/$name"
    fi
    echo "INSTALLED: $name"
done
```

**Show:** each skill installed with its commands listed.

## Step 10: Reference Doc Completeness

Follow process.md "Reference Doc Completeness Check".

**Show the user:** OK/MISSING table for every referenced doc.

**Ask** (only if MISSING found): "These references are missing -- this will cause commands to fail. Investigate?"

Any MISSING reference is a blocker -- do not proceed until resolved.

## Step 11: After Inventory + Eval Baseline

Follow process.md "Before/After Inventory" (capture "after") and "Eval Baseline" sections.

**Show the user:**
```
Before: X skills, Y commands
After:  X skills, Y commands
Delta:  +N skills, +M commands

Eval baseline:
  n8n: 20/20
  Art: 15/15
  (etc -- only if evals exist)
```

**Ask:** "Inventory looks correct?"

## Step 12: OMC Hook Audit

Follow process.md "OMC Hook Audit" section. Skip if no OMC.

**Show the user:** any warnings about bad hooks.

**Ask** (only if warnings): "Remove these hooks?"

## Step 13: Post-Install Smoke Test

Follow process.md "Post-Install Smoke Test" section.

**Show the user:**
- Symlink check: PASS/FAIL
- Skill count check: PASS/FAIL
- SKILL.md presence: PASS/FAIL
- Skippy commands present: PASS/FAIL
- GSD removed: PASS/FAIL
- Broken symlinks: PASS/FAIL

**Ask:** "All checks passed. Ready for change manifest and handoff?"

If any FAIL: "X checks failed. Investigate or rollback?"

## Step 14: Change Manifest

Follow process.md "Change Manifest" section. Write to `$BACKUP_DIR/changes.md`.

**Show the user:** the manifest summary (added/updated/removed/unchanged counts).

## Step 15: Generate Handoff Prompt

Create a prompt the user pastes into a NEW CC session to verify the install. Base it on what was ACTUALLY installed:

- Skill count and command list (from successful installs)
- What was removed (only if actually removed)
- Backup location
- Specific test: "Try `/skippy:progress` in any project with `.planning/`"
- For e2e: "Run `/skippy:plan` on a real phase"

**Show the user** the handoff prompt AND save it to `$BACKUP_DIR/verify-prompt.md`.

**Ask:** "Install complete. Ready to start a fresh session and verify?"

## Done

Tell the user:
1. Backup + restore script: `$BACKUP_DIR/` (location shown during Step 2)
2. Install log: `$BACKUP_DIR/install-log.md`
3. Change manifest: `$BACKUP_DIR/changes.md`
4. Skills installed, commands available
5. What was removed
6. "Paste the handoff prompt into a new session to verify"
