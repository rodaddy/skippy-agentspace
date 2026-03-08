# Hook Installation

PAI LAW enforcement hooks for Claude Code. 15 hooks covering all 15 LAWs.

## Prerequisites

- **bun** -- required. All hook scripts use `#!/usr/bin/env bun`.
  Check: `command -v bun`
  Install: `curl -fsSL https://bun.sh/install | bash`
- **Claude Code** with settings at `~/.claude/settings.json`

## Automated Install

```bash
bash skills/core/hooks/install-hooks.sh
```

Options:
- `--dry-run` -- show what would change without writing
- `--settings=PATH` -- override settings.json location

The installer:
1. Creates a timestamped backup of settings.json
2. Reads manifest.json for hook declarations
3. Resolves script paths to absolute (follows symlinks)
4. Adds new matcher groups to settings.json without modifying existing hooks
5. Skips hooks already installed (idempotent -- safe to re-run)

## Manual Install (for AI agents)

If the automated installer is unavailable, follow these steps directly.

### Step 1: Backup

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup-$(date +%Y-%m-%d-%H%M%S)
```

### Step 2: Read manifest

Read `skills/core/hooks/manifest.json`. Each entry has:
- `event` -- the hook event type (PreToolUse, UserPromptSubmit)
- `matcher` -- tool name pattern (e.g., "Write|Edit|Bash") or null
- `script` -- filename of the hook script

### Step 3: For each hook in manifest

1. Resolve the script path to absolute: `realpath skills/core/hooks/<script>`
2. Build the command string: `bun run <absolute-path>`
3. Check if `~/.claude/settings.json` already has a hook entry with this exact command -- skip if so
4. Add a new matcher group under `hooks[event]`:

```json
{
  "matcher": "<matcher from manifest>",
  "hooks": [
    { "type": "command", "command": "bun run <absolute-path>" }
  ]
}
```

Group hooks with the same event+matcher into a single matcher group for efficiency.

### Step 4: Write settings.json

Write the modified JSON with `JSON.stringify(obj, null, 2)`. Preserve all non-hook keys.

### Step 5: Verify

```bash
bun -e "const s = JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json', 'utf-8')); let c = 0; for (const gs of Object.values(s.hooks || {})) { for (const g of gs) { for (const h of g.hooks) { if (h.command.includes('skills/core/hooks/')) c++; } } } console.log(c + ' PAI hooks installed');"
```

Expected output: `15 PAI hooks installed`

## Uninstall

```bash
bash skills/core/hooks/uninstall-hooks.sh
```

The uninstaller removes only hooks matching BOTH:
1. Command path contains `skills/core/hooks/` (identifier)
2. Script name matches an entry in `manifest.json` (cross-reference)

This double-check strategy ensures existing hooks from other frameworks are never touched.

## Verify Installation

```bash
# Quick validation (structure checks)
bash tools/validate-hooks.sh

# Full validation (includes install/uninstall round-trip tests)
bash tools/validate-hooks.sh --full
```
