# skippy-agentspace Install Process

First-time installation. For updates, see `update-process.md`.

**Shared procedures (backup, logging, diff, smoke test, etc.) are in `process.md`. Read it first.**

**If any step fails: run `$BACKUP_DIR/restore.sh --force` to roll back. See process.md Failure Protocol.**

## How This Install Works

This is an **interactive, step-by-step** install. You do NOT run all steps automatically. For each step:

1. **LOG** -- write what you're about to do to `$LOG_FILE` BEFORE doing it
2. **Explain** -- tell the user what this step does and why
3. **Ask** -- use the `AskUserQuestion` tool with structured choices (checkboxes/radio). NEVER ask free-text questions. The user should click, not type.
4. **Execute** -- run the step
5. **LOG** -- write results to `$LOG_FILE` IMMEDIATELY after execution, BEFORE showing the user
6. **Show** -- display the log output / results
7. **Confirm** -- use `AskUserQuestion` with "Looks good / Investigate / Rollback" choices

### Real-Time Logging (HARD ENFORCED)

**LOG EVERYTHING. LOG IT NOW. NOT LATER. NOT IN A BATCH. NOW.**

Every Bash command, every Read, every Edit, every user choice, every result -- appended to `$LOG_FILE` IMMEDIATELY after it happens. Not at the end of the step. Not at the checkpoint. After EACH action.

**The pattern for EVERY action inside a step:**
1. Append to `$LOG_FILE`: `[CMD] the command you're about to run`
2. Run the command
3. Append to `$LOG_FILE`: `[PASS|FAIL|SKIP|WARN|INFO] the result`

**What gets logged:**
- `[CMD]` -- every bash command, every file read, every tool call (BEFORE running)
- `[PASS]` -- successful result with output summary
- `[FAIL]` -- failure with the actual error message
- `[SKIP]` -- step or action skipped with reason
- `[WARN]` -- non-blocking issue detected
- `[INFO]` -- discovery, context, or user choice recorded
- `[ASK]` -- question presented to user + which option they chose

**Between every step is a `LOG CHECKPOINT` marker.** You MUST NOT proceed past a checkpoint until `$LOG_FILE` contains the complete record of EVERY action from the previous step -- not a summary, the actual commands and results.

**If you realize you forgot to log something: STOP. Log it NOW before doing anything else.**
**If a step has 5 commands, the log should have 5 `[CMD]` + 5 result entries from that step.**

**CRITICAL: Every question MUST use the `AskUserQuestion` tool with predefined options. No free-text prompts. No "type 1, 2, or 3." Click-only interaction.**

### Step 0: Install Mode

Before anything else, use AskUserQuestion:

**Question:** "How would you like to install?"
**Options:**
- Follow defaults -- standard paths, recommended settings. Shows each step but only asks if something looks wrong.
- Guided -- walk through every step. You approve each one before it runs. (recommended)
- Discover -- scan your system first, show what's found, then decide together.

Default: Guided.

In all modes, EVERY step is logged to `$BACKUP_DIR/install-log.md`. The log captures what was done even if the user chose defaults.

---

## Step 1: Present Overview and Ask Install Mode

**DO NOT run any bash commands or system discovery yet.** First, present the user a table summarizing all install steps:

| Step | Action |
|------|--------|
| 2 | Backup ~/.claude/, ~/.config/pai/ (+ pai-private if exists) with restore script |
| 3 | Discover consumed sources (GSD, OMC, PAUL, Open Brain) |
| 4 | Pre-install diff -- compare repo skills vs installed versions |
| 5 | Capture current skill/command counts |
| 6 | Ensure symlink architecture |
| 7 | Command collision check |
| 8 | Remove old marketplace commands and agents (moved to /tmp) |
| 9 | Migrate skippy-dev to skippy |
| 10 | Copy skippy skills |
| 11 | Command routing setup |
| 12 | Reference doc and path portability check |
| 13 | After inventory + eval baseline |
| 14 | OMC hook audit |
| 15 | Post-install smoke test |
| 16 | Change manifest |
| 17 | Generate handoff/verification prompt |
| 18 | Save install config |

Then immediately use AskUserQuestion to ask the install mode. Do NOT start reading system state until the user has chosen a mode.

Then read `docs/process.md` silently -- do not show its contents to the user. It's internal reference for you.

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 1 must be in `$LOG_FILE`. Verify: install mode chosen, timestamp.**

---

## Step 2: Backup

Follow process.md "Backup" section. Backup location is determined by process.md (Desktop if it exists, otherwise ~/.cache/).

**Show the user:**
- What directories will be backed up (discovered, not assumed)
- Total size estimate
- Backup location
- Restore command: `bash $BACKUP_DIR/restore.sh`

**Ask (AskUserQuestion):** "Proceed with backup?" -- options: Proceed / Change location / Skip (not recommended)

**After:** Show backup results -- files copied, sizes, restore.sh location. Confirm rollback smoke test passed.

Start the install log: `$BACKUP_DIR/install-log.md`.

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 2 must be in `$LOG_FILE`. Verify: backup location, sizes, restore.sh path, rollback test result.**

---

## Step 3: Discover Consumed Sources

Read `upstreams/*/upstream.json` for marketplace definitions. Read `.planning/audits/` for audit data. Read `CLAUDE.md` "Consumed Sources" table.

**Show the user:**
- Table of consumed sources (GSD, OMC, PAUL, Open Brain)
- What skippy takes from each
- What skippy replaces

**Ask (AskUserQuestion):** "Sources reviewed." -- options: Continue / Tell me more about a source / Skip

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 3 must be in `$LOG_FILE`. Verify: upstream count, sources found, audit data location.**

---

## Step 4: Pre-Install Diff

Follow process.md "Pre-Install/Update Diff" section.

**Show the user:**
- Table: each skill, whether it's NEW / IDENTICAL / DIFFERS
- For DIFFERS: which side is newer, what files differ
- Warning if installed version has extra files (evals, custom config) that would be lost

**For EVERY skill that DIFFERS (not just ones with installed-only files), diff the SKILL.md content and assess:**
- Is the repo version an upgrade (more content, new commands, new references)?
- Is the installed version richer (production customizations, inline content the repo skeleton lacks)?
- Are they roughly equivalent (just metadata differences)?

Show the assessment per skill. This determines whether each skill gets: repo overwrites installed, installed stays and repo adds new files, or skip entirely.

For skills where repo is clearly an upgrade:
**Ask (AskUserQuestion):** "These N skills would be upgraded by the repo version." -- options: Approve all / Review individual / Skip

For skills where installed is richer:
**Ask (AskUserQuestion):** "These N skills have richer installed versions." -- options: Add repo-only files (keep installed) / Review individual / Skip

For skills WITH installed-only files (core, deploy-service, etc.):

First, use AI judgment: compare the repo SKILL.md vs installed SKILL.md. If the installed version is richer/more current than the repo version, recommend SKIP (the repo would be a downgrade). If the repo adds new commands or references the installed doesn't have, recommend MERGE.

**Ask (AskUserQuestion) per skill:** "Skill X: [your assessment]" -- options:
- Skip (keep installed as-is -- recommended when installed is richer)
- Merge additive (add repo files, keep installed files, overwrite shared files)
- Merge selective (show file-by-file, choose which to take)
- Clean replace (delete installed-only files -- NOT recommended)

**Default depends on assessment. NEVER clean-replace without explicit approval.**

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 4 must be in `$LOG_FILE`. Verify: per-skill diff status (NEW/IDENTICAL/DIFFERS), user merge choices.**

---

## Step 5: Before Inventory

Follow process.md "Before/After Inventory" -- capture the "before" snapshot.

**Show the user:**
- Current skill count
- Current command count
- Where skills live (symlink target or direct directory)

**Ask (AskUserQuestion):** "Current setup captured." -- options: Continue / Show details / Stop

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 5 must be in `$LOG_FILE`. Verify: skill count, command count, symlink target.**

---

## Step 6: Ensure Symlink Architecture

Check if `~/.claude/skills` is a single symlink to `~/.config/pai/Skills`.

```bash
target=$(readlink "$HOME/.claude/skills" 2>/dev/null || echo "NOT_A_SYMLINK")
```

**Show the user** what was found:
- "Already using single symlink architecture -- no changes needed" OR
- "Found N individual symlinks -- need to migrate to single symlink" OR
- "No skills directory found -- will create from scratch"

**Ask (AskUserQuestion, only if changes needed):** "Symlink migration needed." -- options: Proceed / Show what will change / Skip

**Execute:**
- If already correct: skip
- If directory of individual symlinks: migrate (move real dirs to PAI, remove individual symlinks, move .DS_Store to /tmp, create single symlink)
- If doesn't exist: `mkdir -p "$HOME/.config/pai/Skills" && ln -s "$HOME/.config/pai/Skills" "$HOME/.claude/skills"`

**Show:** result and verification (`readlink ~/.claude/skills`)

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 6 must be in `$LOG_FILE`. Verify: symlink state (already correct / migrated / created), readlink output.**

---

## Step 7: Command Collision Check

Follow process.md "Command Collision Check" section.

**Show the user:**
- Table of any collisions found
- Which commands coexist safely (different names) vs actual conflicts (same name)

**Ask (AskUserQuestion):** "Collision check complete." -- options: Continue / Resolve a collision / Skip

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 7 must be in `$LOG_FILE`. Verify: collisions found (or none), resolution choices.**

---

## Step 8: Remove Old Marketplace Commands and Agents

Follow process.md "Consumed Source Cleanup" section. Move to /tmp, never rm.

**Show the user** what will be removed (scan before acting):
- Count GSD commands, agents, core, patches directories that exist
- Report OMC status (keeping, with reason)
- Or: "No GSD/OMC found -- nothing to remove."

**Ask (AskUserQuestion):** "Ready to remove old commands and agents." -- options: Proceed (moved to /tmp) / Show what will be removed / Skip

**Execute** the cleanup from process.md. Run the verification check at the end.

**Show:** what was removed, what was kept, verification result.

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 8 must be in `$LOG_FILE`. Verify: each item removed with /tmp path, agent count removed, verification result.**

---

## Step 9: Migrate skippy-dev to skippy (if needed)

The skill directory was renamed from `skippy-dev` to `skippy`. If the installed system has the old name, migrate it:

```bash
PAI_SKILLS="${SKILLS_TARGET:-$HOME/.config/pai/Skills}"
if [[ -d "$PAI_SKILLS/skippy-dev" ]] && [[ ! -d "$PAI_SKILLS/skippy" ]]; then
    mv "$PAI_SKILLS/skippy-dev" "$PAI_SKILLS/skippy"
    echo "MIGRATED: skippy-dev -> skippy"
elif [[ -d "$PAI_SKILLS/skippy-dev" ]] && [[ -d "$PAI_SKILLS/skippy" ]]; then
    # Both exist -- merge skippy-dev into skippy, then remove old
    rsync -a "$PAI_SKILLS/skippy-dev/" "$PAI_SKILLS/skippy/"
    mv "$PAI_SKILLS/skippy-dev" "/tmp/skippy-dev-migrated-$$"
    echo "MERGED: skippy-dev into skippy (old moved to /tmp)"
fi
```

Also clean up old command routing if it exists:
```bash
if [[ -d "$HOME/.claude/commands/skippy-dev" ]]; then
    mv "$HOME/.claude/commands/skippy-dev" "/tmp/skippy-dev-commands-$$"
    echo "CLEANED: old ~/.claude/commands/skippy-dev"
fi
```

**Log all migration actions. Show the user what was migrated.**

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 9 must be in `$LOG_FILE`. Verify: migration actions taken (or skipped), old paths cleaned.**

---

## Step 10: Copy Skippy Skills

**Show the user:**
- List of skills to install with command counts
- Install target directory (`$SKILLS_TARGET` from discovery)

**Ask (AskUserQuestion):** "Ready to install skills." -- options: Proceed / Show skill list / Skip

**Execute:**
Read `/tmp/skippy-install-state.txt` with the Read tool to get SKILLS_TARGET, then:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_SKILLS="$REPO_ROOT/skills"
# Use discovered skills target from state file (read via Read tool, not source)
PAI_SKILLS="${SKILLS_TARGET:-$HOME/.config/pai/Skills}"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    if command -v rsync >/dev/null 2>&1; then
        # ADDITIVE: copies repo files in, preserves installed-only files
        rsync -a "$skill_dir" "$PAI_SKILLS/$name/"
    else
        cp -R "$skill_dir" "$PAI_SKILLS/$name/"
    fi
    echo "INSTALLED: $name"
done
```

**Default is additive** (rsync without --delete). Installed-only files (evals/, custom configs, extra references) are preserved. If the user chose "clean replace" for a specific skill during Step 4 diff, use `rsync -a --delete` for that skill only.

**Show:** each skill installed with its commands listed.

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 10 must be in `$LOG_FILE`. Verify: each skill installed with command list, rsync/cp method used.**

---

## Step 11: Command Routing Setup

Claude Code discovers slash commands from `~/.claude/commands/<prefix>/`. Skills installed via `~/.claude/skills/` have their commands in the skill directory, but they also need to be linked into `~/.claude/commands/` for slash command routing.

**For each skill that has a `commands/` directory, symlink the whole directory:**
```bash
for skill_dir in "$PAI_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    if [[ -d "$skill_dir/commands" ]]; then
        ln -sfn "$skill_dir/commands" "$HOME/.claude/commands/$name"
        echo "ROUTED: /$name:* ($(ls "$skill_dir/commands/"*.md 2>/dev/null | wc -l | tr -d ' ') commands)"
    fi
done
```

One symlink per skill, not per command. All commands in the skill are automatically available.

**Show the user:** which skills have routed commands.

**Ask (AskUserQuestion):** "Command routing set up." -- options: Continue / Show command list / Skip

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 11 must be in `$LOG_FILE`. Verify: each skill routed with command count.**

---

## Step 12: Reference Doc and Path Portability Check

Follow process.md "Reference Doc Completeness Check".

**Additionally, check for non-portable paths in command files:**
```bash
for cmd_file in "$PAI_SKILLS"/*/commands/*.md; do
    # Check for repo-relative paths (skills/skippy-dev/agents/ etc.)
    if grep -q 'skills/skippy-dev/' "$cmd_file" 2>/dev/null; then
        echo "NON-PORTABLE: $cmd_file references repo-relative path 'skills/skippy-dev/'"
    fi
    # Check for hardcoded absolute paths
    if grep -q '/Volumes/' "$cmd_file" 2>/dev/null; then
        echo "HARDCODED: $cmd_file contains absolute /Volumes/ path"
    fi
done
```

Non-portable paths should use relative references (e.g., `references/` not `~/.config/pai/Skills/skippy-dev/references/`) or `${CLAUDE_SKILL_DIR}` variables.

**Show the user:** OK/MISSING table for referenced docs + any non-portable path warnings.

**Also check for stale/orphaned files** -- files that exist in the installed skill but are NOT referenced by any command or SKILL.md:
- `bin/` directories alongside `scripts/` (likely pre-migration artifacts)
- `.bak` or `.backup` files
- Files in both `bin/` and `scripts/` with the same name (duplicates with different logic)

Log stale files separately. Don't delete -- just report for user awareness.

**Ask (AskUserQuestion, only if issues found):** "Path issues found." -- options: Investigate / Continue anyway / Rollback

Any MISSING reference is a blocker -- do not proceed until resolved.

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 12 must be in `$LOG_FILE`. Verify: OK/MISSING per reference doc, any non-portable path warnings.**

---

## Step 13: After Inventory + Eval Baseline

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

**Ask (AskUserQuestion):** "Inventory captured." -- options: Looks good / Show details / Investigate

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 13 must be in `$LOG_FILE`. Verify: before/after counts, delta, eval baseline scores.**

---

## Step 14: Hook Audit (OMC + Open Brain)

### 14a: OMC Hook Audit

Follow process.md "OMC Hook Audit" section. Skip if no OMC.

**Show the user:** any warnings about bad hooks.

**Ask** (only if warnings): "Remove these hooks?"

### 14b: Open Brain Integration

Open Brain provides semantic memory across sessions. Three hooks must be registered in `~/.claude/settings.json`, and the agent token must be available.

**Check these in order:**

1. **OPEN_BRAIN_AGENT_TOKEN** -- check `settings.json` env block and shell environment
   - If missing: fetch from vaultwarden (`mcp2cli vaultwarden-secrets get_credential --params '{"query": "Open Brain - Agent Token"}'`)
   - Add to `settings.json` env block: `"OPEN_BRAIN_AGENT_TOKEN": "<token>"`

2. **OB hooks in settings.json** -- check for all 3:
   - `SessionStart`: `bun run <open-brain-repo>/hooks/open-brain-session-load.ts` (timeout: 10)
   - `PreCompact`: `bun run <open-brain-repo>/hooks/open-brain-session-save.ts` (timeout: 15)
   - `SessionEnd`: `bun run <open-brain-repo>/hooks/open-brain-session-capture.ts` (timeout: 15, async: true)
   - The `<open-brain-repo>` path is discovered from: `upstreams/open-brain/upstream.json` or ask user

3. **mcp2cli open-brain service** -- verify `mcp2cli open-brain --help` works
   - If not configured: check `~/.config/mcp2cli/services.json` for the open-brain entry
   - Service URL: `http://10.71.20.15:3100/mcp` with bearer auth

4. **OB server reachability** -- `curl -sf --max-time 3 http://10.71.20.15:3100/mcp` with an init request
   - If unreachable: warn but don't block (OB is best-effort infrastructure)

**Show the user:**
```
Open Brain Integration:
  Token: set / MISSING
  Hooks: 3/3 registered / N/3 (missing: X, Y)
  mcp2cli: configured / NOT configured
  Server: reachable / unreachable (non-blocking)
```

**Ask (AskUserQuestion):** "Open Brain integration status." -- options: Fix missing items / Continue (OB is optional) / Skip

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 14 must be in `$LOG_FILE`. Verify: OMC hooks, OB token status, OB hook registration, mcp2cli status, server reachability.**

---

## Step 15: Post-Install Smoke Test

Follow process.md "Post-Install Smoke Test" section.

**Show the user:**
- Symlink check: PASS/FAIL
- Skill count check: PASS/FAIL
- SKILL.md presence: PASS/FAIL
- Skippy commands present: PASS/FAIL
- GSD removed: PASS/FAIL
- Broken symlinks: PASS/FAIL
- Open Brain hooks: PASS/WARN (3/3 registered)
- OB token: PASS/WARN (set in env)
- PAI Skills symlinks: PASS/WARN (session-wrap, capture-session, brain, session-start point to SAS)

**Ask (AskUserQuestion):** "Smoke test results shown." -- options: Continue to handoff / Investigate failures / Rollback

If any FAIL: options become: Investigate / Rollback / Continue anyway (not recommended)

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 15 must be in `$LOG_FILE`. Verify: each smoke test PASS/FAIL with details.**

---

## Step 16: Change Manifest

Follow process.md "Change Manifest" section. Write to `$BACKUP_DIR/changes.md`.

**Show the user:** the manifest summary (added/updated/removed/unchanged counts).

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 16 must be in `$LOG_FILE`. Verify: added/updated/removed/unchanged counts.**

---

## Step 17: Generate Handoff Prompt

Create a prompt the user pastes into a NEW CC session to verify the install. Base it on what was ACTUALLY installed:

- Skill count and command list (from successful installs)
- What was removed (only if actually removed)
- Backup location and restore command
- Verification tests to run:
  1. "Run `/skippy:progress` in any project with `.planning/`"
  2. "Run `/skippy:plan --skip-research --skip-verify` on a test phase to verify the plan command works"
  3. "Confirm no `gsd:*` commands appear in the skill list"
- After verification passes:
  - "To consume additional marketplace sources, run `/skippy:consume <github-repo-url>` for each source you want to audit and absorb."
  - List the default consumed sources (GSD, OMC, PAUL, Open Brain) and note they're already included.

**Show the user** the handoff prompt AND save it to `$BACKUP_DIR/verify-prompt.md`.

**Ask (AskUserQuestion):** "Install complete." -- options: Copy handoff prompt / Show summary again / Rollback

---
**LOG CHECKPOINT: Every `[CMD]` and result from Step 17 must be in `$LOG_FILE`. Verify: handoff prompt path, verification test list.**

---

## Step 18: Save Install Config

Write permanent config so future updates have defaults. Follow process.md "Install config (permanent)" section.

## Done

Tell the user:
1. Backup + restore script: `$BACKUP_DIR/` (location shown during Step 2)
2. Install log: `$BACKUP_DIR/install-log.md`
3. Change manifest: `$BACKUP_DIR/changes.md`
4. Install config: `$SKIPPY_CONFIG` (used by future updates)
5. Skills installed, commands available
6. What was removed
7. "Paste the handoff prompt into a new session to verify"
