# PAI Portable -- Installation Guide

Portable clone of PAI (Personal AI Infrastructure) for Claude Code on macOS.

## Prerequisites

| Tool | Install | Purpose |
|------|---------|---------|
| Claude Code | `npm i -g @anthropic-ai/claude-code` | CLI agent |
| bun | `curl -fsSL https://bun.sh/install \| bash` | JS runtime, package manager |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Python package manager |
| jq | `brew install jq` | JSON processing |
| Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | macOS package manager |

## Quick Start

```bash
bash install.sh
```

The script will:
1. Check for required tools (warns but continues if missing)
2. Back up any existing `~/.claude/`, `~/.config/pai/`, `~/.config/mcp2cli/`
3. Copy all configuration files
4. Resolve `__HOME__` path placeholders to your actual home directory
5. Set up symlinks (`~/.claude/skills` -> `~/.config/pai/Skills`)
6. Verify the installation

## What's Included

### ~/.claude/ (Claude Code config)

| Component | Description |
|-----------|-------------|
| `CLAUDE.md` | Global instructions -- PAI LAWs, rules, workflow conventions |
| `settings.json` | Permissions, env vars, hook configurations |
| `docs/` | Deep reference docs (laws, code conventions, infrastructure, git, agents, session management, rationalization defense) |
| `commands/` | Slash commands (add-todo, brain, check-todos, checkpoint, critical-mode, deploy-service, enforce-skills, fabric, persona) |
| `agents/` | Custom agent definitions |
| `bin/` | Utilities -- `claudePy` (Python runner), `claudePip` (pip wrapper), `n8n-wf` (workflow helper) |
| `hooks/` | Pre/post tool-use hooks for enforcement, safety, session management |
| `plugins-manifest.json` | List of installed plugins (reinstall via `claude plugins install`) |

### ~/.config/pai/ (PAI infrastructure)

| Component | Count | Description |
|-----------|-------|-------------|
| `Skills/` | ~85 | Skill definitions (SKILL.md + references/) for specialized tasks |
| `Tools/` | ~47 | TypeScript/Bash CLI tools |
| `Packs/` | ~30 | Pre-packaged skill documentation bundles |
| `hooks/` | ~56 | Hook implementations (enforcement, capture, context loading) |
| `templates/` | 3 dirs | CI, git-hooks, GitHub Actions templates |
| `rules/` | 11 dirs | Style, architecture, infrastructure, security, stack rules |
| `memory/` | ~9 files | Personal context (about-user, decisions, ideas, infrastructure) |
| `knowledge/` | ~226 files | Patterns, decisions, gotchas, security notes, learnings |
| `skippy-kb/` | 3 files | Skippy persona knowledge base |
| `fabric-patterns/` | - | Fabric AI pattern templates |
| `Bundles/` | - | Bundle definitions |

### ~/.config/mcp2cli/ (MCP tool bridge)

| Component | Description |
|-----------|-------------|
| `skills/` | 22 service routing tables (SKILL.md + references per service) |
| `services.json.template` | Service definitions with secrets stripped -- fill in your own |

## After Installation

### 1. Fill in secrets

```bash
# Open the services template and replace all __REPLACE_WITH_*__ placeholders
vi ~/.config/mcp2cli/services.json
```

Each placeholder tells you what it needs:
- `__REPLACE_WITH_YOUR_N8N_API_KEY__`
- `__REPLACE_WITH_AUTH_HEADER__`
- `__REPLACE_WITH_YOUR_HOME_ASSISTANT_TOKEN__`
- etc.

The shell config templates (`bootstrap/env`, `bootstrap/zshrc`, `bootstrap/alias`) also use
`__PLACEHOLDER__` values. Copy them to your home directory and fill in:
- `__GEMINI_API_KEY__` -- Google Gemini API key
- `__LITELLM_API_KEY__` -- LiteLLM proxy API key
- `__CLAWDBOT_TOKEN__` -- ClawdBot gateway token
- `__ANTHROPIC_AUTH_TOKEN__` -- Anthropic auth token (if using Z.AI)
- `__OPENAI_API_KEY__` -- OpenAI API key
- `__YOUR_LITELLM_IP__` -- IP of your LiteLLM proxy server
- `__YOUR_OLLAMA_IP__` -- IP of your Ollama instance
- `__YOUR_DB_IP__` -- IP of your Second Brain PostgreSQL server
- `__YOUR_N8N_IP__` -- IP of your n8n instance
- `__YOUR_NAS_IP__` -- IP of your NAS (for sshfs mounts)
- `__YOUR_GCP_PROJECT_ID__` -- Google Cloud project ID

### 2. Install mcp2cli (if not already installed)

```bash
bun install -g mcp2cli
```

### 3. Install Claude Code plugins

The source installation had these plugins:
- `gopls-lsp@claude-plugins-official`
- `pyright@claude-code-lsps`
- `playwright@claude-plugins-official`
- `pyright-lsp@claude-plugins-official`
- `gopls@claude-code-lsps`
- `typescript-lsp@claude-plugins-official`
- `swift-lsp@claude-plugins-official`
- `episodic-memory@superpowers-marketplace`
- `superpowers@superpowers-marketplace`
- `frontend-design@claude-plugins-official`
- `skill-creator@claude-plugins-official`
- `canvas@claude-canvas`

Install with:
```bash
claude plugins install <plugin-name>
```

### 4. Review paths

The installer replaces hardcoded home paths with your `$HOME` and `/Volumes/ThunderBolt/Development` with your chosen development directory. If your development directory is elsewhere, update:

```bash
# Find remaining path references
grep -r "Development" ~/.claude/settings.json ~/.config/pai/config.json
```

### 5. Set up external services

These services need their own infrastructure to function:

| Service | What's needed |
|---------|---------------|
| vaultwarden-secrets | Vaultwarden server + API token |
| n8n | n8n instance + API key |
| proxmox | Proxmox VE cluster + API tokens |
| qmd | qmd binary + indexed document collections |
| home-assistant | Home Assistant instance + long-lived token |
| homekit | HomeMCPBridge server |
| open-brain | Obsidian vault + Open Brain plugin |
| agent-browser | Chrome + gsd-browser binary |

Without these, the corresponding skills and mcp2cli services will error -- but everything else works fine.

## Verification

After running `install.sh`, start a Claude Code session:

```bash
claude
```

You should see:
- PAI CORE context loads at session start (personas, LAWs)
- Skills appear in the system reminder
- Hooks fire on tool use
- Slash commands work (`/check-todos`, `/brain`, etc.)

If something's wrong:
```bash
# Check that settings loaded
cat ~/.claude/settings.json | jq '.env'

# Check skills symlink
ls -la ~/.claude/skills

# Check a specific skill
cat ~/.config/pai/Skills/core/SKILL.md | head -20

# Check hook exists
ls ~/.claude/hooks/law-enforcement/
```

## Bundle Structure

```
pai-portable/
  install.sh                  # This installer
  INSTALL.md                  # This file
  claude/                     # -> ~/.claude/
    CLAUDE.md
    settings.json             # Paths use __HOME__ placeholder
    docs/                     # Deep reference docs
    commands/                 # Slash commands
    agents/                   # Agent definitions
    bin/                      # claudePy, claudePip, n8n-wf
    hooks/                    # All hooks (symlinks pre-resolved)
    plugins-manifest.json     # Plugin list for reference
  pai/                        # -> ~/.config/pai/
    Skills/                   # 85 skill definitions
    Tools/                    # CLI tools
    Packs/                    # Documentation bundles
    hooks/                    # Hook implementations
    hooks-private/            # Enforcement hooks (merged from pai-private)
    templates/                # CI/git/GitHub Actions templates
    rules/                    # Style, arch, infra, security rules
    memory/                   # Personal context files
    knowledge/                # Patterns, decisions, gotchas
    skippy-kb/                # Skippy persona knowledge
    config.json               # PAI config
    VERSION                   # Version number
  mcp2cli/                    # -> ~/.config/mcp2cli/
    services.json.template    # Service definitions (secrets stripped)
    skills/                   # 22 service routing tables
```

## Updating

To update the portable bundle from the source machine, re-run the export process. The installer always backs up existing configs before overwriting.

## Security Notes

- No API keys, tokens, or passwords are included in this bundle
- `services.json.template` has all secrets replaced with `__REPLACE_WITH_*__` placeholders
- `credentials/` directory from pai-private is excluded
- `.bw_session` (Bitwarden session) is excluded
- `.env` files are excluded
- Encrypted vault snapshots are excluded
- Review `settings.json` after install -- it may reference paths that leak directory structure
