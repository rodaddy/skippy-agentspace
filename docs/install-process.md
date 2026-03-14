# skippy-agentspace Install Process

First-time installation. For updates, see `update-process.md`.

**Shared procedures (backup, logging, diff, smoke test, etc.) are in `process.md`. Read it first.**

**If any step fails: run `$BACKUP_DIR/restore.sh --force` to roll back. See process.md Failure Protocol.**

## Step 1: Read Shared Process

Read `docs/process.md` -- it defines backup, logging, diff, inventory, collision check, reference doc completeness, eval baseline, hook audit, smoke test, change manifest, and failure protocol. All of those apply here.

## Step 2: Backup

Follow process.md "Backup" section. Backup goes to `~/Desktop/skippy-backup-{timestamp}/`.

Start the install log: `$BACKUP_DIR/install-log.md`.

## Step 3: Discover Consumed Sources

Read `upstreams/*/upstream.json` for marketplace definitions. Read `.planning/audits/` for audit data. Read `CLAUDE.md` "Consumed Sources" table for the summary.

This tells you what skippy replaces and what it keeps from each source.

## Step 4: Pre-Install Diff

Follow process.md "Pre-Install/Update Diff" section. Compare repo skills vs installed skills. Report to user. Get approval before overwriting anything newer.

## Step 5: Before Inventory

Follow process.md "Before/After Inventory" -- capture the "before" snapshot.

## Step 6: Ensure Symlink Architecture

Check if `~/.claude/skills` is a single symlink to `~/.config/pai/Skills`:

```bash
target=$(readlink "$HOME/.claude/skills" 2>/dev/null || echo "NOT_A_SYMLINK")
```

- If `$target` ends with `.config/pai/Skills`: good, skip ahead
- If it's a directory of individual symlinks: migrate
  - Move non-symlink (real dir) skills into `~/.config/pai/Skills/`
  - Remove individual symlinks
  - Handle .DS_Store by moving to /tmp (not rm)
  - Create: `ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`
- If it doesn't exist: `mkdir -p "$HOME/.config/pai/Skills" && ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`

## Step 7: Command Collision Check

Follow process.md "Command Collision Check" section. Report overlaps before removing anything.

## Step 8: Remove Old Marketplace Commands

Only remove what exists. Move to /tmp, never rm.

```bash
if [[ -d "$HOME/.claude/commands/gsd" ]]; then
    mv "$HOME/.claude/commands/gsd" "/tmp/gsd-commands-backup-$$"
    echo "REMOVED: ~/.claude/commands/gsd"
fi
if [[ -d "$HOME/.claude/get-shit-done" ]]; then
    mv "$HOME/.claude/get-shit-done" "/tmp/gsd-core-backup-$$"
    echo "REMOVED: ~/.claude/get-shit-done"
fi
```

If neither exists: "No GSD installation found -- skipping."

**OMC (oh-my-claudecode):** Only relevant if the user has it installed.

```bash
if [[ -d "$HOME/.claude/plugins/cache/omc" ]]; then
    echo "OMC plugin detected."
    echo "  KEEP: OMC hooks (skill-injector adds keyword triggers, session-start loads state)"
    echo "  KEEP: OMC commands (different names from skippy -- they coexist)"
    echo "  CHECK: hooks.json for known bad hooks (see process.md OMC Hook Audit)"
else
    echo "No OMC installation found -- skipping."
fi
```

**No OMC required.** Claude Code discovers skills natively from `~/.claude/skills/*/SKILL.md`. Skippy works without any marketplace installed. OMC hooks are a nice-to-have, not a dependency.

## Step 9: Copy Skippy Skills

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

## Step 10: Reference Doc Completeness

Follow process.md "Reference Doc Completeness Check". Any MISSING reference is a blocker.

## Step 11: After Inventory + Eval Baseline

Follow process.md "Before/After Inventory" (capture "after") and "Eval Baseline" sections.

## Step 12: OMC Hook Audit

Follow process.md "OMC Hook Audit" section.

## Step 13: Post-Install Smoke Test

Follow process.md "Post-Install Smoke Test" section.

## Step 14: Change Manifest

Follow process.md "Change Manifest" section. Write to `$BACKUP_DIR/changes.md`.

## Step 15: Generate Handoff Prompt

Create a prompt the user pastes into a NEW CC session to verify the install. Base it on what was ACTUALLY installed (not hardcoded):

- Skill count and command list (from successful installs)
- What was removed (only if it was actually removed)
- Backup location
- Specific test: "Try `/skippy:progress` in any project with `.planning/`"
- For e2e: "Run `/skippy:plan` on a real phase"

Write to terminal AND save to `$BACKUP_DIR/verify-prompt.md`.

## Done

Tell the user:
1. Backup + restore script location (Desktop)
2. Install log location
3. Skills installed, commands available
4. What was removed
5. Paste the handoff prompt into a new session to verify
