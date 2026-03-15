# skippy-agentspace Shared Process

Standard operating procedures shared between install and update. Both `install-process.md` and `update-process.md` reference this file for common steps.

## Backup (MANDATORY -- always first)

**Default location:** User's Desktop if it exists, otherwise `~/.cache/skippy-backups/`.

The backup should be somewhere visible and obvious -- not buried in a hidden directory.

```bash
if [[ -d "$HOME/Desktop" ]]; then
    BACKUP_DIR="$HOME/Desktop/skippy-backup-$(date +%Y%m%d-%H%M%S)"
else
    BACKUP_DIR="$HOME/.cache/skippy-backups/pre-install-$(date +%Y%m%d-%H%M%S)"
fi
```

Ask the user: "Backup will go to `$BACKUP_DIR`. Change location?" before proceeding.

### Targeted vs Full Backup

Calculate the size of what will be backed up. If total is **under 50MB**, back up everything without asking -- it's trivial.

If total is **over 50MB**, use AskUserQuestion:

**Question:** "Backup would be X GB (Y files). How should we proceed?"
**Options:**
- Targeted -- only back up directories the install will modify (~50MB: skills, commands, get-shit-done)
- Full -- back up everything (~X GB: all of ~/.claude/ + ~/.config/pai/)
- Skip backup (not recommended -- no rollback)

**Targeted backup** only captures:
```bash
# Only what the install touches
rsync -al "$HOME/.config/pai/Skills/" "$BACKUP_DIR/config-pai-Skills/"
[[ -d "$HOME/.claude/commands/gsd" ]] && rsync -al "$HOME/.claude/commands/gsd/" "$BACKUP_DIR/commands-gsd/"
[[ -d "$HOME/.claude/get-shit-done" ]] && rsync -al "$HOME/.claude/get-shit-done/" "$BACKUP_DIR/get-shit-done/"
# GSD agent definitions (hijack Claude Code's agent routing if present)
mkdir -p "$BACKUP_DIR/agents-gsd"
for agent in "$HOME/.claude/agents"/gsd-*.md; do
    [[ -f "$agent" ]] && cp "$agent" "$BACKUP_DIR/agents-gsd/"
done
[[ -d "$HOME/.config/pai-private" ]] && rsync -al "$HOME/.config/pai-private/" "$BACKUP_DIR/config-pai-private/"
```

**Full backup** captures everything (the default from the "How" section above).

### Discover the user's setup

Before backing up, map what exists:

```bash
echo "=== Environment Discovery ==="

# Where do skills live?
if [[ -L "$HOME/.claude/skills" ]]; then
    SKILLS_TARGET="$(readlink "$HOME/.claude/skills")"
    echo "Skills symlink: ~/.claude/skills -> $SKILLS_TARGET"
elif [[ -d "$HOME/.claude/skills" ]]; then
    SKILLS_TARGET="$HOME/.claude/skills"
    echo "Skills directory: ~/.claude/skills (no symlink)"
else
    SKILLS_TARGET=""
    echo "Skills: not found (fresh install)"
fi

# What config dirs exist?
BACKUP_TARGETS=("$HOME/.claude")
[[ -d "$HOME/.config/pai" ]] && BACKUP_TARGETS+=("$HOME/.config/pai")
[[ -d "$HOME/.config/pai-private" ]] && BACKUP_TARGETS+=("$HOME/.config/pai-private")

echo "Backup targets: ${BACKUP_TARGETS[*]}"
```

Save `$SKILLS_TARGET` -- this is where skills get installed. If empty, the install creates it.

### What to backup

Everything the install might affect, plus private config for safety:

| Target | Why | Always? |
|--------|-----|---------|
| `~/.claude/` | Skills symlink, commands, settings, plugins | Yes |
| `~/.config/pai/` | Skills, hooks, rules (if exists) | If exists |
| `~/.config/pai-private/` | Private config, memory, personas (if exists) | If exists -- NEVER write to, backup only |

### How

```bash
BACKUP_DIR="$HOME/Desktop/skippy-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Preserve symlinks as symlinks (-l flag)
rsync -al "$HOME/.claude/" "$BACKUP_DIR/dot-claude/"
[[ -d "$HOME/.config/pai" ]] && rsync -al "$HOME/.config/pai/" "$BACKUP_DIR/config-pai/"
[[ -d "$HOME/.config/pai-private" ]] && rsync -al "$HOME/.config/pai-private/" "$BACKUP_DIR/config-pai-private/"

# Save symlink target separately (rsync can mangle on restore)
if [[ -L "$HOME/.claude/skills" ]]; then
    readlink "$HOME/.claude/skills" > "$BACKUP_DIR/skills-symlink-target.txt"
fi

# Save discovery results for restore
echo "SKILLS_TARGET=$SKILLS_TARGET" > "$BACKUP_DIR/environment.txt"
echo "BACKUP_TARGETS=${BACKUP_TARGETS[*]}" >> "$BACKUP_DIR/environment.txt"
```

If rsync unavailable: `cp -RP` (preserves symlinks on macOS/Linux).

**NEVER write to `~/.config/pai-private/`.** It's backed up for safety but the install only touches `~/.config/pai/Skills/` (or wherever `$SKILLS_TARGET` points).

### Restore script

**Use the Write tool (not bash heredoc) to create restore.sh.** Bash heredocs containing `~/.claude/` paths will be blocked by security hooks. The Write tool bypasses this.

Write `$BACKUP_DIR/restore.sh`:

```bash
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE'
#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" != "--force" ]] && [[ "${1:-}" != "-y" ]]; then
    echo "=== Restoring from $BACKUP_DIR ==="
    echo "This will restore all backed-up directories to their pre-install state."
    echo ""
    echo "Will restore:"
    [[ -d "$BACKUP_DIR/dot-claude" ]] && echo "  ~/.claude/"
    [[ -d "$BACKUP_DIR/config-pai" ]] && echo "  ~/.config/pai/"
    [[ -d "$BACKUP_DIR/config-pai-private" ]] && echo "  ~/.config/pai-private/"
    echo ""
    read -p "Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

# Restore symlink first (before rsync overwrites the directory)
if [[ -f "$BACKUP_DIR/skills-symlink-target.txt" ]]; then
    rm -rf "$HOME/.claude/skills"
    ln -s "$(cat "$BACKUP_DIR/skills-symlink-target.txt")" "$HOME/.claude/skills"
    echo "RESTORED: ~/.claude/skills symlink"
fi

# Detect backup type (full vs targeted) and restore accordingly
if [[ -d "$BACKUP_DIR/dot-claude" ]]; then
    # Full backup
    rsync -al --delete "$BACKUP_DIR/dot-claude/" "$HOME/.claude/" && echo "RESTORED: ~/.claude/"
    [[ -d "$BACKUP_DIR/config-pai" ]] && rsync -al --delete "$BACKUP_DIR/config-pai/" "$HOME/.config/pai/" && echo "RESTORED: ~/.config/pai/"
    [[ -d "$BACKUP_DIR/config-pai-private" ]] && rsync -al --delete "$BACKUP_DIR/config-pai-private/" "$HOME/.config/pai-private/" && echo "RESTORED: ~/.config/pai-private/"
else
    # Targeted backup -- restore only what was backed up
    [[ -d "$BACKUP_DIR/config-pai-Skills" ]] && rsync -al --delete "$BACKUP_DIR/config-pai-Skills/" "$HOME/.config/pai/Skills/" && echo "RESTORED: ~/.config/pai/Skills/"
    [[ -d "$BACKUP_DIR/commands-gsd" ]] && rsync -al "$BACKUP_DIR/commands-gsd/" "$HOME/.claude/commands/gsd/" && echo "RESTORED: ~/.claude/commands/gsd/"
    [[ -d "$BACKUP_DIR/get-shit-done" ]] && rsync -al "$BACKUP_DIR/get-shit-done/" "$HOME/.claude/get-shit-done/" && echo "RESTORED: ~/.claude/get-shit-done/"
    [[ -d "$BACKUP_DIR/config-pai-private" ]] && rsync -al --delete "$BACKUP_DIR/config-pai-private/" "$HOME/.config/pai-private/" && echo "RESTORED: ~/.config/pai-private/"
fi

echo "=== Restored. Start a new Claude Code session to pick up changes. ==="
RESTORE
chmod +x "$BACKUP_DIR/restore.sh"
```

### Rollback smoke test

After creating restore.sh, verify it would work:
```bash
# Dry-run: check restore script is executable and backup dirs exist
[[ -x "$BACKUP_DIR/restore.sh" ]] && echo "PASS: restore.sh executable"
[[ -d "$BACKUP_DIR/dot-claude" ]] && echo "PASS: dot-claude backup exists"
[[ -d "$BACKUP_DIR/config-pai" ]] && echo "PASS: config-pai backup exists"
```

Do NOT proceed with install/update if rollback isn't verified.

## Install Log (MANDATORY)

CC must write a step-by-step log during install/update. The log is the audit trail -- it captures everything so the user (or a future session) can understand exactly what happened.

```bash
LOG_FILE="$BACKUP_DIR/install-log.md"
```

**Write to the log AS you go, not at the end.** If the process crashes mid-way, the log shows exactly where it stopped.

**Important:** The log file is created during the backup step, but discovery and other commands ran before it existed. After creating the log file, **retroactively write all commands and results from earlier steps** (environment discovery, size calculations, user choices) so the log is complete from the start of the session.

**CRITICAL LOGGING RULE: After EVERY step, BEFORE presenting results to the user, append that step's entries to the log file using the Write or Edit tool. Do NOT batch log writes. Do NOT skip logging because you're about to show the user. The log is the audit trail -- if it's not in the log, it didn't happen. If you find yourself showing results without having written to the log first, STOP and write the log NOW.**

### What to log for EVERY step

| Category | What to log | Example |
|----------|------------|---------|
| **Discovery** | Everything found during system scan | "Skills dir: symlink to /Users/rico/.config/pai/Skills (75 skills)" |
| **User choice** | Which option the user selected | "Install mode: Guided" |
| **Action** | What was executed | "rsync -a skills/skippy-dev/ ~/.config/pai/Skills/skippy-dev/" |
| **Result** | Outcome of each action | "[PASS] skippy-dev installed (8 commands)" |
| **Skip** | Steps skipped and why | "[SKIP] OMC removal -- not installed" |
| **Warning** | Non-blocking issues | "[WARN] Installed humanizer has evals/results.md not in repo -- preserved" |
| **Failure** | Anything that failed | "[FAIL] Reference doc verification-loops.md missing" |
| **Diff** | Before/after comparisons | "Before: 75 skills, 42 commands. After: 75 skills, 47 commands. Delta: +5 commands" |

### Log format

```markdown
# Install Log -- YYYY-MM-DD HH:MM:SS

## Environment
- OS: macOS / Linux / WSL2
- Shell: zsh / bash
- Claude Code: vX.Y.Z
- Repo: rodaddy/skippy-agentspace @ commit XXXXXXX
- Branch: feat/orchestration-protocol

## Install Mode
User selected: Guided

## Step 2: Backup
- [PASS] ~/.claude/ backed up (1.2G, 312 files)
- [PASS] ~/.config/pai/ backed up (800M, 198 files)
- [PASS] ~/.config/pai-private/ backed up (45M, 23 files)
- [PASS] restore.sh created and verified
- [INFO] Backup location: ~/Desktop/skippy-backup-20260314-130500/

## Step 3: Discover Consumed Sources
- [INFO] Found 4 upstream definitions: gsd, omc, paul, open-brain
- [INFO] Audit data: .planning/audits/marketplace-audit-2026-03-13.md (93 commands)

## Step 4: Pre-Install Diff
- [IDENTICAL] core
- [DIFFERS] skippy-dev (repo has 5 new commands, installed has evals/)
- [NEW] (not installed yet -- will be added)
- User choice: Approve all

...etc for every step
```

### Log rules

1. **Timestamps** on every step header
2. **Exact commands** -- log the full bash command BEFORE running it, then log the result AFTER
3. **File counts and sizes** for backup/copy operations
4. **Full paths** for everything (not abbreviated)
5. **User choices** recorded verbatim (which AskUserQuestion option they picked)
6. **Diffs summarized** (not full file diffs -- just "N files differ")
7. **Errors include the actual error message** from bash, not just "it failed"
8. **One action per bash call** -- run one command, log it, then run the next. Do not batch.

Example log entry with command:
```markdown
- [CMD] `rsync -a /Volumes/.../skills/skippy-dev/ /Users/rico/.config/pai/Skills/skippy-dev/`
- [PASS] skippy-dev installed (8 commands: plan, execute, verify, quick, progress, cleanup, reconcile, update)
```

## Pre-Install/Update Diff (MANDATORY)

Before overwriting any skill, compare repo version vs installed version:

```bash
REPO_SKILLS="$(git rev-parse --show-toplevel)/skills"
PAI_SKILLS="$HOME/.config/pai/Skills"

for skill_dir in "$REPO_SKILLS"/*/; do
    name="$(basename "$skill_dir")"
    if [[ -d "$PAI_SKILLS/$name" ]]; then
        changes=$(diff -rq "$skill_dir" "$PAI_SKILLS/$name" 2>/dev/null | grep -v .DS_Store | wc -l | tr -d ' ')
        if [[ "$changes" -gt 0 ]]; then
            echo "DIFFERS: $name ($changes file differences)"
        else
            echo "IDENTICAL: $name"
        fi
    else
        echo "NEW: $name (not installed)"
    fi
done
```

Report the diff to the user. If the installed version has files the repo doesn't (e.g., evals/results.md from Karpathy loops), warn: "Installed version has extra files that will be lost."

**Never overwrite newer with older without explicit user approval.**

## Before/After Inventory

Capture skill + command counts before AND after:

```bash
# Before
echo "=== PRE inventory ===" > "$BACKUP_DIR/inventory-before.txt"
ls -d "$HOME/.config/pai/Skills"/*/ 2>/dev/null | wc -l >> "$BACKUP_DIR/inventory-before.txt"
find "$HOME/.config/pai/Skills" -path "*/commands/*.md" 2>/dev/null | wc -l >> "$BACKUP_DIR/inventory-before.txt"
```

After install/update, capture the same and diff:
```
Before: X skills, Y commands
After:  X skills, Y commands
Delta:  +N skills, +M commands
```

## Command Collision Check

Before installing, detect if new skippy commands share names with existing commands from other sources:

```bash
# List all existing command names
for cmd_dir in "$HOME/.claude/commands"/*/; do
    [[ -d "$cmd_dir" ]] || continue
    source_name="$(basename "$cmd_dir")"
    for cmd_file in "$cmd_dir"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        echo "$source_name:$(basename "$cmd_file" .md)"
    done
done
```

Compare against skippy commands being installed. Report overlaps:
```
COLLISION: skippy:cleanup vs gsd:cleanup
COLLISION: skippy:plan vs gsd:plan-phase (different name, same purpose)
```

Collisions with different names (like plan vs plan-phase) are fine -- they coexist. Same-name collisions need resolution.

## Consumed Source Cleanup

Remove artifacts from consumed marketplaces (GSD, OMC, PAUL) that interfere with skippy's own commands and agents. Move everything to /tmp -- never delete.

### GSD Cleanup

GSD installs to 4 locations. All must be removed:

```bash
# GSD slash commands
if [[ -d "$HOME/.claude/commands/gsd" ]]; then
    mv "$HOME/.claude/commands/gsd" "/tmp/gsd-commands-backup-$$"
    echo "REMOVED: ~/.claude/commands/gsd"
fi

# GSD core (workflows, templates, references)
if [[ -d "$HOME/.claude/get-shit-done" ]]; then
    mv "$HOME/.claude/get-shit-done" "/tmp/gsd-core-backup-$$"
    echo "REMOVED: ~/.claude/get-shit-done"
fi

# GSD agent definitions -- GLOB, not hardcoded names
# These hijack Claude Code's agent routing (gsd-planner, gsd-executor, etc.)
# GSD adds new agents across versions so a fixed list goes stale
mkdir -p "/tmp/gsd-agents-backup-$$"
for agent in "$HOME/.claude/agents"/gsd-*.md; do
    [[ -f "$agent" ]] || continue
    mv "$agent" "/tmp/gsd-agents-backup-$$/"
    echo "REMOVED: $(basename "$agent")"
done

# GSD local patches (leftover from GSD update system)
if [[ -d "$HOME/.claude/gsd-local-patches" ]]; then
    mv "$HOME/.claude/gsd-local-patches" "/tmp/gsd-patches-backup-$$"
    echo "REMOVED: ~/.claude/gsd-local-patches"
fi
```

### OMC Handling

OMC hooks provide value and commands coexist with skippy. Keep OMC installed. Report what's kept and why.

### Verification

After cleanup, confirm no GSD agents remain:
```bash
remaining=$(ls "$HOME/.claude/agents"/gsd-*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$remaining" -gt 0 ]]; then
    echo "FAIL: $remaining GSD agents still present"
else
    echo "PASS: No GSD agents remaining"
fi
```

## Reference Doc Completeness Check

After install, verify every file referenced by a command actually exists:

```bash
for cmd_file in "$HOME/.config/pai/Skills/skippy-dev/commands"/*.md; do
    grep -o 'references/[a-z-]*.md' "$cmd_file" 2>/dev/null | while read ref; do
        full_path="$HOME/.config/pai/Skills/skippy-dev/$ref"
        if [[ -f "$full_path" ]]; then
            echo "  OK: $ref"
        else
            echo "  MISSING: $ref"
        fi
    done
done
```

Any MISSING reference is a blocker. Do not proceed until resolved.

## Eval Baseline

If installed skills have `evals/results.md`, capture current scores:

```bash
find "$HOME/.config/pai/Skills" -path "*/evals/results.md" | while read results; do
    skill="$(basename "$(dirname "$(dirname "$results")")")"
    score=$(grep -o '[0-9]*/[0-9]*' "$results" | tail -1)
    echo "$skill: $score"
done
```

Save to `$BACKUP_DIR/eval-baseline.txt`. After install/update, compare. Score dropped? Flag it.

## OMC Hook Audit

Check for known problematic hooks after any OMC-related changes:

```bash
OMC_HOOKS="$HOME/.claude/plugins/cache/omc/oh-my-claudecode/*/hooks/hooks.json"
for hooks_file in $OMC_HOOKS; do
    [[ -f "$hooks_file" ]] || continue
    # Check for known bad hooks
    if grep -q "keyword-detector" "$hooks_file"; then
        echo "WARNING: keyword-detector.mjs still registered -- remove it"
    fi
    if grep -q "persistent-mode" "$hooks_file"; then
        echo "WARNING: persistent-mode.cjs still registered -- remove it"
    fi
done
```

## Post-Install Smoke Test

After everything is installed, run ONE real command to verify:

1. Find a project with `.planning/` directory
2. Run the equivalent of `/skippy:progress` logic:
   - Can it read STATE.md?
   - Can it read ROADMAP.md?
   - Does it report a coherent status?
3. Report PASS or FAIL

If no project with `.planning/` exists, verify at minimum:
- `ls ~/.claude/skills/skippy-dev/commands/` returns the expected commands
- Each command .md file is readable and has valid frontmatter

## Change Manifest

Write `$BACKUP_DIR/changes.md` summarizing what changed:

```markdown
# Changes -- YYYY-MM-DD

## Added
- skippy-dev/commands/plan.md
- skippy-dev/commands/execute.md
- ...

## Updated
- skippy-dev/references/plan-structure.md (3 lines changed)
- ...

## Removed
- ~/.claude/commands/gsd/ (moved to /tmp/gsd-commands-backup-XXXX)
- ...

## Unchanged
- 63 skills not touched
```

## State Persistence

Two state files: temporary (current session) and permanent (survives across sessions).

### Session state (temporary)

For the current install/update session. Lives in /tmp, lost on reboot -- that's fine.

```bash
STATE_FILE="/tmp/skippy-install-state.txt"
echo "BACKUP_DIR=$BACKUP_DIR" > "$STATE_FILE"
echo "SKILLS_TARGET=$SKILLS_TARGET" >> "$STATE_FILE"
echo "INSTALL_MODE=guided" >> "$STATE_FILE"
```

If you lose track of a variable (compaction, long session), read it back using the **Read tool** (not `source` in bash -- security hooks block sourcing from /tmp):
```
Read /tmp/skippy-install-state.txt
```
Then set the variables inline in your next bash call.

### Install config (permanent)

Saved during install, read during updates. Lives alongside the skills so it persists.

```bash
SKIPPY_CONFIG="${SKILLS_TARGET:-$HOME/.config/pai/Skills}/.skippy-config"
```

Written at the END of a successful install:
```bash
cat > "$SKIPPY_CONFIG" << CONFIG
# skippy-agentspace install config
# Written by install on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Read by update-process.md for defaults

SKILLS_TARGET=$SKILLS_TARGET
INSTALL_MODE=$INSTALL_MODE
BACKUP_LOCATION=$BACKUP_DIR
LAST_INSTALL=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LAST_REPO_COMMIT=$(git rev-parse HEAD)
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "local")
CONFIG
```

Updates read this first to get defaults:
```bash
SKIPPY_CONFIG="${HOME}/.config/pai/Skills/.skippy-config"
if [[ -f "$SKIPPY_CONFIG" ]]; then
    source "$SKIPPY_CONFIG"
    echo "Loaded install config from $SKIPPY_CONFIG"
    echo "  Skills target: $SKILLS_TARGET"
    echo "  Last install: $LAST_INSTALL"
    echo "  Last commit: $LAST_REPO_COMMIT"
else
    echo "No previous install config found -- using defaults"
fi
```

## AI Judgment (Why .md Not .sh)

The install process is a markdown instruction set, not a bash script, because CC can use judgment that scripts can't:

- If an installed-only file is `evals/results.md` with 24/24 passing, recommend "merge -- this skill has proven eval scores"
- If an installed-only file is a `.bak` backup file, recommend "safe to replace -- this is a leftover"
- If the diff shows the repo version has MORE commands than installed, flag "upgrade -- repo adds new capabilities"
- If the diff shows the installed version has custom references the repo doesn't, flag "custom content -- preserve"

**Read installed-only files when they have meaningful names (evals, configs, references). Use your judgment to recommend merge vs replace vs skip. Don't just list files mechanically.**

## Skip-Backup Warning

If the user skips the backup step, set a flag:

```bash
echo "BACKUP_SKIPPED=true" >> "$STATE_FILE"
```

For EVERY subsequent step that modifies the system, include in the AskUserQuestion options: "(no rollback available -- backup was skipped)"

## Stale File Detection

After additive rsync, check for files that exist in the installed skill but NOT in the repo AND are not user-custom content:

- Files with `.bak`, `.backup`, `.old` extensions -- likely stale
- Files that existed in a previous repo version but were removed -- likely stale
- Files in `evals/`, custom references, user configs -- likely intentional

Log stale files separately from preserved custom files so the user can clean up later.

## Failure Protocol

If ANY step fails and cannot be quickly resolved:

1. Log the failure in install-log.md
2. Run `$BACKUP_DIR/restore.sh --force`
3. Report: "Install failed at Step N. System restored to pre-install state. Failure: [details]"

Do NOT continue past a failure hoping it'll resolve itself.
