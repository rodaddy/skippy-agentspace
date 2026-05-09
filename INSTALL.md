# Install skippy-agentspace

## Plugin Install (preferred)

```
/plugin marketplace add rodaddy/skippy-agentspace
/plugin install skippy@skippy-agentspace
```

This registers the marketplace and installs all 88 skills. Run `/clear` to pick up new skills.

## Manual Install

```bash
git clone https://github.com/rodaddy/skippy-agentspace.git
cd skippy-agentspace
bash tools/install.sh --all    # Install all skills + ggshield
```

Or install selectively:

```bash
bash tools/install.sh --core           # Core skill only (minimum viable PAI)
bash tools/install.sh skippy brain     # Specific skills by name
bash tools/install.sh --ggshield       # GitGuardian secret scanning only
bash tools/install.sh                  # Show status table (no changes)
```

`install.sh` auto-detects the target directory (`~/.claude/skills/` or `~/.claude/commands/`) and creates symlinks from the repo into Claude Code's discovery system.

## GitGuardian Setup (ggshield)

`install.sh --all` includes ggshield setup automatically. To set up standalone:

```bash
bash tools/install.sh --ggshield
```

This installs ggshield (via Homebrew), configures a git pre-commit hook, and authenticates with GitGuardian. All subsequent commits are scanned for leaked secrets.

## Bootstrap Setup (fresh Mac)

For provisioning a complete PAI environment on a new machine, use the bootstrap layer:

```bash
cd bootstrap
bash install.sh
```

This copies `~/.claude/` config, `~/.config/pai/` skills + hooks + tools, and `~/.config/mcp2cli/` service routing. Path placeholders (`__HOME__`, `__DEVDIR__`) are resolved automatically. Secret placeholders (`__GEMINI_API_KEY__`, `__YOUR_NAS_IP__`, etc.) must be filled manually after install.

See `bootstrap/INSTALL.md` for the full placeholder list and post-install steps.

## Claude-Guided Install

Open a Claude Code session in the repo and say:

> Read `docs/install-process.md` and install skippy-agentspace on this machine.

This runs the interactive 18-step process: backup, discovery, diff, skill copy, hook wiring, smoke test, and verification handoff.

For updates: `Read docs/update-process.md and update skippy-agentspace`

## Verification

```bash
bash tools/verify.sh
```

Runs health checks across prerequisites, skills, hooks, and commands. Each check reports PASS, WARN, or FAIL with actionable fix suggestions.
