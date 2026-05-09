#!/usr/bin/env bash
set -euo pipefail

# PAI Portable Installer
# Clones PAI skills, commands, hooks, and Claude Code configuration to a new Mac.
# Run: bash install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PAI_DIR="$HOME/.config/pai"
MCP2CLI_DIR="$HOME/.config/mcp2cli"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${GREEN}━━━ $* ━━━${NC}"; }

# -------------------------------------------------------------------
# Development directory
# -------------------------------------------------------------------
step "Development directory"

DEFAULT_DEV="$HOME/Development"
read -rp "Where do you keep your development projects? [$DEFAULT_DEV] " DEV_DIR
DEV_DIR="${DEV_DIR:-$DEFAULT_DEV}"
DEV_DIR="${DEV_DIR/#\~/$HOME}"  # expand ~ if user typed it

if [[ ! -d "$DEV_DIR" ]]; then
  read -rp "$DEV_DIR does not exist. Create it? [Y/n] " create_answer
  if [[ ! "$create_answer" =~ ^[Nn]$ ]]; then
    mkdir -p "$DEV_DIR"
    ok "Created $DEV_DIR"
  fi
fi

info "Development directory: $DEV_DIR"

# -------------------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------------------
step "Pre-flight checks"

MISSING=()

if ! command -v claude &>/dev/null; then
  MISSING+=("claude (Claude Code CLI -- install via: npm install -g @anthropic-ai/claude-code)")
fi
if ! command -v bun &>/dev/null; then
  MISSING+=("bun (JS runtime -- install via: curl -fsSL https://bun.sh/install | bash)")
fi
if ! command -v uv &>/dev/null; then
  MISSING+=("uv (Python package manager -- install via: curl -LsSf https://astral.sh/uv/install.sh | sh)")
fi
if ! command -v jq &>/dev/null; then
  MISSING+=("jq (JSON processor -- install via: brew install jq)")
fi
if ! command -v rsync &>/dev/null; then
  MISSING+=("rsync (file sync -- should be preinstalled on macOS)")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  err "Missing required tools:"
  for tool in "${MISSING[@]}"; do
    echo "  - $tool"
  done
  echo ""
  read -rp "Continue anyway? Some features won't work. [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 1
else
  ok "All prerequisites found"
fi

# -------------------------------------------------------------------
# Backup existing configs
# -------------------------------------------------------------------
step "Backing up existing configurations"

TIMESTAMP="$(date +%s)"

if [[ -d "$CLAUDE_DIR" ]]; then
  BACKUP="$CLAUDE_DIR.backup-$TIMESTAMP"
  cp -R "$CLAUDE_DIR" "$BACKUP"
  ok "Backed up ~/.claude -> $BACKUP"
else
  info "No existing ~/.claude found (fresh install)"
fi

if [[ -d "$PAI_DIR" ]]; then
  BACKUP="$PAI_DIR.backup-$TIMESTAMP"
  cp -R "$PAI_DIR" "$BACKUP"
  ok "Backed up ~/.config/pai -> $BACKUP"
else
  info "No existing ~/.config/pai found (fresh install)"
fi

if [[ -d "$MCP2CLI_DIR" ]]; then
  BACKUP="$MCP2CLI_DIR.backup-$TIMESTAMP"
  cp -R "$MCP2CLI_DIR" "$BACKUP"
  ok "Backed up ~/.config/mcp2cli -> $BACKUP"
else
  info "No existing ~/.config/mcp2cli found (fresh install)"
fi

# -------------------------------------------------------------------
# Install Claude Code configuration
# -------------------------------------------------------------------
step "Installing Claude Code configuration"

mkdir -p "$CLAUDE_DIR"/{docs,commands,agents,bin,hooks/{bash-helpers,formatters,law-enforcement,post-session,productivity,quality,safety,session-start,skill-triggers}}

# CLAUDE.md and docs
cp "$SCRIPT_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
ok "CLAUDE.md installed"

rsync -a "$SCRIPT_DIR/claude/docs/" "$CLAUDE_DIR/docs/"
ok "Deep docs installed ($(ls "$SCRIPT_DIR/claude/docs/"*.md 2>/dev/null | wc -l | tr -d ' ') files)"

# Settings.json -- replace __HOME__ with actual home
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/claude/settings.json" > "$CLAUDE_DIR/settings.json"
ok "settings.json installed (paths resolved to $HOME)"

# Commands (slash commands)
rsync -a "$SCRIPT_DIR/claude/commands/" "$CLAUDE_DIR/commands/"
ok "Commands installed ($(ls "$SCRIPT_DIR/claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ') commands)"

# Agents
rsync -a "$SCRIPT_DIR/claude/agents/" "$CLAUDE_DIR/agents/"
ok "Agent definitions installed"

# Bin utilities
rsync -a "$SCRIPT_DIR/claude/bin/" "$CLAUDE_DIR/bin/"
chmod +x "$CLAUDE_DIR/bin/"* 2>/dev/null
ok "Bin utilities installed (claudePy, claudePip, n8n-wf)"

# Statusline
if [[ -f "$SCRIPT_DIR/claude/statusline-enhanced.sh" ]]; then
  cp "$SCRIPT_DIR/claude/statusline-enhanced.sh" "$CLAUDE_DIR/statusline-enhanced.sh"
  chmod +x "$CLAUDE_DIR/statusline-enhanced.sh"
  ok "Statusline script installed"
fi

# Hooks
rsync -a "$SCRIPT_DIR/claude/hooks/" "$CLAUDE_DIR/hooks/"
find "$CLAUDE_DIR/hooks/" -name '*.sh' -exec chmod +x {} +
ok "Hooks installed (all symlinks pre-resolved)"

# Plugin manifest (for reference -- plugins install via claude CLI)
if [[ -f "$SCRIPT_DIR/claude/plugins-manifest.json" ]]; then
  mkdir -p "$CLAUDE_DIR/plugins"
  cp "$SCRIPT_DIR/claude/plugins-manifest.json" "$CLAUDE_DIR/plugins/installed_plugins.json"
  ok "Plugin manifest copied (run plugin install step to activate)"
fi
if [[ -f "$SCRIPT_DIR/claude/plugins-marketplaces.json" ]]; then
  cp "$SCRIPT_DIR/claude/plugins-marketplaces.json" "$CLAUDE_DIR/plugins/known_marketplaces.json"
fi

# -------------------------------------------------------------------
# Install PAI infrastructure
# -------------------------------------------------------------------
step "Installing PAI infrastructure"

mkdir -p "$PAI_DIR"

rsync -a --exclude='.DS_Store' "$SCRIPT_DIR/pai/" "$PAI_DIR/"
ok "PAI infrastructure installed"

# Create the skills symlink from ~/.claude/skills -> PAI Skills
ln -sfn "$PAI_DIR/Skills" "$CLAUDE_DIR/skills"
ok "Symlinked ~/.claude/skills -> $PAI_DIR/Skills"

# Make tools executable
chmod +x "$PAI_DIR/Tools/"*.ts "$PAI_DIR/Tools/"*.sh 2>/dev/null
chmod +x "$PAI_DIR/scripts/"* 2>/dev/null
ok "Tools and scripts made executable"

# Create bin symlinks for PAI tools
mkdir -p "$PAI_DIR/bin"
for tool in "$PAI_DIR/Tools/"*.ts "$PAI_DIR/Tools/"*.sh; do
  [[ -f "$tool" ]] || continue
  name="$(basename "$tool" | sed 's/\.\(ts\|sh\)$//')"
  ln -sfn "$tool" "$PAI_DIR/bin/$name"
done
ok "PAI bin symlinks created"

info "Skills installed: $(ls "$PAI_DIR/Skills/" | wc -l | tr -d ' ')"
info "Packs installed: $(ls "$PAI_DIR/Packs/"*.md 2>/dev/null | wc -l | tr -d ' ')"
info "Knowledge files: $(find "$PAI_DIR/knowledge" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"

# -------------------------------------------------------------------
# Install mcp2cli configuration
# -------------------------------------------------------------------
step "Installing mcp2cli configuration"

mkdir -p "$MCP2CLI_DIR"

# Skills (lightweight routing tables)
rsync -a --exclude='.DS_Store' "$SCRIPT_DIR/mcp2cli/skills/" "$MCP2CLI_DIR/skills/"
ok "mcp2cli skills installed ($(ls "$MCP2CLI_DIR/skills/" | wc -l | tr -d ' ') services)"

# Services template
if [[ -f "$SCRIPT_DIR/mcp2cli/services.json.template" ]]; then
  if [[ ! -f "$MCP2CLI_DIR/services.json" ]]; then
    # First install -- resolve paths and copy as services.json
    sed -e "s|__HOME__|$HOME|g" \
        -e "s|__DEVDIR__|$DEV_DIR|g" \
        "$SCRIPT_DIR/mcp2cli/services.json.template" > "$MCP2CLI_DIR/services.json"
    warn "services.json created from template -- YOU MUST fill in API keys/tokens"
    warn "Search for __REPLACE_WITH_ in ~/.config/mcp2cli/services.json"
  else
    info "services.json already exists -- skipping (template available at $SCRIPT_DIR/mcp2cli/services.json.template)"
  fi
fi

# -------------------------------------------------------------------
# Fix paths in hook scripts
# -------------------------------------------------------------------
step "Fixing paths in installed files"

# Fix /Volumes/ThunderBolt/Development -> chosen dev directory
FIXDIRS=("$CLAUDE_DIR" "$PAI_DIR" "$MCP2CLI_DIR")
FIXTYPES=(-name '*.ts' -o -name '*.sh' -o -name '*.js' -o -name '*.json' -o -name '*.md')

for dir in "${FIXDIRS[@]}"; do
  find "$dir" -type f \( "${FIXTYPES[@]}" \) -exec \
    perl -pi -e "s|/Volumes/ThunderBolt/Development|$DEV_DIR|g" {} \; 2>/dev/null
done

ok "Development paths resolved to $DEV_DIR"

# Save DEV_DIR for future reference
echo "$DEV_DIR" > "$PAI_DIR/.dev-dir"
ok "Development directory saved to $PAI_DIR/.dev-dir"

# -------------------------------------------------------------------
# Install plugins (interactive)
# -------------------------------------------------------------------
step "Plugin installation"

if command -v claude &>/dev/null && [[ -f "$CLAUDE_DIR/plugins/installed_plugins.json" ]]; then
  info "The following plugins were in the source installation:"
  jq -r '.plugins | keys[]' "$CLAUDE_DIR/plugins/installed_plugins.json" 2>/dev/null | while read -r plugin; do
    echo "  - $plugin"
  done
  echo ""
  info "Plugins must be installed via 'claude plugins install <name>'."
  info "Claude Code will prompt to install missing plugins on first use."
else
  info "No plugin manifest found -- skip plugin setup"
fi

# -------------------------------------------------------------------
# Verification
# -------------------------------------------------------------------
step "Verification"

ERRORS=0

verify() {
  if [[ -e "$1" ]]; then
    ok "$2"
  else
    err "MISSING: $2 ($1)"
    ((ERRORS++))
  fi
}

verify "$CLAUDE_DIR/CLAUDE.md"                    "CLAUDE.md"
verify "$CLAUDE_DIR/settings.json"                "settings.json"
verify "$CLAUDE_DIR/docs/laws.md"                 "Deep docs (laws.md)"
verify "$CLAUDE_DIR/hooks/law-enforcement"        "Hooks (law-enforcement)"
verify "$CLAUDE_DIR/hooks/safety"                 "Hooks (safety)"
verify "$CLAUDE_DIR/hooks/session-start"          "Hooks (session-start)"
verify "$CLAUDE_DIR/commands/check-todos.md"      "Commands (check-todos)"
verify "$CLAUDE_DIR/bin/claudePy"                 "Bin (claudePy)"
verify "$CLAUDE_DIR/skills"                       "Skills symlink"
verify "$PAI_DIR/Skills/core/SKILL.md"            "PAI core skill"
verify "$PAI_DIR/Skills/brain/SKILL.md"           "PAI brain skill"
verify "$PAI_DIR/Skills/session-wrap/SKILL.md"    "PAI session-wrap skill"
verify "$PAI_DIR/Tools"                           "PAI Tools"
verify "$PAI_DIR/Packs"                           "PAI Packs"
verify "$PAI_DIR/rules"                           "PAI rules (merged from private)"
verify "$PAI_DIR/memory"                          "PAI memory (merged from private)"
verify "$PAI_DIR/knowledge"                       "PAI knowledge base"
verify "$MCP2CLI_DIR/skills"                      "mcp2cli skills"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  ok "All checks passed!"
else
  err "$ERRORS checks failed -- review output above"
fi

# -------------------------------------------------------------------
# Post-install summary
# -------------------------------------------------------------------
step "Installation complete"

cat <<'SUMMARY'

What was installed:
  ~/.claude/         - CLAUDE.md, settings, hooks, commands, agents, bin
  ~/.config/pai/     - Skills, Tools, Packs, hooks, rules, memory, knowledge
  ~/.config/mcp2cli/ - Service routing skills

Next steps:
  1. Fill in API keys/tokens in ~/.config/mcp2cli/services.json
     Search for: __REPLACE_WITH_
  2. Review ~/.claude/settings.json for any paths that need updating
  3. Install mcp2cli if not already: bun install -g mcp2cli
  4. Install Claude Code plugins as needed (see plugin list above)
  5. Set up any MCP servers referenced in services.json
  6. Run 'claude' to verify the setup loads correctly

Services that need local setup to work:
  - vaultwarden-secrets (needs vaultwarden server)
  - n8n (needs n8n instance + API key)
  - proxmox (needs Proxmox cluster + API tokens)
  - homekit/home-assistant (needs local HA instance)
  - qmd (needs qmd binary + document collections)
  - open-brain (needs Obsidian vault + OB plugin)

SUMMARY

echo -e "${GREEN}Done!${NC} Backups of any previous configs are timestamped in their parent dirs."
