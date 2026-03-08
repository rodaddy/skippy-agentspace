#!/usr/bin/env bash
set -euo pipefail

# prereqs.sh - Interactive prerequisite checker with OS detection and install prompts
#
# Usage:
#   bash tools/prereqs.sh          # Check prerequisites, prompt to install missing
#   bash tools/prereqs.sh < /dev/null  # Non-interactive mode (skip prompts)
#
# Checks: git, bash 4+, bun, jq
# Supports: macOS (brew), Debian/Ubuntu (apt), Fedora/RHEL (dnf/yum), Arch (pacman), WSL2

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

ok_count=0
missing_count=0

report_ok() {
    echo "  OK: $1"
    ok_count=$((ok_count + 1))
}

report_missing() {
    echo "  MISSING: $1"
    missing_count=$((missing_count + 1))
}

report_outdated() {
    echo "  OUTDATED: $1"
    missing_count=$((missing_count + 1))
}

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------

OS="unknown"
PKG_MGR="unknown"
PKG_INSTALL="unknown"

detect_os() {
    local kernel
    kernel="$(uname -s)"

    case "$kernel" in
        Darwin)
            OS="macos"
            PKG_MGR="brew"
            PKG_INSTALL="brew install"
            ;;
        Linux)
            # Check for WSL2
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl2"
            else
                OS="linux"
            fi

            # Parse distro from os-release
            if [ -f /etc/os-release ]; then
                local distro_id
                distro_id="$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"' | head -1)"
                case "$distro_id" in
                    ubuntu|debian|pop|mint|linuxmint)
                        PKG_MGR="apt"
                        PKG_INSTALL="sudo apt-get install -y"
                        ;;
                    fedora|rhel|centos|rocky|alma)
                        if command -v dnf >/dev/null 2>&1; then
                            PKG_MGR="dnf"
                            PKG_INSTALL="sudo dnf install -y"
                        else
                            PKG_MGR="yum"
                            PKG_INSTALL="sudo yum install -y"
                        fi
                        ;;
                    arch|manjaro|endeavouros)
                        PKG_MGR="pacman"
                        PKG_INSTALL="sudo pacman -S --noconfirm"
                        ;;
                    *)
                        PKG_MGR="unknown"
                        PKG_INSTALL="unknown"
                        ;;
                esac
            fi
            ;;
        *)
            OS="unknown"
            PKG_MGR="unknown"
            PKG_INSTALL="unknown"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Install helpers
# ---------------------------------------------------------------------------

prompt_install() {
    local tool="$1"
    local install_cmd="$2"

    if [ "$PKG_MGR" = "unknown" ]; then
        echo "    Install manually: $install_cmd"
        return 1
    fi

    printf "    Install %s? [y/N] " "$tool"
    local response
    if read -r response < /dev/tty 2>/dev/null; then
        case "$response" in
            y|Y|yes|YES)
                echo "    Running: $install_cmd"
                if eval "$install_cmd"; then
                    echo "    Installed successfully."
                    return 0
                else
                    echo "    Install failed."
                    return 1
                fi
                ;;
            *)
                echo "    Skipped."
                return 1
                ;;
        esac
    else
        # Non-interactive (piped input / no tty)
        echo "    Non-interactive mode -- skipping install prompt."
        echo "    Install manually: $install_cmd"
        return 1
    fi
}

get_install_cmd() {
    local tool="$1"

    case "$tool" in
        bun)
            if [ "$OS" = "macos" ]; then
                echo "brew install oven-sh/bun/bun"
            else
                echo "curl -fsSL https://bun.sh/install | bash"
            fi
            ;;
        jq)
            echo "$PKG_INSTALL jq"
            ;;
        git)
            echo "$PKG_INSTALL git"
            ;;
        bash)
            if [ "$OS" = "macos" ]; then
                echo "brew install bash"
            else
                echo "$PKG_INSTALL bash"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Tool checks
# ---------------------------------------------------------------------------

check_git() {
    if command -v git >/dev/null 2>&1; then
        local version
        version="$(git --version | cut -d' ' -f3)"
        report_ok "git $version"
        return 0
    else
        report_missing "git"
        prompt_install "git" "$(get_install_cmd git)" && check_git
        return 1
    fi
}

check_bash() {
    local bash_path
    bash_path="$(command -v bash 2>/dev/null || true)"

    if [ -z "$bash_path" ]; then
        report_missing "bash"
        prompt_install "bash" "$(get_install_cmd bash)" && check_bash
        return 1
    fi

    # Get version from the PATH bash, not the running shell
    local bash_version_str
    bash_version_str="$("$bash_path" -c 'echo $BASH_VERSION')"
    local major
    major="$(echo "$bash_version_str" | cut -d. -f1)"

    if [ "$major" -ge 4 ] 2>/dev/null; then
        report_ok "bash $bash_version_str ($bash_path)"
        return 0
    else
        report_outdated "bash $bash_version_str (need 4+, path: $bash_path)"
        prompt_install "bash" "$(get_install_cmd bash)" && check_bash
        return 1
    fi
}

check_bun() {
    if command -v bun >/dev/null 2>&1; then
        local version
        version="$(bun --version)"
        report_ok "bun $version"
        return 0
    else
        report_missing "bun"
        prompt_install "bun" "$(get_install_cmd bun)" && check_bun
        return 1
    fi
}

check_jq() {
    if command -v jq >/dev/null 2>&1; then
        local version
        version="$(jq --version)"
        report_ok "jq $version"
        return 0
    else
        report_missing "jq"
        prompt_install "jq" "$(get_install_cmd jq)" && check_jq
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo "=== Prerequisite Check ==="
echo ""

detect_os
echo "  Platform: $OS (package manager: $PKG_MGR)"
echo ""

# Track which checks pass (avoid bash 4+ features -- no associative arrays)
git_ok=false
bash_ok=false
bun_ok=false
jq_ok=false

check_git && git_ok=true || true
check_bash && bash_ok=true || true
check_bun && bun_ok=true || true
check_jq && jq_ok=true || true

echo ""

# Recount after potential installs
final_ok=0
final_missing=0

if [ "$git_ok" = true ]; then final_ok=$((final_ok + 1)); else final_missing=$((final_missing + 1)); fi
if [ "$bash_ok" = true ]; then final_ok=$((final_ok + 1)); else final_missing=$((final_missing + 1)); fi
if [ "$bun_ok" = true ]; then final_ok=$((final_ok + 1)); else final_missing=$((final_missing + 1)); fi
if [ "$jq_ok" = true ]; then final_ok=$((final_ok + 1)); else final_missing=$((final_missing + 1)); fi

echo "=== Summary ==="
echo "  $final_ok OK, $final_missing missing/outdated"
echo ""

if [ "$final_missing" -eq 0 ]; then
    echo "All prerequisites met."
    exit 0
else
    echo "$final_missing tool(s) still missing. Install them and re-run."
    exit 1
fi
