# Install skippy-agentspace

Clone this repo. Open a Claude Code session in it. Say:

> Read `docs/install-process.md` and install skippy-agentspace on this machine.

That's it. The process handles everything: marketplace discovery, backup with restore script, skill installation, old command removal, eval testing, and a handoff prompt for verification in a fresh session.

For updates after initial install:

> Read `docs/update-process.md` and update skippy-agentspace.

## What Happens

1. Discovers which marketplaces this repo consumes (from `upstreams/` and `.planning/audits/`)
2. Backs up your entire `~/.claude/` and `~/.config/pai/` with a one-command restore script
3. Sets up single-symlink architecture (`~/.claude/skills/` -> `~/.config/pai/Skills/`)
4. Copies skippy skills into `~/.config/pai/Skills/`
5. Removes old GSD/OMC commands that skippy replaces
6. Runs Karpathy-style eval loops on skills that have assertions
7. Generates a handoff prompt to verify the install in a fresh session

## Manual Install (if you prefer)

```bash
bash tools/install.sh --all --copy
```

See `docs/install-process.md` for the full process with backup, removal, and testing.
