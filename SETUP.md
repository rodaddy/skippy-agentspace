# Setup Guide

First-time setup for skippy-agentspace. See [INSTALL.md](INSTALL.md) for detailed installation options (plugin, manual, bootstrap, ggshield).

## Quick Start

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
bash tools/install.sh --all    # Install all 88 skills + ggshield
```

**WSL2 users:** Clone into the native Linux filesystem (`~/projects/` or similar), not `/mnt/c/`. The Windows filesystem has permission and performance issues that break symlinks and slow git operations.

## Prerequisites

```bash
bash tools/prereqs.sh
```

Checks for required tools and offers to install missing ones:

| Tool | Minimum | Used For |
|------|---------|----------|
| git | any | Version control, upstream tracking |
| bash | 4.0+ | Hook scripts, install tools |
| bun | any | TypeScript hook execution |
| jq | any | JSON processing in scripts |

Auto-detects OS and uses the appropriate package manager (Homebrew, apt, dnf, pacman).

## Install Paths

| Goal | Command |
|------|---------|
| Everything (skills + ggshield) | `bash tools/install.sh --all` |
| Core skill only | `bash tools/install.sh --core` |
| Specific skills | `bash tools/install.sh skippy brain fabric` |
| Secret scanning only | `bash tools/install.sh --ggshield` |
| Status table (no changes) | `bash tools/install.sh` |
| Fresh Mac bootstrap | `cd bootstrap && bash install.sh` (see `bootstrap/INSTALL.md`) |

## Hooks (Optional)

```bash
bash skills/core/hooks/install-hooks.sh
```

Installs LAW enforcement hooks into `~/.claude/settings.json` (non-destructive merge). Hooks enforce shebang checks, branch protection, file size limits, and other guardrails. Skills work without hooks -- hooks add enforcement for PAI conventions. Requires bun at runtime.

## Verify

```bash
bash tools/verify.sh
```

Health check across prerequisites, skills, hooks, and commands. Reports PASS/WARN/FAIL with fix suggestions. Run anytime -- works like `brew doctor`.

## Refresh Claude Code

Run `/clear` in your Claude Code session to pick up new skills, or restart the session entirely.

## Next Steps

- [INSTALL.md](INSTALL.md) -- Detailed installation options and ggshield setup
- [UPGRADE.md](UPGRADE.md) -- Updating to newer versions
- [CLAUDE.md](CLAUDE.md) -- AI agent context and project overview
- [INDEX.md](INDEX.md) -- Full skill catalog (88 skills across 5 categories)
