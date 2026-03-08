# Stack Research

**Domain:** Portable PAI infrastructure -- standalone execution framework, testing, multi-agent review, version management
**Researched:** 2026-03-08
**Confidence:** HIGH
**Milestone:** v1.2 Standalone Skippy

## Context: What Already Exists (DO NOT CHANGE)

Locked decisions from v1.0 and v1.1. Listed for downstream consumers.

| Technology | Purpose | Status |
|------------|---------|--------|
| Bash (`#!/usr/bin/env bash`) | All scripts and tooling | Locked -- no build step, no runtime deps |
| Markdown | Rules, references, SKILL.md entry points | Locked -- Claude Code's native format |
| Symlinks | Installation mechanism (tools/install.sh) | Locked -- dual-target (skills/ and commands/) |
| `.claude-plugin/marketplace.json` | Plugin distribution | Locked -- strict:false |
| `upstreams/<name>/upstream.json` | Per-upstream tracking registry | Locked -- directory-based, extensible |
| TypeScript hooks (via bun) | LAW enforcement (15 hooks) | Locked -- `skills/core/hooks/` |
| `tools/{install,uninstall,verify,prereqs,validate-hooks,index-sync}.sh` | Tooling infrastructure | Locked -- 6 scripts, all working |

## Stack Additions for v1.2

Six new capabilities, each analyzed independently. Critical constraint unchanged: **no new runtime dependencies beyond git, bash 4+, bun, jq** (the existing prereqs.sh set).

---

### 1. GSD Pattern Absorption (Reference Docs + Standalone Commands)

**What:** Absorb GSD's execution patterns as skippy-native reference docs and commands so the framework works without GSD installed at runtime.

**Stack decision: Markdown reference docs + bash command wrappers. No code porting.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Markdown references | N/A | `references/gsd-execution.md`, `references/gsd-planning.md`, etc. | GSD workflows are markdown prompts (460 lines for execute-phase, 450 for execute-plan). Absorbing them means distilling the patterns into skippy-native references that Claude can load. No code to port. |
| Bash command stubs | N/A | `commands/execute.md`, `commands/plan.md` as Claude slash commands | Commands are markdown files that Claude reads. They reference the absorbed patterns. No shell scripts needed for commands themselves. |

**What to absorb from GSD (11,452 lines across 33 workflows):**

| GSD Pattern | Lines | Absorb As | Priority |
|-------------|-------|-----------|----------|
| Phased execution (execute-phase.md) | 460 | `references/phased-execution.md` | HIGH -- core execution loop |
| Plan execution (execute-plan.md) | 450 | `references/plan-execution.md` | HIGH -- task-level execution |
| Wave-based parallelism | ~80 | Fold into phased-execution reference | HIGH -- parallel agent spawning |
| Checkpoint handling | ~100 | `references/checkpoints.md` (already partially exists via GSD dep) | MEDIUM -- human-in-loop gates |
| State tracking (STATE.md management) | ~60 | Fold into existing `references/state-consistency.md` | MEDIUM |
| Deviation rules (4 rules) | ~40 | `references/deviation-rules.md` | HIGH -- critical execution pattern |
| Commit protocol | ~40 | Fold into existing conventions | LOW -- standard git patterns |
| Verification loops | ~60 | Already exists as `references/verification-loops.md` | DONE |
| Plan structure (PLAN.md format) | ~80 | Already captured in `references/gsd-dependency-map.md` | DONE |

**What NOT to port:**
- `gsd-tools.cjs` (592 lines + 11 lib modules) -- this is GSD's Node.js CLI for state/roadmap/config management. Skippy doesn't need to replicate it. Commands that need state manipulation should use direct file operations (grep/sed) on `.planning/` files, which is simpler and has zero runtime dependency.
- GSD's `config.json` system -- skippy already has its own pattern. No need to absorb GSD's config-get/config-set tooling.
- GSD's template system -- templates are markdown files. Reference them by path, don't copy them.

**Integration point:** The existing `references/gsd-dependency-map.md` already documents every file format and parsing dependency. Absorbed references should cite this map when describing state file structures.

---

### 2. `/skippy:review` Multi-Agent Audit Swarm

**What:** A slash command that spawns parallel review subagents, each focused on a specific audit dimension, then aggregates findings.

**Stack decision: Pure markdown command + Claude Code's native `Task()` subagent system. No external tooling.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code `Task()` API | Current | Spawn parallel review subagents | Native to Claude Code. No dependencies. Each subagent gets fresh 200k context. This is the same pattern GSD uses for execute-phase wave spawning. |
| Markdown command file | N/A | `commands/review.md` -- the command definition | Claude Code commands are markdown. The command defines the swarm configuration, agent roles, and aggregation logic. |
| Structured output protocol | N/A | JSON-like structured returns from each subagent | Subagents return findings in a consistent format. Orchestrator aggregates. Same pattern as GSD's execute-phase aggregate_results step. |

**Swarm architecture (4 specialist agents, not 9):**

Keep it lean. Research shows 3-4 subagents is the sweet spot before coordination overhead outweighs benefit. More than that and you spend more time routing than reviewing.

| Agent Role | Focus | Subagent Type |
|------------|-------|---------------|
| **Code Quality** | DRY violations, dead code, complexity, naming, file size limits | `skippy-reviewer` |
| **Security** | Hardcoded secrets, injection vectors, unsafe shell patterns, permission issues | `skippy-security` |
| **Architecture** | Component boundaries, coupling, dependency direction, anti-patterns | `skippy-architect` |
| **Consistency** | CLAUDE.md compliance, convention adherence, skill structure validation | `skippy-consistency` |

**Execution flow:**
1. Command receives scope (directory, files, or "everything")
2. Orchestrator spawns 4 agents in parallel via `Task()`
3. Each agent reads relevant files, applies its lens, returns structured findings
4. Orchestrator aggregates into a single report: `REVIEW.md`
5. Optionally: orchestrator spawns a fix agent for auto-fixable issues

**What NOT to add:**
- No Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) -- experimental feature, adds coordination overhead, and agents don't need to talk to each other for reviews. Subagents report back to orchestrator, which is sufficient.
- No external review tools (eslint, shellcheck integration) -- these are good ideas but belong in a separate skill, not baked into the review command. The review swarm is about AI-powered review, not linting.
- No cross-model review (using Gemini/GPT to validate Claude's output) -- interesting pattern from MetaSwarm but adds API key dependencies and cost.
- No persistent agent memory between reviews -- each review is stateless. Historical comparison is a future feature.

**Reference docs to create:**
- `references/review-swarm.md` -- swarm configuration, agent prompts, output format
- `references/review-rubric.md` -- what each agent checks for, severity levels, auto-fix criteria

---

### 3. bats-core Test Suite

**What:** Automated testing for all shell scripts in `tools/` and `skills/*/scripts/`.

**Stack decision: bats-core 1.13.0 via brew, with bats-assert and bats-support helper libraries. Git submodules for helpers, brew for bats itself.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| bats-core | 1.13.0 | Test runner | The standard for bash testing. v1.13.0 (Nov 2025) adds `--negative-filter` and `--abort` (fail-fast). Available via brew. MIT license. |
| bats-assert | latest | Assertion helpers | `assert_success`, `assert_failure`, `assert_output --partial`, `refute_output`. Official companion library from bats-core org. |
| bats-support | latest | Output formatting | Required dependency of bats-assert. Provides structured assertion output (two-column and multi-line formats). |
| bats-file | latest | Filesystem assertions | `assert_file_exists`, `assert_dir_exists`. Useful for testing install/uninstall symlink operations. |

**Installation approach: brew for bats-core, git submodules for helpers.**

```bash
# bats-core itself (added to prereqs.sh as optional dev dependency)
brew install bats-core

# Helper libraries as git submodules (committed to repo)
git submodule add https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git tests/test_helper/bats-file
```

**Why git submodules over brew for helpers:**
- brew installs bats-assert/bats-file to a Homebrew prefix, making `load` paths non-portable
- Submodules give a fixed relative path (`tests/test_helper/bats-support/load`) that works on any OS
- bats-core itself is fine via brew because it's a CLI tool, not a library to `load`

**Why NOT npm/bun for bats:**
- bats-core's npm package exists but adds a node_modules dependency for a bash testing tool -- wrong ecosystem
- brew is already a prereq for bash 4+ on macOS

**Test directory structure:**

```
tests/
  test_helper/
    bats-support/      # git submodule
    bats-assert/       # git submodule
    bats-file/         # git submodule
    common.bash        # Shared test fixtures and helpers
  tools/
    install.bats       # Tests for tools/install.sh
    uninstall.bats     # Tests for tools/uninstall.sh
    verify.bats        # Tests for tools/verify.sh
    prereqs.bats       # Tests for tools/prereqs.sh
    index-sync.bats    # Tests for tools/index-sync.sh
    validate-hooks.bats # Tests for tools/validate-hooks.sh
  skills/
    skill-structure.bats  # Validates all skills have SKILL.md, correct frontmatter
    deploy-service.bats   # Tests for deploy-service scripts
  integration/
    install-uninstall.bats  # Round-trip install/uninstall tests
    version-bump.bats       # Version management tests
```

**Test helpers (tests/test_helper/common.bash):**

```bash
# Load bats helpers
load 'bats-support/load'
load 'bats-assert/load'
load 'bats-file/load'

# Project root
export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"

# Create isolated test environment
setup_test_env() {
    export TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
    mkdir -p "$TEST_HOME/.claude/skills"
    mkdir -p "$TEST_HOME/.claude/commands"
}

teardown_test_env() {
    rm -rf "$TEST_HOME"
}
```

**Target: ~260 lines minimum across all test files.** Each tools/ script gets 30-50 lines of tests covering happy path, error cases, and edge cases.

**What NOT to test with bats:**
- TypeScript hooks -- those need bun-based testing, not bats. Leave for a separate test harness.
- Markdown command files -- these are prompts for Claude, not executable scripts. Their "testing" is functional validation during use.
- GSD integration -- GSD is an upstream dependency, not our code to test.

**Integration with CI:** Not needed yet (private repo, solo dev). But the test runner command is simple: `bats tests/` runs everything. Add to `tools/verify.sh` as an optional category.

---

### 4. DRY Extraction (`tools/lib/common.sh`)

**What:** Extract duplicated shell patterns across the 6 existing tools/ scripts into a shared library.

**Stack decision: Single sourced file at `tools/lib/common.sh`. No framework, no package system.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bash `source` | N/A | `source "$(dirname "$0")/lib/common.sh"` at top of each script | Standard bash pattern. No magic, no dependency. Every script sources the same file. |

**Duplicated patterns found across existing scripts (from grep analysis):**

| Pattern | Found In | Extraction Target |
|---------|----------|-------------------|
| `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` | install.sh, verify.sh, validate-hooks.sh, index-sync.sh | `common.sh::init_repo_root()` |
| `SKILLS_DIR="$REPO_ROOT/skills"` | install.sh, verify.sh, index-sync.sh | `common.sh::SKILLS_DIR` (set by init) |
| `set -euo pipefail` | All 6 scripts | Keep in each script (it's a shell option, not a function) |
| `pass()/warn()/fail()` output helpers | verify.sh, validate-hooks.sh | `common.sh::pass()`, `common.sh::warn()`, `common.sh::fail()`, `common.sh::suggest()` |
| `report_ok()/report_missing()` | prereqs.sh | Alias to `pass()/fail()` or keep separate (prereqs has different output format) |
| `command -v <tool>` checks | prereqs.sh, verify.sh | `common.sh::require_cmd()` |
| `for skill_dir in "$SKILLS_DIR"/*/` iteration | install.sh, verify.sh, index-sync.sh | `common.sh::each_skill()` callback pattern or keep inline (iteration is trivial) |
| Symlink checking (`-L "$link"`) | install.sh, uninstall.sh, verify.sh | `common.sh::is_installed()` (already exists in index-sync.sh) |
| PASS/WARN/FAIL counting | verify.sh, validate-hooks.sh | `common.sh::summary()` |

**What to extract (worth the indirection):**

```bash
# tools/lib/common.sh

# --- Path setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# --- Output helpers ---
_PASS=0 _WARN=0 _FAIL=0

pass()    { echo "  PASS: $1"; _PASS=$((_PASS + 1)); }
warn()    { echo "  WARN: $1"; _WARN=$((_WARN + 1)); }
fail()    { echo "  FAIL: $1"; _FAIL=$((_FAIL + 1)); }
suggest() { echo "    Fix: $1"; }

summary() {
    echo "=== Summary ==="
    echo "  $_PASS passed, $_WARN warnings, $_FAIL failures"
    [[ "$_FAIL" -gt 0 ]] && return 1 || return 0
}

# --- Prerequisite checks ---
require_cmd() {
    local cmd="$1" label="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# --- Skill helpers ---
is_installed() {
    local name="$1"
    [[ -L "$HOME/.claude/skills/$name" ]] || [[ -L "$HOME/.claude/commands/$name" ]]
}

get_version() {
    cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "0.0.0"
}
```

**What NOT to extract (not worth the indirection):**
- `set -euo pipefail` -- must remain in each script (shell options aren't inherited via `source` reliably across subshells)
- Argument parsing -- each script has unique flags. No shared pattern worth abstracting.
- `detect_os()` / `detect_target()` -- used by only one script each. Don't extract single-use functions.
- Skill iteration loops -- the loop body is different in every script. Extracting the iteration but not the body adds complexity without reducing duplication.

**Migration approach:** Extract functions, update scripts to source common.sh, verify with bats tests. Do NOT change behavior -- pure refactor.

---

### 5. deploy-service Config Mechanism

**What:** Replace hardcoded placeholders (`<your-server-ip>`, `<your-domain>`, etc.) with a config file that deploy-service reads at runtime.

**Stack decision: Bash key=value config file at `skills/deploy-service/config.env`, sourced at runtime. Gitignored.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Bash key=value config | N/A | `skills/deploy-service/config.env` | Same pattern as `upstreams/*/upstream.conf`. No parser needed -- `source config.env` loads variables directly. Bash-native, zero dependencies. |
| Example config template | N/A | `skills/deploy-service/config.env.example` | Committed to repo. Documents all required variables with placeholder values. Users copy to `config.env` and fill in real values. |
| Input validation functions | N/A | `skills/deploy-service/scripts/validate-config.sh` | Source this before any deploy operation. Checks all required vars are set and non-placeholder. |

**Config file format (`config.env.example`):**

```bash
# deploy-service configuration
# Copy to config.env and fill in your values.
# config.env is gitignored -- never commit real values.

# Proxmox host
PROXMOX_HOST="<your-server-ip>"

# Domain (wildcard SSL)
DOMAIN="<your-domain>"

# Proxy LXC (nginx reverse proxy)
PROXY_VMID="<your-proxy-vmid>"
PROXY_IP="<your-proxy-ip>"

# Network ranges (first 3 octets)
NET1="<your-network-1>"
NET2="<your-network-2>"
GATEWAY="<your-gateway>"

# DNS servers (space-separated VMIDs)
DNS_VMIDS="<your-dns-server-vmids>"

# Starting IP host octet for new containers
IP_START=13
```

**Validation script pattern:**

```bash
validate_config() {
    local config="$1"
    local errors=0

    if [[ ! -f "$config" ]]; then
        echo "ERROR: Config file not found: $config"
        echo "  Copy config.env.example to config.env and fill in your values."
        return 1
    fi

    source "$config"

    for var in PROXMOX_HOST DOMAIN PROXY_VMID PROXY_IP NET1 NET2 GATEWAY DNS_VMIDS; do
        local val="${!var}"
        if [[ -z "$val" || "$val" == "<"*">" ]]; then
            echo "ERROR: $var is not configured (value: '${val:-empty}')"
            errors=$((errors + 1))
        fi
    done

    return "$errors"
}
```

**Root guard pattern:**

```bash
# Add to deploy workflow scripts
if [[ "$(id -u)" -eq 0 ]]; then
    echo "ERROR: Do not run deploy-service as root."
    echo "  The script uses SSH to reach Proxmox. Run as your normal user."
    exit 1
fi
```

**What NOT to add:**
- No JSON/YAML config -- bash can't natively parse those without jq/yq. Key=value is sufficient for flat infrastructure config.
- No encrypted config storage -- that's what vaultwarden MCP is for. config.env holds non-secret infrastructure topology (IPs, VMIDs, domains).
- No auto-discovery of infrastructure -- config is explicit. Auto-discovery adds fragility and network dependency.

**Gitignore addition:**

```
skills/deploy-service/config.env
```

---

### 6. Version Management

**What:** Track the skippy-agentspace version, provide a bump mechanism, and expose version in commands and install output.

**Stack decision: Plain `VERSION` file with semver string + inline bash bump function. No external tools.**

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `VERSION` file | N/A | Single file at repo root containing just the version string (e.g., `1.2.0`) | Same pattern as GSD (`~/.claude/get-shit-done/VERSION` contains `1.22.4`). Simple, universal, no parser needed. `cat VERSION` gives you the version. |
| Inline bash semver bump | N/A | `tools/version-bump.sh` -- 30-line script for `major`/`minor`/`patch` bumps | Zero dependencies. Pure bash string manipulation. No need for external semver tools for a project this size. |
| Git tag on bump | N/A | `git tag v$(cat VERSION)` after bump | Standard release tagging. Lets `/skippy:update` detect version changes in this repo too. |

**Why NOT use an external semver tool:**
- fsaintjacques/semver-tool and parleer/semver-bash are excellent but add a dependency for a 15-line function
- This project bumps versions maybe once per milestone -- the complexity of managing an external tool exceeds the complexity of the inline function
- If semver needs grow (pre-release labels, build metadata), revisit then

**VERSION file format:**

```
1.2.0
```

That's it. One line. No YAML wrapper. No JSON. Just the version string.

**Bump script (`tools/version-bump.sh`):**

```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="$(cd "$(dirname "$0")/.." && pwd)/VERSION"
CURRENT="$(cat "$VERSION_FILE")"

IFS='.' read -r major minor patch <<< "$CURRENT"

case "${1:-}" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *)
        echo "Usage: version-bump.sh [major|minor|patch]"
        echo "Current version: $CURRENT"
        exit 1
        ;;
esac

NEW="$major.$minor.$patch"
echo "$NEW" > "$VERSION_FILE"
echo "Version: $CURRENT -> $NEW"
```

**Integration points:**
- `tools/install.sh` prints version on `--help` and during install
- `tools/verify.sh` reports version in output header
- `SKILL.md` frontmatter `metadata.version` stays manually synced (or a version-bump hook updates it)
- `.claude-plugin/marketplace.json` includes version field
- Git tag created on version bump (optional, manual)

**What NOT to add:**
- No `package.json` version field -- this is not a Node.js project
- No CHANGELOG.md auto-generation -- overkill for solo dev with good commit messages
- No pre-release version labels (alpha, beta, rc) -- not needed for a private repo
- No CI-triggered version bumps -- manual bumps per milestone

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Markdown references for GSD patterns | Port gsd-tools.cjs to bash | If you need CLI state management. You don't -- direct file ops are simpler for skippy's needs. |
| Task() subagents for review swarm | Agent Teams (experimental) | When teammates need to communicate with each other. Review agents don't -- they report to orchestrator. |
| bats-core via brew + submodule helpers | bats via npm, or ShellSpec, or shunit2 | ShellSpec if you want BDD-style. shunit2 if you want xUnit-style. bats-core is the community standard with best Claude Code familiarity. |
| Single common.sh library | Multiple lib files by category | If common.sh exceeds ~200 lines. Currently projected at ~60 lines -- one file is fine. |
| Bash key=value config.env | JSON config with jq parsing | If config becomes nested (it won't -- infrastructure topology is flat). |
| Inline semver bump function | fsaintjacques/semver-tool | If you need pre-release labels, build metadata, or semver comparison. Not needed now. |
| Plain VERSION file | package.json version field | If this were a Node.js package. It isn't. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| gsd-tools.cjs porting | 592 lines + 11 lib modules of Node.js. Massive effort, ongoing sync burden. | Markdown references that teach Claude the patterns. Claude does the state ops directly. |
| Agent Teams for review | Experimental feature behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Adds token overhead. | Standard `Task()` subagents -- production-ready, well-understood. |
| npm bats-core package | Adds node_modules for a bash testing tool. Wrong ecosystem. | `brew install bats-core` for the runner, git submodules for helper libs. |
| ShellSpec/shunit2 | Less community adoption, less Claude familiarity, less ecosystem support. | bats-core is the de facto standard. |
| Complex config frameworks (TOML, YAML) | Require parsers (yq, toml-cli). deploy-service config is flat key=value. | Bash `source config.env` -- zero dependency. |
| Automated changelog generation | Overhead for solo dev. Good commit messages are sufficient. | Manual version bumps per milestone. |
| External semver libraries | Dependency for a 15-line function used once per milestone. | Inline bash bump in tools/version-bump.sh. |
| Docker for testing | Tests need access to `~/.claude/` paths. Docker isolation fights this. | Direct bats execution on host. |

## Stack Patterns by Capability

**If absorbing a GSD pattern:**
- Read the GSD workflow file (all in `~/.claude/get-shit-done/workflows/`)
- Distill the pattern into a skippy reference doc (150-250 lines max)
- Reference the `gsd-dependency-map.md` for file format dependencies
- Add a command file if the pattern needs a user-facing entry point
- Do NOT copy GSD code -- describe the pattern so Claude can execute it

**If adding a review agent role:**
- Define the role in `references/review-swarm.md`
- Specify: focus area, what files to read, what to check, output format
- Keep to 4 agents max. Add more only if a specific gap is proven.

**If writing bats tests:**
- One `.bats` file per script in `tools/`
- Source `tests/test_helper/common.bash` in `setup()`
- Use `setup_test_env` / `teardown_test_env` for isolation
- Test happy path, missing args, invalid input, and edge cases
- Target 30-50 lines per test file

**If extracting to common.sh:**
- Function must be used by 3+ scripts to justify extraction
- Keep function signatures simple (positional args, no options parsing)
- Never extract shell options (`set -euo pipefail`) -- keep in each script

**If adding deploy-service config:**
- Required variables go in config.env.example with `<placeholder>` values
- validate-config.sh checks for unset or placeholder values before any operation
- Root guard at the top of every script that touches Proxmox

**If bumping version:**
- Run `tools/version-bump.sh [major|minor|patch]`
- Commit the VERSION file change
- Optionally tag: `git tag v$(cat VERSION)`

## Version Compatibility

| Component | Requires | Notes |
|-----------|----------|-------|
| All bash scripts | Bash 4.0+ | macOS ships 3.2; `brew install bash` needed. Existing prereqs.sh checks this. |
| TypeScript hooks | Bun 1.0+ | Existing prerequisite. Hooks use `Bun.file()` and `Bun.spawn()`. |
| bats-core | 1.13.0 | `brew install bats-core`. New dev dependency. Add as optional check in prereqs.sh. |
| bats-assert | latest (git submodule) | Pinned to commit hash via submodule. No version drift. |
| bats-support | latest (git submodule) | Required dependency of bats-assert. |
| bats-file | latest (git submodule) | Optional but valuable for filesystem assertions. |
| Git | 2.20+ | For submodule support and `--quiet` flag. Any recent git works. |
| Claude Code | Any with skills/ and Task() support | Task() is the native subagent system. Available in all current versions. |
| GSD | 1.22+ (reference only) | Absorbed as reference docs. GSD is NOT a runtime dependency in v1.2. |
| jq | 1.6+ | Already in prereqs.sh. Used by existing scripts. |

## Installation Changes

```bash
# New dev dependency (testing only -- not required for runtime)
brew install bats-core

# Helper libraries (one-time setup after clone)
git submodule update --init --recursive

# Run tests
bats tests/

# Bump version
bash tools/version-bump.sh patch
```

**prereqs.sh update:** Add bats-core as an optional ("dev") check. Don't fail the prereq check if bats is missing -- it's only needed for development, not for using skills.

## Sources

- GSD workflows at `~/.claude/get-shit-done/workflows/` -- 33 files, 11,452 lines total. execute-phase.md (460 lines) and execute-plan.md (450 lines) are the primary absorption targets. [HIGH confidence, direct inspection]
- GSD bin at `~/.claude/get-shit-done/bin/` -- gsd-tools.cjs (592 lines) + 11 lib modules. Deliberately NOT ported. [HIGH confidence, direct inspection]
- GSD VERSION file -- contains `1.22.4` as plain text. Same format recommended for skippy. [HIGH confidence, direct inspection]
- Existing tools/ scripts -- 6 scripts with measurable duplication in REPO_ROOT setup, output helpers, and command checks. [HIGH confidence, grep analysis]
- deploy-service skill -- SKILL.md, deploy-workflow.md, find-next-ip.sh all contain `<your-*>` placeholders (8 unique placeholders). [HIGH confidence, direct inspection]
- [bats-core v1.13.0](https://github.com/bats-core/bats-core/releases/tag/v1.13.0) -- released Nov 2025, adds --negative-filter and --abort. Available via `brew install bats-core`. [HIGH confidence, brew info + release notes]
- [bats-core helper libraries](https://github.com/bats-core/bats-support) -- bats-support, bats-assert, bats-file. Official companion libraries. [HIGH confidence, GitHub repos]
- [bats-core documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- `load`, `run`, setup/teardown lifecycle. [HIGH confidence, official docs]
- [Claude Code subagent patterns](https://hamy.xyz/blog/2026-02_code-reviews-claude-subagents) -- 9 parallel review agents pattern. We scale to 4 for simplicity. [MEDIUM confidence, community blog]
- [Claude Code Agent Teams docs](https://code.claude.com/docs/en/agent-teams) -- official docs confirm Task() is the right tool for independent review agents. Agent Teams for cross-communication. [HIGH confidence, official docs]
- [Claude Code Swarm Orchestration patterns](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea) -- specialist subagent roles and structured output protocol. [MEDIUM confidence, community gist]
- [fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool) -- evaluated and rejected for this project's needs. Good tool, overkill here. [HIGH confidence, evaluated]
- [parleer/semver-bash](https://github.com/parleer/semver-bash) -- pure bash semver. Evaluated, rejected -- inline function is simpler for our use case. [HIGH confidence, evaluated]

---
*Stack research for: Standalone Skippy v1.2 -- GSD absorption, review swarm, testing, DRY extraction, deploy config, version management*
*Researched: 2026-03-08*
