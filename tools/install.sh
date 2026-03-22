#!/usr/bin/env bash
set -euo pipefail

_CLEANUP_DIRS=()
trap 'if [ "${#_CLEANUP_DIRS[@]}" -gt 0 ]; then for d in "${_CLEANUP_DIRS[@]}"; do rm -rf "$d" 2>/dev/null; done; fi' EXIT

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
    skippy_is_installed() { [[ -d "$HOME/.claude/skills/${1:?}" ]] || [[ -d "$HOME/.claude/commands/${1:?}" ]] || [[ -d "${PAI_SKILLS_DIR:-$HOME/.config/pai/Skills}/${1:?}" ]]; }
    skippy_validate_skill_name() { local n="$1"; [[ -z "$n" ]] && { echo "Error: Skill name cannot be empty" >&2; return 1; }; ! [[ "$n" =~ ^[a-zA-Z0-9_-]+$ ]] && { echo "Error: Invalid skill name '$n'" >&2; return 1; }; return 0; }
fi

# validate_skill_name delegates to common.sh skippy_validate_skill_name
validate_skill_name() { skippy_validate_skill_name "$@"; }

REPO_ROOT="$(skippy_repo_root)"
SKILLS_DIR="$REPO_ROOT/skills"
TARGET="auto"
SKILL_NAMES=()
INSTALL_ALL=false
INSTALL_CORE=false
PAI_SKILLS_DIR="${PAI_SKILLS_DIR:-$HOME/.config/pai/Skills}"
BACKUP_DIR="${SKIPPY_BACKUP_DIR:-$HOME/.cache/skippy-backups}"

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

backup_skill() {
    local name="$1"
    local target_dir="$2"
    local backup_name="pre-install-$(date +%Y%m%d-%H%M%S)-$$"
    local backup_dest="$BACKUP_DIR/$backup_name/skills"

    if [[ -d "$target_dir/$name" ]]; then
        mkdir -p "$backup_dest"
        _CLEANUP_DIRS+=("$BACKUP_DIR/$backup_name")
        cp -R "$target_dir/$name" "$backup_dest/$name"
        echo "  BACKUP: $name -> $backup_dest/$name"
    fi
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

    # Determine install target:
    #   - If PAI_SKILLS_DIR exists: COPY to pai (stable install). pai handles CC discovery.
    #   - If no pai: COPY to ~/.claude/skills/ (direct CC discovery).
    # NEVER symlink to sas dev repo -- dev changes would break live skills.

    if [[ -d "$PAI_SKILLS_DIR" ]]; then
        local dest="$PAI_SKILLS_DIR/$name"
        mkdir -p "$PAI_SKILLS_DIR"

        # Backup existing before overwrite
        if [[ -d "$dest" ]] && [[ ! -L "$dest" ]]; then
            backup_skill "$name" "$PAI_SKILLS_DIR"
        fi

        # Remove stale symlink or existing copy
        if [[ -L "$dest" ]]; then
            rm "$dest"
            echo "    Removed stale symlink: $dest"
        elif [[ -d "$dest" ]]; then
            mv "$dest" "/tmp/skippy-replaced-$name-$$" 2>/dev/null || true
        fi

        # Copy (not symlink) to pai
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --delete "$src/" "$dest/"
        else
            cp -R "$src" "$dest"
        fi

        echo "  INSTALLED (copy -> pai): $name -> $dest"
        echo "    Skill entry: $dest/SKILL.md"
    else
        local dest="$HOME/.claude/skills/$name"
        mkdir -p "$HOME/.claude/skills"

        # Remove stale symlink or existing copy
        if [[ -L "$dest" ]]; then
            rm "$dest"
        elif [[ -d "$dest" ]]; then
            backup_skill "$name" "$HOME/.claude/skills"
            mv "$dest" "/tmp/skippy-replaced-$name-$$" 2>/dev/null || true
        fi

        # Copy (not symlink) directly to claude
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --delete "$src/" "$dest/"
        else
            cp -R "$src" "$dest"
        fi

        echo "  INSTALLED (copy -> claude): $name -> $dest"
        echo "    Skill entry: $dest/SKILL.md"
    fi

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
        echo "  SKIP (commands): $name has no commands/ directory -- nothing to copy in legacy mode"
        return 0
    fi

    mkdir -p "$HOME/.claude/commands"

    # Remove existing (symlink or directory)
    if [[ -L "$dest" ]]; then
        echo "  UPDATE: Removing existing symlink at $dest"
        rm "$dest"
    elif [[ -d "$dest" ]]; then
        backup_skill "$name" "$HOME/.claude/commands"
        mv "$dest" "/tmp/skippy-replaced-cmd-$name-$$" 2>/dev/null || true
    fi

    # Copy (not symlink) commands directory
    cp -R "$commands_src" "$dest"
    echo "  INSTALLED (commands copy): $name -> $dest"
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
        echo "  Run 'install.sh' with no args to see available skills."
        return 1
    fi

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        echo "ERROR: $name/ has no SKILL.md -- not a valid skill"
        echo "  Run 'install.sh' with no args to see available skills."
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
        --copy)
            echo "NOTE: --copy is deprecated. Install now copies by default (never symlinks)."
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
            echo "  install.sh skippy                   Install one skill"
            echo "  install.sh skippy excalidraw        Install multiple skills"
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
