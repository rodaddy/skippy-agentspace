# Setup Guide

First-time setup for skippy-agentspace. Takes you from a fresh clone to a working PAI installation with verified skills and hooks.

## Step 1: Clone the Repository

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
```

**WSL2 users:** Clone into the native Linux filesystem (`~/projects/` or similar), not `/mnt/c/`. The Windows filesystem has permission and performance issues that break symlinks and slow git operations.

## Step 2: Check Prerequisites

```bash
bash tools/prereqs.sh
```

This checks for 4 required tools and reports their versions:

| Tool | Minimum | Used For |
|------|---------|----------|
| git | any | Version control, upstream tracking |
| bash | 4.0+ | Hook scripts, install tools |
| bun | any | TypeScript hook execution |
| jq | any | JSON processing in scripts |

If any tools are missing, prereqs.sh offers to install them interactively. It auto-detects your OS and uses the appropriate package manager:

- **macOS:** Homebrew (`brew install`)
- **Debian/Ubuntu:** apt (`sudo apt install`)
- **Fedora:** dnf (`sudo dnf install`)
- **Arch:** pacman (`sudo pacman -S`)

## Step 3: Install Core Skill

```bash
bash tools/install.sh --core
```

The core skill is the minimum viable PAI installation. It includes:

- Persona definitions (Skippy, Bob, Clarisa, April)
- LAW enforcement rules
- Project templates
- Hook infrastructure

This creates a symlink from `skills/core/` into `~/.claude/skills/core/` (or `~/.claude/commands/core/` on older Claude Code versions).

## Step 4: Install Additional Skills (Optional)

Install everything:

```bash
bash tools/install.sh --all
```

Or install individual skills by name:

```bash
bash tools/install.sh skippy-dev
bash tools/install.sh fabric excalidraw
```

To see what's available and what's already installed:

```bash
bash tools/install.sh
```

This shows a status table with `[installed]` or `[available]` badges for each skill. See [INSTALL.md](INSTALL.md) for detailed skill management.

## Step 5: Install Hooks (Optional)

```bash
bash skills/core/hooks/install-hooks.sh
```

Hooks enforce LAWs automatically during Claude Code sessions -- shebang checks, branch protection, and other guardrails. They merge into your `~/.claude/settings.json` non-destructively (existing settings are preserved).

This step is optional. Skills work without hooks. Hooks add enforcement for PAI-specific conventions. They require bun at runtime.

## Step 6: Verify Installation

```bash
bash tools/verify.sh
```

This runs a health check across 4 categories:

- **Prerequisites** -- tool availability and versions
- **Skills** -- symlink integrity, SKILL.md presence
- **Hooks** -- settings.json configuration, hook file existence
- **Commands** -- slash command accessibility

Each check reports PASS, WARN, or FAIL with actionable fix suggestions. All PASS or WARN means you're good. Any FAIL includes a command to fix the issue.

Run verify.sh anytime -- it works like `brew doctor` for ongoing health checks.

## Step 7: Refresh Claude Code

Run `/clear` in your Claude Code session to pick up new skills, or restart the session entirely.

Installed skills and commands are now available. Run `/help` to see discovered commands.

## Next Steps

- [INSTALL.md](INSTALL.md) -- Adding or removing individual skills
- [UPGRADE.md](UPGRADE.md) -- Updating to newer versions
- [CLAUDE.md](CLAUDE.md) -- AI agent context and project overview
- [INDEX.md](INDEX.md) -- Full skill catalog by category
