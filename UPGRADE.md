# Upgrading

Two upgrade paths: manual (works with any AI tool) and AI-assisted (Claude Code with skippy-dev installed).

## Manual Upgrade

Works with any AI tool -- Gemini, Codex, Claude, or no AI at all.

### 1. Pull Latest Changes

```bash
cd skippy-agentspace
git pull
```

If you have local modifications to tracked files, git may report merge conflicts. Resolve them normally (`git diff`, edit, `git add`).

### 2. Re-install Skills

```bash
bash tools/install.sh --all
```

This re-creates symlinks to pick up any new or restructured skills. Existing symlinks are updated in place.

### 3. Re-install Hooks

```bash
bash skills/core/hooks/install-hooks.sh
```

Hook installation is idempotent -- it merges PAI hooks into `~/.claude/settings.json` without affecting your existing settings or non-PAI hooks.

### 4. Verify

```bash
bash tools/verify.sh
```

Confirms prerequisites, skills, hooks, and commands are all healthy. Fix any FAIL items using the suggested commands.

### 5. Refresh Claude Code

Run `/clear` or restart your Claude Code session to pick up changes.

## AI-Assisted Upgrade

Requires Claude Code with the skippy-dev skill installed.

```
/skippy:upgrade
```

This handles the full upgrade workflow:

1. Snapshots current state (installed skills, hook count, modified files)
2. Pulls latest changes from the remote
3. Re-installs all skills and hooks
4. Runs verification
5. Compares post-upgrade state to pre-upgrade snapshot
6. Reports any conflicts if tracked files were locally modified

See `skills/skippy-dev/commands/upgrade.md` for the full command specification.

## What Gets Preserved

- **Custom skills** you created (not in upstream) are untouched -- install.sh only operates on skills in the repo's `skills/` directory
- **settings.json hooks** are merged non-destructively -- `install-hooks.sh` is idempotent and only adds/updates PAI hooks
- **Non-PAI settings** in `~/.claude/settings.json` (permissions, other hooks, custom config) are never modified
- **Your git history** is preserved -- `git pull` is a standard merge, not a force reset
