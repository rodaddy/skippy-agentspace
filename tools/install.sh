#!/usr/bin/env bash
set -euo pipefail

# install -- Install skills into Claude Code's discovery system
#
# Usage:
#   install.sh                            Show status table of all skills
#   install.sh <skill-name> [skill...]    Install one or more skills (auto-detect target)
#   install.sh --core                     Install only the core skill
#   install.sh --all                      Install all skills
#   install.sh [options] --target=X       Override target (skills|commands|auto)
#
# Targets:
#   skills   -> ~/.claude/skills/<name>/    (modern -- full skill with SKILL.md)
#   commands -> ~/.claude/commands/<name>   (legacy -- slash commands only)
#   auto     -> detect best target (default)
#
# Modern installs symlink the entire skill directory (SKILL.md, commands/, references/, scripts/).
# Legacy installs symlink the commands/ subdirectory only (slash commands, no SKILL.md discovery).

# Source shared library with graceful fallback
_COMMON_SH="$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    SKIPPY_PASS=${SKIPPY_PASS:-0}; SKIPPY_WARN=${SKIPPY_WARN:-0}; SKIPPY_FAIL=${SKIPPY_FAIL:-0}
    skippy_repo_root() { local d; d="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"; [[ -d "$d/skills" ]] && echo "$d" && return 0; [[ -n "${SKIPPY_ROOT:-}" && -d "$SKIPPY_ROOT/skills" ]] && echo "$SKIPPY_ROOT" && return 0; return 1; }
    skippy_pass() { printf '  \033[32m✓\033[0m %s\n' "${1:?requires message}"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_warn() { printf '  \033[33m⚠\033[0m %s\n' "${1:?requires message}"; SKIPPY_WARN=$((SKIPPY_WARN + 1)); }
    skippy_fail() { printf '  \033[31m✗\033[0m %s\n' "${1:?requires message}"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_suggest() { printf '  \033[36m💡\033[0m %s\n' "${1:?requires message}"; }
    skippy_section() { printf '\n=== %s ===\n\n' "${1:?requires section name}"; }
    skippy_summary() { printf '\n%d passed, %d warnings, %d failures\n' "$SKIPPY_PASS" "$SKIPPY_WARN" "$SKIPPY_FAIL"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
    skippy_is_installed() { [[ -L "$HOME/.claude/skills/${1:?}" ]] || [[ -L "$HOME/.claude/commands/${1:?}" ]]; }
fi

validate_skill_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: Skill name cannot be empty" >&2
        return 1
    fi
    if [[ "$name" =~ [/\\] ]] || [[ "$name" == .* ]]; then
        echo "Error: Invalid skill name '$name' -- must not contain path separators or start with dot" >&2
        return 1
    fi
}

REPO_ROOT="$(skippy_repo_root)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET="auto"
SKILL_NAMES=()
INSTALL_ALL=false
INSTALL_CORE=false

# --- Functions (must be defined before argument parsing uses them) ---

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

show_status() {
    printf "%-20s %-14s %s\n" "SKILL" "STATUS" "DESCRIPTION"
    printf "%-20s %-14s %s\n" "-----" "------" "-----------"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        local desc
        desc="$(sed -n '/^description:/s/^description: *//p' "$skill_dir/SKILL.md" 2>/dev/null | head -1)"
        local status="available"
        if skippy_is_installed "$name"; then
            status="installed"
        fi
        printf "%-20s %-14s %s\n" "$name" "[$status]" "${desc:-no description}"
    done
}

detect_target() {
    case "$TARGET" in
        skills)   echo "skills" ;;
        commands) echo "commands" ;;
        auto)
            if [[ -d "$HOME/.claude/skills" ]]; then
                echo "skills"
            elif [[ -d "$HOME/.claude/commands" ]]; then
                echo "commands"
            else
                # Fresh machine: prefer modern skills/ target
                mkdir -p "$HOME/.claude/skills"
                echo "skills"
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
        local cmd_list=""
        for cmd_file in "$src/commands/"*.md; do
            [[ -f "$cmd_file" ]] || continue
            local cmd_name
            cmd_name="$(basename "$cmd_file" .md)"
            cmd_list="${cmd_list:+$cmd_list, }$cmd_name"
        done
        echo "    Commands: $cmd_list"
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
    local cmd_list=""
    for cmd_file in "$commands_src"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        local cmd_name
        cmd_name="$(basename "$cmd_file" .md)"
        cmd_list="${cmd_list:+$cmd_list, }$cmd_name"
    done
    echo "    Commands: $cmd_list"
}

install_skill() {
    local name="$1"
    validate_skill_name "$name" || return 1
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
        --core)
            INSTALL_CORE=true
            ;;
        -h|--help)
            echo "Usage: install.sh [skill-name...] [--core] [--all] [--target=skills|commands|auto]"
            echo ""
            echo "Modes:"
            echo "  (no args)            Show status table of all skills"
            echo "  <skill> [skill...]   Install one or more skills by name"
            echo "  --core               Install only the core skill"
            echo "  --all                Install all skills"
            echo ""
            echo "Options:"
            echo "  --target=X           Override target (skills|commands|auto, default: auto)"
            echo "                       auto prefers skills/ if ~/.claude/skills/ exists"
            echo ""
            echo "Examples:"
            echo "  install.sh                          Show status of all skills"
            echo "  install.sh --core                   Install core skill only"
            echo "  install.sh skippy-dev               Install one skill"
            echo "  install.sh skippy-dev excalidraw    Install multiple skills"
            echo "  install.sh --all                    Install everything"
            echo ""
            echo "Available skills:"
            list_skills
            exit 0
            ;;
        *)
            validate_skill_name "$arg" || exit 1
            SKILL_NAMES+=("$arg")
            ;;
    esac
done

# --- Main ---

if [[ "$INSTALL_ALL" == true ]]; then
    echo "=== Installing all skills (target: $(detect_target)) ==="
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        install_skill "$(basename "$skill_dir")"
    done
    echo "=== Done. Run /clear to refresh skill list. ==="
elif [[ "$INSTALL_CORE" == true ]]; then
    echo "=== Installing core skill (target: $(detect_target)) ==="
    install_skill "core"
    echo "Run /clear to refresh skill list."
elif [[ ${#SKILL_NAMES[@]} -gt 0 ]]; then
    echo "=== Installing ${#SKILL_NAMES[@]} skill(s) (target: $(detect_target)) ==="
    failed=0
    succeeded=0
    for name in "${SKILL_NAMES[@]}"; do
        if install_skill "$name"; then
            succeeded=$((succeeded + 1))
        else
            failed=$((failed + 1))
        fi
    done
    echo "=== Done: $succeeded installed, $failed failed. Run /clear to refresh skill list. ==="
    if [[ "$failed" -gt 0 ]]; then
        exit 1
    fi
else
    show_status
    echo ""
    echo "Usage: install.sh [skill-name...] [--core] [--all] [--target=skills|commands|auto]"
    echo "Run install.sh --help for more details."
fi
