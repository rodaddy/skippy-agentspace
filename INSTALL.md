# Installing Skills & Components

Adding individual skills or components to an existing skippy-agentspace setup. For first-time installation, see [SETUP.md](SETUP.md).

## Plugin Install (Preferred)

If your Claude Code version supports plugins:

```
/plugin marketplace add owner/skippy-agentspace
/plugin install skippy-dev@skippy-agentspace
```

Available plugins are listed in `.claude-plugin/marketplace.json`. The marketplace uses `strict: false` -- no plugin.json files are needed in individual skills.

## Manual Install

Install a single skill:

```bash
bash tools/install.sh skippy-dev
```

Install multiple skills at once:

```bash
bash tools/install.sh skippy-dev fabric excalidraw
```

Install core only (minimum viable PAI):

```bash
bash tools/install.sh --core
```

Install everything:

```bash
bash tools/install.sh --all
```

The installer auto-detects whether to use `~/.claude/skills/` (modern) or `~/.claude/commands/` (legacy). Override with `--target=skills` or `--target=commands` if needed.

## Checking Status

Run the installer with no arguments to see what's installed:

```bash
bash tools/install.sh
```

This prints a status table showing each skill with `[installed]` or `[available]` badges and a brief description.

## Available Skills

12 skills across 4 categories. See [INDEX.md](INDEX.md) for the full catalog.

| Category | Skills |
|----------|--------|
| Core | core (personas, LAWs, rules, hooks, templates) |
| Workflow | add-todo, check-todos, correct, session-wrap, skippy-dev, update-todo |
| Utility | browser, excalidraw, fabric, vaultwarden |
| Domain | deploy-service |

## Uninstalling

Remove a single skill:

```bash
bash tools/uninstall.sh skippy-dev
```

Remove everything:

```bash
bash tools/uninstall.sh --all
```

Uninstall removes symlinks from both `~/.claude/skills/` and `~/.claude/commands/`. The skill source files in the repo are not affected.

## Verifying

After installing or uninstalling, confirm the setup is healthy:

```bash
bash tools/verify.sh
```

Run `/clear` in Claude Code to pick up changes to available skills and commands.
