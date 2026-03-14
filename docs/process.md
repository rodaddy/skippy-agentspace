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

# Restore each backed-up directory
[[ -d "$BACKUP_DIR/dot-claude" ]] && rsync -al --delete "$BACKUP_DIR/dot-claude/" "$HOME/.claude/" && echo "RESTORED: ~/.claude/"
[[ -d "$BACKUP_DIR/config-pai" ]] && rsync -al --delete "$BACKUP_DIR/config-pai/" "$HOME/.config/pai/" && echo "RESTORED: ~/.config/pai/"
[[ -d "$BACKUP_DIR/config-pai-private" ]] && rsync -al --delete "$BACKUP_DIR/config-pai-private/" "$HOME/.config/pai-private/" && echo "RESTORED: ~/.config/pai-private/"

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

CC must write a step-by-step log during install/update. Every action, every skip, every failure.

```bash
LOG_FILE="$BACKUP_DIR/install-log.md"
```

Log format:
```markdown
# Install Log -- YYYY-MM-DD HH:MM

## Step 1: Backup
- [PASS] ~/.claude/ backed up (X files)
- [PASS] ~/.config/pai/ backed up (Y files)
- [PASS] restore.sh created and verified

## Step 2: ...
```

Write to the log AS you go, not at the end. If the process crashes mid-way, the log shows exactly where it stopped.

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

## Failure Protocol

If ANY step fails and cannot be quickly resolved:

1. Log the failure in install-log.md
2. Run `$BACKUP_DIR/restore.sh --force`
3. Report: "Install failed at Step N. System restored to pre-install state. Failure: [details]"

Do NOT continue past a failure hoping it'll resolve itself.
