#!/usr/bin/env bash
set -euo pipefail

# install -- Install skills into Claude Code's discovery system
#
# Usage:
#   install.sh <skill-name>              Install a single skill (auto-detect target)
#   install.sh --all                     Install all skills
#   install.sh <skill-name> --target=X   Override target (skills|commands|auto)
#
# Targets:
#   skills   -> ~/.claude/skills/<name>/    (modern -- full skill with SKILL.md)
#   commands -> ~/.claude/commands/<name>   (legacy -- slash commands only)
#   auto     -> detect best target (default)
#
# Modern installs symlink the entire skill directory (SKILL.md, commands/, references/, scripts/).
# Legacy installs symlink the commands/ subdirectory only (slash commands, no SKILL.md discovery).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET="auto"
SKILL_NAME=""
INSTALL_ALL=false

# --- Argument parsing ---

for arg in "$@"; do
    case "$arg" in
        --target=*)
            TARGET="${arg#--target=}"
            if [[ "$TARGET" != "skills" && "$TARGET" != "commands" && "$TARGET" != "auto" ]]; then
                echo "ERROR: --target must be 'skills', 'commands', or 'auto' (got '$TARGET')"
                exit 1
            fi
            ;;
        --all)
            INSTALL_ALL=true
            ;;
        -h|--help)
            echo "Usage: install.sh <skill-name> [--target=skills|commands|auto]"
            echo "       install.sh --all [--target=skills|commands|auto]"
            echo ""
            echo "Targets:"
            echo "  auto      Detect best target (default) -- prefers skills/ if it exists"
            echo "  skills    Modern: symlink entire skill dir to ~/.claude/skills/<name>/"
            echo "  commands  Legacy: symlink commands/ subdir to ~/.claude/commands/<name>"
            echo ""
            echo "Available skills:"
            list_skills
            exit 0
            ;;
        *)
            if [[ -z "$SKILL_NAME" ]]; then
                SKILL_NAME="$arg"
            else
                echo "ERROR: Unexpected argument '$arg'"
                exit 1
            fi
            ;;
    esac
done

# --- Functions ---

list_skills() {
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        local desc
        desc="$(sed -n '/^description:/s/^description: *//p' "$skill_dir/SKILL.md" 2>/dev/null | head -1)"
        echo "  $name -- ${desc:-no description}"
    done
}

detect_target() {
    case "$TARGET" in
        skills)   echo "skills" ;;
        commands) echo "commands" ;;
        auto)
            if [[ -d "$HOME/.claude/skills" ]]; then
                echo "skills"
            else
                echo "commands"
            fi
            ;;
    esac
}

warn_plugin_conflict() {
    local name="$1"
    local cache_dir="$HOME/.claude/plugins/cache"

    if [[ -d "$cache_dir" ]]; then
        # Check if any cached plugin contains this skill
        local match
        match=$(find "$cache_dir" -maxdepth 3 -name "SKILL.md" -path "*/$name/*" 2>/dev/null | head -1)
        if [[ -n "$match" ]]; then
            echo "  WARN: Skill '$name' appears to be installed via plugin system"
            echo "        Plugin path: $(dirname "$match")"
            echo "        Manual install may create duplicate slash commands."
            echo "        Consider running 'tools/uninstall.sh $name' if you switch install methods."
        fi
    fi
}

install_skill_modern() {
    local name="$1"
    local src="$SKILLS_DIR/$name"
    local dest="$HOME/.claude/skills/$name"

    mkdir -p "$HOME/.claude/skills"

    if [[ -L "$dest" ]]; then
        echo "  UPDATE: Removing existing symlink at $dest"
        unlink "$dest"
    elif [[ -e "$dest" ]]; then
        echo "  ERROR: $dest exists and is not a symlink -- remove manually"
        return 1
    fi

    ln -s "$src" "$dest"
    echo "  INSTALLED (skills): $name -> $dest"
    echo "    Skill entry: $src/SKILL.md"
    if [[ -d "$src/commands" ]]; then
        echo "    Commands: $(ls "$src/commands/"*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')"
    fi
}

install_skill_legacy() {
    local name="$1"
    local commands_src="$SKILLS_DIR/$name/commands"
    local dest="$HOME/.claude/commands/$name"

    if [[ ! -d "$commands_src" ]]; then
        echo "  SKIP (commands): $name has no commands/ directory -- nothing to symlink in legacy mode"
        return 0
    fi

    mkdir -p "$HOME/.claude/commands"

    if [[ -L "$dest" ]]; then
        echo "  UPDATE: Removing existing symlink at $dest"
        unlink "$dest"
    elif [[ -e "$dest" ]]; then
        echo "  ERROR: $dest exists and is not a symlink -- remove manually"
        return 1
    fi

    ln -s "$commands_src" "$dest"
    echo "  INSTALLED (commands): $name -> $dest"
    echo "    Commands: $(ls "$commands_src"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')"
}

install_skill() {
    local name="$1"
    local skill_dir="$SKILLS_DIR/$name"
    local resolved_target
    resolved_target="$(detect_target)"

    if [[ ! -d "$skill_dir" ]]; then
        echo "ERROR: Skill '$name' not found in $SKILLS_DIR/"
        return 1
    fi

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        echo "ERROR: $name/ has no SKILL.md -- not a valid skill"
        return 1
    fi

    # Warn about potential plugin conflicts
    warn_plugin_conflict "$name"

    case "$resolved_target" in
        skills)
            install_skill_modern "$name"
            ;;
        commands)
            install_skill_legacy "$name"
            ;;
    esac
}

# --- Main ---

if [[ "$INSTALL_ALL" == true ]]; then
    echo "=== Installing all skills (target: $(detect_target)) ==="
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        install_skill "$(basename "$skill_dir")"
    done
    echo "=== Done. Run /clear to refresh skill list. ==="
elif [[ -n "$SKILL_NAME" ]]; then
    install_skill "$SKILL_NAME"
    echo "Run /clear to refresh skill list."
else
    echo "Usage: install.sh <skill-name> [--target=skills|commands|auto]"
    echo "       install.sh --all [--target=skills|commands|auto]"
    echo ""
    echo "Available skills:"
    list_skills
fi
