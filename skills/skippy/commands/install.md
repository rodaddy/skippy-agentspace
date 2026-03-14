---
name: skippy:install
description: Install skippy-agentspace from GitHub repo -- clone, backup, copy skills, verify
argument-hint: "[--repo=rodaddy/skippy-agentspace]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---
<objective>
Full skippy-agentspace installation from a GitHub repo. Handles everything:
clone -> backup existing -> copy skills to PAI -> verify -> report.

The user runs this ONE command. Nothing else needed.
</objective>

<context>
Default repo: rodaddy/skippy-agentspace (override with --repo=owner/repo)
Install target: ~/.config/pai/Skills/ (where Claude Code discovers skills via ~/.claude/skills symlink)
Backup location: ~/.cache/skippy-backups/
</context>

<process>

## 1. Clone

```bash
REPO="${ARGUMENTS:-rodaddy/skippy-agentspace}"
CLONE_DIR="$(mktemp -d)/skippy-agentspace"
git clone --depth 1 "git@github.com:${REPO}.git" "$CLONE_DIR"
```

If SSH fails, retry with HTTPS:
```bash
git clone --depth 1 "https://github.com/${REPO}.git" "$CLONE_DIR"
```

## 2. Backup

Snapshot everything that will be touched:

```bash
BACKUP_DIR="$HOME/.cache/skippy-backups/pre-install-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
```

For each skill in `$CLONE_DIR/skills/*/`:
- If `~/.config/pai/Skills/<name>` exists, copy it to `$BACKUP_DIR/<name>`
- Report: "BACKUP: <name>"

## 3. Copy Skills

For each skill directory in `$CLONE_DIR/skills/*/`:
- Use `rsync -a --delete` to copy into `~/.config/pai/Skills/<name>/`
- If rsync unavailable: move existing to /tmp, then `cp -R`
- Report: "INSTALLED: <name> (N commands)"
- List the commands in each skill

## 4. Ensure Symlink Architecture

Check if `~/.claude/skills` is a symlink to `~/.config/pai/Skills`:

```bash
readlink ~/.claude/skills
```

- If already symlinked correctly: skip
- If it's a directory of individual symlinks: migrate
  - Move contents to /tmp (not rm)
  - Replace with single symlink: `ln -s ~/.config/pai/Skills ~/.claude/skills`
- If it doesn't exist: create the symlink

## 5. Verify

- Count skills visible: `ls -d ~/.claude/skills/*/`
- Check each installed skill has SKILL.md
- Check commands are discoverable: list all `commands/*.md` across installed skills
- Report total: "X skills installed, Y commands available"

## 6. Cleanup

```bash
rm -rf "$CLONE_DIR"
```

Report backup location in case rollback needed.

## 7. Final Report

```
=== Skippy Install Complete ===
Skills installed: N
Commands available: skippy:plan, skippy:execute, skippy:verify, skippy:quick, skippy:progress, ...
Backup: ~/.cache/skippy-backups/pre-install-YYYYMMDD-HHMMSS/
Source: github.com/REPO

Run /skippy:progress to check project state.
Run /skippy:upgrade from the repo to pull future updates.
```

</process>
