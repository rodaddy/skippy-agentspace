# Minimal ~/.claude/ Directory

The `~/.claude/` directory should contain minimal content -- primarily symlinks
pointing to the actual source of truth.

## Principle

Keep `~/.claude/` as a thin routing layer. Actual configuration, rules, and
skills live in a managed config directory. The claude directory only contains
symlinks to those locations.

## Structure

<!-- CUSTOMIZE: config_source (default: ~/.config/<your-system>/) -->
```
~/.claude/
  CLAUDE.md          -> <config_source>/CLAUDE.md
  docs/              -> <config_source>/docs/
  skills/            -> <config_source>/skills/
  commands/          -> <config_source>/commands/
```

## Why

- **Single source of truth** -- edits happen in one place, not scattered across directories
- **Version control** -- the config directory can be a git repo; `~/.claude/` cannot
- **Multiple machines** -- sync the config directory; symlinks recreate the structure
- **Clean separation** -- Claude Code's own files don't mix with your configuration

## Setup

After cloning your config repo, create symlinks:

```bash
ln -sf <config_source>/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf <config_source>/docs ~/.claude/docs
ln -sf <config_source>/skills ~/.claude/skills
```

Verify with `ls -la ~/.claude/` -- everything should show as symlinks.
