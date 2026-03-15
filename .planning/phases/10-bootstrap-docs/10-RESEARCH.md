# Phase 10: Bootstrap & Docs - Research

**Researched:** 2026-03-08
**Domain:** Shell scripting (bash 4+), cross-platform CLI tooling, developer documentation
**Confidence:** HIGH

## Summary

Phase 10 is the final phase -- everything it documents and verifies already exists. The phase produces 4 markdown docs (README.md, SETUP.md, INSTALL.md, UPGRADE.md), 2 shell scripts (prereqs.sh, verify.sh), and 1 AI command (/skippy:upgrade). The technical challenge is low -- this is bash scripting and technical writing. The design challenge is moderate -- producing clear, cross-platform documentation that works for macOS, Linux, and WSL2 audiences without becoming a maintenance burden.

The existing codebase provides strong foundations: `tools/install.sh` (246 lines, battle-tested), `tools/validate-hooks.sh` (317 lines, the output formatting model for verify.sh), `tools/index-sync.sh` (206 lines, `--check` mode reusable), and the Phase 8 AI command pattern (`skills/skippy/commands/update.md`) as the template for `/skippy:upgrade`.

**Primary recommendation:** Build prereqs.sh and verify.sh as the backbone, then write docs that reference them directly. prereqs.sh is step 1 of SETUP.md; verify.sh is the final step. UPGRADE.md documents both manual (git pull + reinstall) and AI-assisted (/skippy:upgrade) paths. README.md is a thin routing layer to the detail docs.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Primary audience: future-you on a new machine, then technical friends, then FOSS community adopters
- Cross-platform: macOS primary (Homebrew), Linux covered (apt, dnf, pacman), WSL2 explicitly supported
- Straight technical tone -- no personality, no fluff. Like Arch Wiki.
- No assumed knowledge beyond "you have a Mac with Homebrew" (or equivalent package manager on Linux)
- README.md: Overview + quick start pattern: what this is (2 paragraphs), quick start (5 commands), then links to SETUP/INSTALL/UPGRADE for detail
- SETUP.md: Step-by-step first-time setup: clone -> prereqs -> install core -> install skills -> verify
- INSTALL.md: Adding individual skills or components to an existing setup. Covers both plugin install and manual install.sh paths.
- UPGRADE.md: Documents BOTH manual steps (git pull + reinstall) AND AI-assisted path (/skippy:upgrade). Manual path required because repo may be used with Gemini, Codex, or other AI tools -- not Claude-only. /skippy:upgrade is an AI command (markdown-based, consistent with Phase 8 pattern). Smart merge of user customizations.
- verify.sh: Reusable health check, not one-time post-install -- run anytime like `brew doctor`. Full diagnostic scope: structural (symlinks, files) + functional (install.sh responds, index-sync.sh passes) + config (settings.json hook paths, command accessibility). Grouped output by category with section headers. Three severity levels: PASS/WARN/FAIL. Suggests fixes for each failure with commands to copy-paste. Re-run capability. Exit code: 0 for all pass or warn-only, 1 for any fail.
- prereqs.sh: Interactive install prompts: for each missing tool, ask "Install X? [y/N]" and run if approved. Auto-detect OS: macOS (brew), Debian/Ubuntu (apt), Fedora (dnf), Arch (pacman). Always interactive -- no CI/non-interactive mode. Checks: bun, jq, bash 4+, git -- reports versions for installed tools.

### Claude's Discretion
- Doc ordering and cross-linking between README/SETUP/INSTALL/UPGRADE
- Exact verification check list beyond the categories specified
- Whether prereqs.sh and verify.sh share common output formatting code
- SETUP.md step granularity (how many steps total)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOOT-01 | prereqs.sh validates required tools (bun, jq, bash 4+, git) | OS detection pattern, interactive install prompts, version reporting -- all documented below |
| BOOT-02 | SETUP.md provides step-by-step first-time setup instructions | Document structure pattern, integration with prereqs.sh/install.sh/verify.sh, cross-platform command variants |
| BOOT-03 | INSTALL.md provides instructions for adding skills/components | Two install paths (plugin vs manual), existing install.sh interface, marketplace.json reference |
| BOOT-04 | UPGRADE.md provides instructions for updating from previous version | Manual upgrade path (git pull + reinstall), AI command pattern from Phase 8 for /skippy:upgrade |
| BOOT-05 | Verification script confirms everything is wired correctly after setup | validate-hooks.sh as formatting model, 4-category check structure, PASS/WARN/FAIL output, fix suggestions |
</phase_requirements>

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 4+ | All scripts | bash 4+ required for associative arrays, `${var,,}` lowercase, safer `set -euo pipefail`. macOS ships bash 3.2 -- Homebrew bash is the fix. |
| bun | 1.x | Hook runtime, JSON processing | Already a hard dependency (Phase 7). All hooks use `#!/usr/bin/env bun`. |
| jq | 1.6+ | JSON queries in verify.sh | Lightweight JSON inspection for settings.json hook count checks. Already listed as prereq. |
| git | 2.x | Clone, update, version tracking | Standard. No exotic features needed. |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `command -v` | Binary existence check | prereqs.sh, verify.sh -- POSIX portable |
| `readlink -f` / `realpath` | Symlink resolution | verify.sh symlink validation. Note: macOS needs `realpath` (from coreutils) or fall back to `readlink` without `-f` |
| `uname -s` | OS detection | prereqs.sh -- returns "Darwin" (macOS) or "Linux" |
| `/etc/os-release` | Linux distro detection | prereqs.sh -- standard on all modern distros. Parse `ID=` field for ubuntu/debian/fedora/arch |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `jq` for JSON checks | `bun -e` inline JS | bun already required. But jq is cleaner for simple queries and is already a declared prereq. Use both where each is natural. |
| Separate output lib | Inline formatting | Shared formatting code adds coupling. prereqs.sh and verify.sh are simple enough to inline their own output formatting. Keep them independent. |

## Architecture Patterns

### Recommended File Layout
```
tools/
  prereqs.sh            # BOOT-01: prerequisite checker + interactive installer
  verify.sh             # BOOT-05: health check (brew doctor style)
  install.sh            # (exists) skill installer
  uninstall.sh          # (exists) skill uninstaller
  index-sync.sh         # (exists) INDEX.md validator/generator
  validate-hooks.sh     # (exists) hook validation
skills/
  skippy/
    commands/
      upgrade.md        # /skippy:upgrade AI command (Phase 8 pattern)
README.md               # Top-level entry point (new, replaces nothing)
SETUP.md                # First-time setup guide (new)
INSTALL.md              # Adding skills/components (new)
UPGRADE.md              # Update instructions (new)
```

### Pattern 1: OS Detection for Cross-Platform Scripts
**What:** Detect OS and package manager at script start, then use variables for platform-specific commands.
**When to use:** prereqs.sh (interactive install prompts)
**Example:**
```bash
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            PKG_MGR="brew"
            PKG_INSTALL="brew install"
            ;;
        Linux)
            OS="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian|pop|mint|linuxmint)
                        PKG_MGR="apt"
                        PKG_INSTALL="sudo apt install -y"
                        ;;
                    fedora|rhel|centos)
                        PKG_MGR="dnf"
                        PKG_INSTALL="sudo dnf install -y"
                        ;;
                    arch|manjaro|endeavouros)
                        PKG_MGR="pacman"
                        PKG_INSTALL="sudo pacman -S --noconfirm"
                        ;;
                    *)
                        PKG_MGR="unknown"
                        ;;
                esac
            fi
            ;;
        *)
            OS="unknown"
            PKG_MGR="unknown"
            ;;
    esac
}
```

### Pattern 2: PASS/WARN/FAIL Output Formatting
**What:** Consistent severity-tagged output with section grouping, modeled on validate-hooks.sh and `brew doctor`.
**When to use:** verify.sh
**Example:**
```bash
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { echo "  WARN: $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "  FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
suggest() { echo "    Fix: $1"; }

# Usage in checks:
if command -v bun >/dev/null 2>&1; then
    pass "bun $(bun --version)"
else
    fail "bun not found"
    suggest "curl -fsSL https://bun.sh/install | bash"
fi
```

### Pattern 3: AI Command Structure (Phase 8 Pattern)
**What:** Markdown-based AI command with frontmatter, `<objective>`, `<execution_context>`, and `<process>` blocks.
**When to use:** `/skippy:upgrade` command
**Example structure (from existing update.md):**
```markdown
---
name: skippy:upgrade
description: Upgrade skippy-agentspace to latest version preserving customizations
---

<objective>
...
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>
## 1. Step name
...
</process>
```

### Pattern 4: Interactive Prompt Pattern
**What:** Ask user before installing each missing prerequisite.
**When to use:** prereqs.sh
**Example:**
```bash
prompt_install() {
    local tool="$1"
    local install_cmd="$2"
    printf "Install %s? [y/N] " "$tool"
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            echo "Installing $tool..."
            eval "$install_cmd"
            ;;
        *)
            echo "Skipped $tool"
            ;;
    esac
}
```

### Anti-Patterns to Avoid
- **Platform-specific paths without detection:** Never hardcode `/usr/local/bin` (Intel Mac) vs `/opt/homebrew/bin` (Apple Silicon) -- use `command -v` instead.
- **readlink -f on macOS:** macOS `readlink` does not support `-f`. Use `realpath` (from coreutils, but NOT a required prereq) or a bash function that follows symlinks with `cd` + `pwd`.
- **Non-portable bash version check:** `$BASH_VERSINFO` is the reliable way to check bash version, not parsing `bash --version` output.
- **Testing the running shell:** prereqs.sh needs to check what `bash` resolves to in PATH, not what shell is currently running the script (could be zsh on macOS).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink validation | Custom readlink loop | Existing `install.sh` (no-arg mode) already shows install status with `[installed]`/`[available]` badges | Reuse -- it already iterates skills and checks both targets |
| Hook count verification | Custom JSON parser | `bun -e` or `jq` one-liner against settings.json | Pattern already proven in validate-hooks.sh and hooks/INSTALL.md |
| INDEX.md consistency | Manual file comparison | `tools/index-sync.sh --check` | Existing tool, exit code 0/1. verify.sh just calls it. |
| Hook structural checks | Custom validation | `tools/validate-hooks.sh` (quick mode) | 317 lines of validated checks. verify.sh invokes it, doesn't reimplement. |
| Skill listing/discovery | Directory scanning | `tools/install.sh` (no-arg mode) | Shows status table -- already built |

**Key insight:** verify.sh should be an *orchestrator* that calls existing tools (`index-sync.sh --check`, `validate-hooks.sh`, `install.sh`) and adds its own structural/config checks on top. Don't reimplement what Phase 7 and Phase 9 already built.

## Common Pitfalls

### Pitfall 1: macOS Ships Bash 3.2
**What goes wrong:** Scripts using bash 4+ features (`associative arrays`, `${var,,}`, `mapfile`) fail silently or with cryptic errors on macOS default bash.
**Why it happens:** Apple stopped updating bash due to GPLv3 licensing. `/bin/bash` on macOS is 3.2 (2007).
**How to avoid:** prereqs.sh checks the PATH `bash`, not `/bin/bash`. The check is `bash --version` on whatever `command -v bash` resolves to. Homebrew bash goes to `/opt/homebrew/bin/bash` (Apple Silicon) or `/usr/local/bin/bash` (Intel). If PATH bash is 3.2, FAIL with "brew install bash" suggestion.
**Warning signs:** `$BASH_VERSINFO[0]` returns 3.

### Pitfall 2: readlink -f Not Available on macOS
**What goes wrong:** `readlink -f` is GNU-specific. macOS `readlink` only dereferences one level and does not support `-f`.
**Why it happens:** macOS ships BSD userland, not GNU.
**How to avoid:** Use a portable symlink resolution function:
```bash
resolve_symlink() {
    local target="$1"
    while [ -L "$target" ]; do
        local dir="$(cd "$(dirname "$target")" && pwd)"
        target="$(readlink "$target")"
        [[ "$target" != /* ]] && target="$dir/$target"
    done
    echo "$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
}
```
Or just use `realpath` if coreutils is installed (but don't make it a prereq).

### Pitfall 3: WSL2 Path Quirks
**What goes wrong:** Windows paths leak into WSL2 (`/mnt/c/...`), Homebrew doesn't exist, and `uname -s` returns "Linux" but the environment is subtly different.
**Why it happens:** WSL2 is a real Linux kernel but mounts Windows filesystem.
**How to avoid:** Detect WSL via `grep -qi microsoft /proc/version 2>/dev/null`. Don't try to support Homebrew on WSL2 -- use apt. Document WSL2 as a supported Linux variant in SETUP.md, not as its own platform. Note: Windows-side `git clone` into `/mnt/c/` causes permission/performance issues -- recommend cloning into native Linux filesystem (`~/`).

### Pitfall 4: Interactive Script Can't Run in Pipe
**What goes wrong:** `curl ... | bash prereqs.sh` or `cat prereqs.sh | bash` breaks interactive prompts because stdin is the pipe, not the terminal.
**Why it happens:** `read` reads from stdin, which is the pipe.
**How to avoid:** prereqs.sh reads from `/dev/tty` for interactive prompts: `read -r response < /dev/tty`. Or -- simpler -- just document that prereqs.sh must be run directly, not piped. Given the decision is "always interactive, no CI mode," this is fine.

### Pitfall 5: Bun Install URL Changes
**What goes wrong:** `curl -fsSL https://bun.sh/install | bash` might change over time.
**Why it happens:** External dependency.
**How to avoid:** Also list `brew install oven-sh/bun/bun` as the macOS alternative. For Linux, the curl installer or `npm install -g bun` are alternatives. Don't hardcode a single install method.

### Pitfall 6: verify.sh Symlink Target Moved
**What goes wrong:** Symlinks exist but point to a moved/deleted source directory (dangling symlinks).
**Why it happens:** User moved the repo or did `git clone` to a different location.
**How to avoid:** verify.sh checks both symlink existence (`-L`) AND target resolution (`-e` after following). Dangling = FAIL with "Symlink exists but target is missing. Re-run tools/install.sh."

## Code Examples

### prereqs.sh: Complete Check Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail

check_tool() {
    local name="$1"
    local check_cmd="$2"
    local version_cmd="$3"
    local install_hint="$4"

    if eval "$check_cmd" >/dev/null 2>&1; then
        local version
        version="$(eval "$version_cmd" 2>&1 | head -1)"
        echo "  OK: $name ($version)"
        return 0
    else
        echo "  MISSING: $name"
        return 1
    fi
}

# For bash specifically -- need version >= 4
check_bash_version() {
    local bash_path
    bash_path="$(command -v bash)"
    local version
    version="$("$bash_path" -c 'echo $BASH_VERSION')"
    local major="${version%%.*}"
    if [ "$major" -ge 4 ]; then
        echo "  OK: bash $version ($bash_path)"
        return 0
    else
        echo "  OUTDATED: bash $version (need 4+)"
        return 1
    fi
}
```

### verify.sh: Category-Grouped Health Check
```bash
# Category: Prerequisites
echo "=== Prerequisites ==="
command -v bun >/dev/null 2>&1 && pass "bun $(bun --version)" || { fail "bun not found"; suggest "curl -fsSL https://bun.sh/install | bash"; }
command -v jq >/dev/null 2>&1 && pass "jq $(jq --version)" || { fail "jq not found"; suggest "$PKG_INSTALL jq"; }
command -v git >/dev/null 2>&1 && pass "git $(git --version | cut -d' ' -f3)" || { fail "git not found"; suggest "$PKG_INSTALL git"; }

# Category: Skills
echo ""
echo "=== Skills ==="
for skill_dir in "$REPO_ROOT/skills"/*/; do
    name="$(basename "$skill_dir")"
    if [ -L "$HOME/.claude/skills/$name" ] || [ -L "$HOME/.claude/commands/$name" ]; then
        # Check if symlink target resolves
        local link_path
        if [ -L "$HOME/.claude/skills/$name" ]; then
            link_path="$HOME/.claude/skills/$name"
        else
            link_path="$HOME/.claude/commands/$name"
        fi
        if [ -e "$link_path" ]; then
            pass "$name installed (symlink resolves)"
        else
            fail "$name symlink dangling"
            suggest "tools/install.sh $name"
        fi
    else
        warn "$name not installed"
        suggest "tools/install.sh $name"
    fi
done

# Category: Hooks
echo ""
echo "=== Hooks ==="
# Delegate to validate-hooks.sh for structural checks
if bash "$REPO_ROOT/tools/validate-hooks.sh" >/dev/null 2>&1; then
    pass "hook structure valid (validate-hooks.sh)"
else
    fail "hook structure issues detected"
    suggest "bash tools/validate-hooks.sh  # run for details"
fi

# Check settings.json registration
if [ -f "$HOME/.claude/settings.json" ]; then
    local hook_count
    hook_count="$(bun -e "const s=JSON.parse(require('fs').readFileSync('$HOME/.claude/settings.json','utf-8'));let c=0;for(const gs of Object.values(s.hooks||{})){for(const g of gs){for(const h of g.hooks){if(h.command.includes('skills/core/hooks/'))c++;}}}console.log(c);" 2>/dev/null || echo 0)"
    if [ "$hook_count" = "15" ]; then
        pass "15 PAI hooks registered in settings.json"
    elif [ "$hook_count" = "0" ]; then
        warn "no PAI hooks in settings.json (hooks not installed)"
        suggest "bash skills/core/hooks/install-hooks.sh"
    else
        warn "$hook_count/15 PAI hooks in settings.json"
        suggest "bash skills/core/hooks/install-hooks.sh  # re-run to fix"
    fi
else
    warn "~/.claude/settings.json not found"
    suggest "bash skills/core/hooks/install-hooks.sh  # creates settings.json"
fi

# Category: Commands
echo ""
echo "=== Commands ==="
# Check that skippy commands are accessible
```

### /skippy:upgrade AI Command Structure
```markdown
---
name: skippy:upgrade
description: Upgrade skippy-agentspace to latest version preserving customizations
---

<objective>
Pull the latest skippy-agentspace changes and re-apply installation,
preserving user customizations (modified SKILL.md files, custom skills,
hook configurations). Report what changed and verify the upgrade.
</objective>

<process>
## 1. Pre-Upgrade Snapshot
- Record currently installed skills (tools/install.sh no-arg output)
- Record current hook count in settings.json
- Note any modified files (git status in repo)

## 2. Pull Latest
- cd to repo root
- git pull origin main (or current branch)
- Report new commits

## 3. Re-Install
- Run tools/install.sh --all (re-symlinks everything)
- Run skills/core/hooks/install-hooks.sh (idempotent merge)

## 4. Verify
- Run tools/verify.sh
- Compare post-upgrade state to pre-upgrade snapshot
- Report: added skills, removed skills, updated files

## 5. Handle Customizations
- If git status shows modified tracked files after pull, report conflicts
- Suggest resolution: keep theirs (upstream), keep ours, or manual merge
</process>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-platform scripts | Cross-platform with OS detection | Current best practice | prereqs.sh must detect macOS vs Linux distros |
| `readlink -f` | `realpath` or portable function | Always (macOS compat) | verify.sh symlink checks need portable resolution |
| Single install path | Dual-target (skills/ vs commands/) | Phase 9 | INSTALL.md must document both paths |
| Hardcoded upstream URLs | Registry-based (`upstreams/*/upstream.json`) | Phase 8 | UPGRADE.md references /skippy:update for upstream changes |

**Deprecated/outdated:**
- `~/.claude/commands/` is "legacy" target. Modern Claude Code uses `~/.claude/skills/`. Both work, but docs should recommend skills/ first.

## Open Questions

1. **Whether verify.sh should have a `--fix` mode**
   - What we know: User decided verify.sh is diagnostic only (like `brew doctor`). Fix suggestions are copy-paste commands.
   - What's unclear: Should verify.sh offer to run the fix commands interactively? prereqs.sh has interactive prompts but verify.sh's scope is broader.
   - Recommendation: Keep verify.sh non-interactive. It outputs fix commands. The user runs them. This is the `brew doctor` model and matches the locked decision.

2. **How SETUP.md handles the "hooks are optional" question**
   - What we know: Core skill is always installed. Hooks require bun. Hooks are PAI-specific (not needed for vanilla Claude Code use).
   - What's unclear: Should SETUP.md install hooks by default, or present them as an optional step?
   - Recommendation: Make hooks a clearly labeled optional step in SETUP.md ("Step 4 (optional): Install LAW enforcement hooks"). verify.sh checks for hooks but uses WARN (not FAIL) if absent.

3. **README.md vs existing CLAUDE.md overlap**
   - What we know: CLAUDE.md is the AI-facing project brief. README.md is the human-facing entry point.
   - What's unclear: How much content overlaps between them?
   - Recommendation: README.md is for humans on GitHub. CLAUDE.md is for AI sessions. README.md links to CLAUDE.md for "AI agent setup" context. No content duplication -- CLAUDE.md already exists and is comprehensive.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash scripts (no test framework -- shell validation scripts) |
| Config file | none |
| Quick run command | `bash tools/verify.sh` |
| Full suite command | `bash tools/verify.sh && bash tools/validate-hooks.sh --full` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOOT-01 | prereqs.sh checks bun, jq, bash 4+, git | smoke | `bash tools/prereqs.sh` (interactive -- manual verify output) | Wave 0 |
| BOOT-02 | SETUP.md guides from clone to working setup | manual-only | Follow SETUP.md steps on clean machine | N/A |
| BOOT-03 | INSTALL.md covers adding skills | manual-only | Follow INSTALL.md steps | N/A |
| BOOT-04 | UPGRADE.md covers updating | manual-only | Follow UPGRADE.md steps | N/A |
| BOOT-05 | verify.sh confirms wiring | smoke | `bash tools/verify.sh` | Wave 0 |

### Sampling Rate
- **Per task commit:** `bash tools/verify.sh` (once verify.sh exists)
- **Per wave merge:** `bash tools/verify.sh && bash tools/validate-hooks.sh`
- **Phase gate:** verify.sh exits 0 with all checks passing

### Wave 0 Gaps
- [ ] `tools/prereqs.sh` -- covers BOOT-01
- [ ] `tools/verify.sh` -- covers BOOT-05
- [ ] `README.md` -- covers project entry point
- [ ] `SETUP.md` -- covers BOOT-02
- [ ] `INSTALL.md` -- covers BOOT-03
- [ ] `UPGRADE.md` -- covers BOOT-04
- [ ] `skills/skippy/commands/upgrade.md` -- AI command for BOOT-04

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis -- `tools/install.sh`, `tools/uninstall.sh`, `tools/index-sync.sh`, `tools/validate-hooks.sh`, `skills/core/hooks/install-hooks.sh`, `skills/core/hooks/INSTALL.md`
- Phase 8 AI command pattern -- `skills/skippy/commands/update.md`
- CONTEXT.md locked decisions -- all design choices verified against existing code

### Secondary (MEDIUM confidence)
- Cross-platform bash patterns -- verified against current macOS (bash 5.3.9 via Homebrew, Darwin 25.3.0) and standard Linux distro detection via `/etc/os-release`
- WSL2 detection via `/proc/version` grep -- standard community pattern, widely documented

### Tertiary (LOW confidence)
- None -- all findings verified against existing project code or POSIX/platform standards

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools already declared as project dependencies, versions verified on current machine
- Architecture: HIGH -- all patterns derived from existing codebase (validate-hooks.sh, update.md, install.sh)
- Pitfalls: HIGH -- macOS bash 3.2, readlink -f, WSL2 quirks are well-documented, verified against current environment
- Documentation structure: HIGH -- decisions fully locked in CONTEXT.md, minimal ambiguity

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable domain -- shell scripting and markdown docs don't change fast)
