# Architecture Research -- v1.2 Integration

**Domain:** Standalone skill framework -- absorbing GSD patterns, multi-agent audit, automated testing, shared libraries, config mechanism, version management
**Researched:** 2026-03-08
**Confidence:** HIGH (based on direct inspection of GSD source at ~/.claude/get-shit-done/, all existing scripts, hook system, and skill structure)
**Scope:** NEW features only -- how they integrate with existing v1.1 architecture

## System Overview -- v1.2 Additions

```
skippy-agentspace/
  skills/
    skippy/
      commands/
        reconcile.md               # EXISTING -- remove GSD dependency
        update.md                  # EXISTING -- unchanged
        cleanup.md                 # EXISTING -- unchanged
        migrate.md                 # EXISTING -- unchanged
        upgrade.md                 # EXISTING -- unchanged
        review.md                  # NEW -- multi-agent audit swarm
      references/
        context-brackets.md        # EXISTING
        reconciliation.md          # EXISTING
        task-anatomy.md            # EXISTING
        plan-boundaries.md         # EXISTING
        state-consistency.md       # EXISTING
        model-routing.md           # EXISTING
        verification-loops.md      # EXISTING
        session-persistence.md     # EXISTING
        structured-deliberation.md # EXISTING
        skill-extraction.md        # EXISTING
        gsd-dependency-map.md      # EXISTING -- UPDATE to mark absorbed patterns
        phased-execution.md        # NEW -- absorbed from GSD
        wave-parallelism.md        # NEW -- absorbed from GSD
        checkpoints.md             # NEW -- absorbed from GSD
        state-tracking.md          # NEW -- absorbed from GSD
        plan-structure.md          # NEW -- absorbed from GSD
      scripts/
        skippy-cleanup.sh          # EXISTING
      SKILL.md                     # MODIFY -- add new references + review command

    deploy-service/
      deploy.conf.example          # NEW -- example config file
      references/
        deploy-workflow.md         # EXISTING -- update placeholder refs
        nginx-proxy.conf           # EXISTING
        systemd-service.service    # EXISTING
      scripts/
        find-next-ip.sh            # MODIFY -- source config
        install-base-stack.sh      # EXISTING
      SKILL.md                     # MODIFY -- document config mechanism

  tools/
    lib/
      common.sh                    # NEW -- shared functions
    install.sh                     # MODIFY -- source lib/common.sh
    uninstall.sh                   # MODIFY -- source lib/common.sh
    verify.sh                      # MODIFY -- source lib/common.sh
    prereqs.sh                     # MODIFY -- source lib/common.sh
    index-sync.sh                  # MODIFY -- source lib/common.sh
    validate-hooks.sh              # MODIFY -- source lib/common.sh
    bump-version.sh                # NEW -- atomic version bump

  tests/
    test_helper/
      common.bash                  # NEW -- bats helper (loads bats-support/assert)
    install.bats                   # NEW -- install.sh tests
    uninstall.bats                 # NEW -- uninstall.sh tests
    verify.bats                    # NEW -- verify.sh tests
    index-sync.bats                # NEW -- index-sync.sh tests
    cleanup.bats                   # NEW -- skippy-cleanup.sh tests
    bump-version.bats              # NEW -- bump-version.sh tests
    common-lib.bats                # NEW -- common.sh function tests

  .github/
    workflows/
      test.yml                     # NEW -- CI workflow for bats
```

## Feature 1: GSD Pattern Absorption

### What Gets Absorbed

GSD's core intellectual property is 6 patterns. The existing skippy references already capture 5 PAUL-sourced ideas and 5 cross-package syntheses. The GSD patterns need their own reference docs so skippy can operate the phased execution lifecycle without requiring GSD at runtime.

| GSD Pattern | Source Files in GSD | New Reference Doc | Priority |
|-------------|--------------------|--------------------|----------|
| Phased execution (discuss/plan/execute/verify) | `workflows/discuss-phase.md`, `execute-phase.md`, `plan-phase.md`, `verify-work.md` | `references/phased-execution.md` | HIGH |
| Wave-based parallelism | `workflows/execute-plan.md` (Pattern A/B/C routing) | `references/wave-parallelism.md` | HIGH |
| Checkpoints | `references/checkpoints.md` (777 lines) | `references/checkpoints.md` | MEDIUM |
| State tracking (.planning/ lifecycle) | `bin/lib/state.cjs`, `templates/state.md` | `references/state-tracking.md` | HIGH |
| Plan structure (XML tasks, YAML frontmatter) | `templates/summary.md`, `workflows/execute-plan.md` | `references/plan-structure.md` | HIGH |
| Verification patterns | `references/verification-patterns.md` | Already covered by `verification-loops.md` | SKIP |

**Verification patterns are already handled.** The existing `verification-loops.md` synthesizes GSD's verify-work, OMC's UltraQA, and PAUL's task anatomy. No new doc needed.

### Where New Reference Docs Live

All new docs go in `skills/skippy/references/`. This follows the established pattern -- every reference doc in the existing skill is a standalone markdown file under `references/`. No new directories needed.

### How Standalone Commands Work Without GSD

**Current problem:** `/skippy:reconcile` heavily depends on GSD's `.planning/` file formats (see `gsd-dependency-map.md`). The existing command reads GSD-format PLAN.md, SUMMARY.md, STATE.md, and ROADMAP.md.

**v1.2 approach -- absorb the format, not the tool:**

1. The new reference docs (`plan-structure.md`, `state-tracking.md`) define the `.planning/` file formats as skippy's own specification. These formats originated in GSD but are now documented independently.

2. `/skippy:reconcile` continues reading the same file formats. The difference is conceptual: skippy now *owns* the format specification rather than depending on GSD's implementation.

3. The `gsd-dependency-map.md` gets a header update noting: "These formats are now part of skippy's specification. GSD compatibility is maintained by design, not dependency."

4. **No code changes to reconcile.md.** The command's process section already defines exactly how to parse PLAN.md, SUMMARY.md, etc. It works against the format, not against GSD tooling.

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `skippy/SKILL.md` | MODIFY | Add 5 new rows to the Enhancements table pointing to new reference docs |
| `skippy/references/gsd-dependency-map.md` | MODIFY | Add header noting format absorption; risks become "format drift" not "GSD dependency" |
| `CLAUDE.md` | MODIFY | Remove "No GSD modification" constraint, replace with "Skippy IS the framework" |

### What NOT to Absorb

Do NOT absorb GSD's tooling (`bin/gsd-tools.cjs`, `bin/lib/*.cjs`). That's Node.js infrastructure for state management, template rendering, and frontmatter parsing. Skippy's commands are markdown-driven (AI executes the instructions) -- no equivalent runtime tooling is needed.

Do NOT replicate GSD's 32 slash commands. Skippy has its own command set. The reference docs give agents enough context to execute phased workflows without GSD's `/gsd:execute-phase` etc.

## Feature 2: /skippy:review -- Multi-Agent Audit Swarm

### Command Architecture

`/skippy:review` is a new command at `skills/skippy/commands/review.md`. It follows the established command pattern: YAML frontmatter (name, description) + objective + execution_context + process.

### Agent Topology

The review swarm uses 3 agents in sequence (not parallel) because each builds on the prior's output:

```
Main Context (orchestrator)
    |
    v
[1] Reviewer Agent (sonnet)       -- reads code, produces findings
    | findings.md
    v
[2] Fixer Agent (sonnet)          -- reads findings, applies fixes
    | fix report
    v
[3] Evaluator Agent (opus)        -- grades fixes, accepts/rejects
    | final verdict
    v
Main Context                      -- presents results
```

### How It Fits the Skill System

**Command file:** `skills/skippy/commands/review.md`

Standard command structure:
```yaml
---
name: skippy:review
description: Multi-agent audit swarm -- reviewer finds issues, fixer resolves, evaluator grades
---
```

**No new skill directory needed.** The review command is part of skippy, not a separate skill. It's a command like reconcile, update, cleanup, migrate, and upgrade.

**Reference doc dependency:** The command's `<execution_context>` should reference `references/verification-loops.md` (for severity-rated review) and `references/model-routing.md` (for agent model selection).

### Sandboxing Strategy

Each agent runs in a spawned subagent context (Claude Code's `Task()` mechanism). The review command's `<process>` section should specify:

- **Reviewer:** Read-only. Uses Read, Glob, Grep tools only. No Bash, no Write, no Edit.
- **Fixer:** Full tool access. Applies fixes based on reviewer findings.
- **Evaluator:** Read-only + Bash (for running tests/build). Verifies fixes are correct.

The command markdown defines these constraints as agent prompts, not enforced sandboxes. This matches how GSD executor agents work -- constraints are in the spawning prompt.

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `skippy/commands/review.md` | NEW | ~120 lines following command pattern |
| `skippy/SKILL.md` | MODIFY | Add `/skippy:review` to Commands section |
| `.claude-plugin/marketplace.json` | NO CHANGE | skippy plugin already includes all commands in `skills/skippy` |
| `INDEX.md` | MODIFY | Add /skippy:review to skippy's Commands column |
| `tools/verify.sh` | MODIFY | Add review.md to the expected commands list (line 201) |

## Feature 3: bats-core Test Suite

### Directory Structure

```
tests/
  test_helper/
    common.bash            # Setup: BATS_LIB_PATH, load bats-support + bats-assert
  install.bats             # 8-12 tests: status display, single install, --all, --core, etc.
  uninstall.bats           # 6-8 tests: single uninstall, --all, dangling symlinks
  verify.bats              # 5-7 tests: prereq checks, skill checks, summary
  index-sync.bats          # 5-7 tests: --check, --generate, orphan detection
  cleanup.bats             # 4-6 tests: --quarantine, --nuke, empty targets
  bump-version.bats        # 4-5 tests: semver bump, dry-run, file discovery
  common-lib.bats          # 6-8 tests: each exported function in common.sh
```

**Estimated total:** ~260-340 lines across 7 test files + helper.

### Why tests/ at Repo Root (Not Inside a Skill)

Tests validate `tools/` scripts (repo-level infrastructure), not skill behavior. Placing them at root follows both the bats convention and the existing structure where `tools/` is repo-level infrastructure.

### bats Helper Setup

```bash
# tests/test_helper/common.bash
REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export REPO_ROOT

# Load bats assertion libraries
# Install: brew install bats-core bats-support bats-assert bats-file
load '/opt/homebrew/lib/bats-support/load.bash'
load '/opt/homebrew/lib/bats-assert/load.bash'

# Create isolated test environment
setup() {
    TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR"
    mkdir -p "$TEST_DIR/.claude/skills" "$TEST_DIR/.claude/commands"
}

teardown() {
    rm -rf "$TEST_DIR"
}
```

**Key pattern:** Override `$HOME` to an isolated temp directory. This prevents tests from touching real `~/.claude/` installation. Every test gets a clean environment.

### Integration with verify.sh

`verify.sh` is a runtime health check (is my installation correct?). bats tests are development-time tests (does the code work?). They serve different purposes and should NOT be merged.

However, verify.sh's check categories map directly to test files:

| verify.sh Category | bats Test File | Overlap |
|--------------------|--------------|---------|
| Prerequisites | (covered in prereqs tests) | prereqs.sh behavior |
| Skills | install.bats, uninstall.bats | Symlink creation/removal |
| Hooks | (covered by validate-hooks.sh) | Hook structure |
| Commands | verify.bats | Command file existence |
| Index | index-sync.bats | INDEX.md consistency |

### CI Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest    # macOS because scripts assume brew, BSD utils
    steps:
      - uses: actions/checkout@v4
      - name: Install bats
        run: brew install bats-core bats-support bats-assert bats-file
      - name: Run tests
        run: bats tests/
```

**macOS runner required** because the scripts use BSD `sed`, `readlink`, etc. Linux runners would need `coreutils` and may behave differently. Since the project targets macOS primarily (brew-based), macOS CI matches the target environment.

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `tests/` directory | NEW | 7 test files + helper |
| `tests/test_helper/common.bash` | NEW | Shared setup/teardown |
| `.github/workflows/test.yml` | NEW | CI workflow |
| `CLAUDE.md` | MODIFY | Add "Run tests: `bats tests/`" to project info |

## Feature 4: tools/lib/common.sh -- Shared Function Library

### What Gets Extracted

Scanning all 6 scripts in `tools/`, these patterns repeat:

**1. Repo root resolution (5 of 6 scripts):**
```bash
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
```

**2. Pass/fail/warn reporting (3 of 6 scripts):**
- `verify.sh`: `pass()`, `warn()`, `fail()`, `suggest()` with counters
- `validate-hooks.sh`: `pass()`, `fail()` with counters
- `prereqs.sh`: `report_ok()`, `report_missing()`, `report_outdated()` with counters

**3. Skill directory listing (3 of 6 scripts):**
- `install.sh`: iterates `$SKILLS_DIR/*/`
- `uninstall.sh`: iterates symlinks
- `index-sync.sh`: iterates `$SKILLS_DIR/*/`

**4. Install status detection (2 of 6 scripts):**
- `install.sh`: checks `$HOME/.claude/skills/$name` or `$HOME/.claude/commands/$name`
- `index-sync.sh`: `is_installed()` function -- identical logic

### Proposed common.sh API

```bash
# tools/lib/common.sh -- Shared functions for skippy-agentspace tools

# --- Path resolution ---
skippy_repo_root()       # Returns repo root (resolves from any script location)
skippy_skills_dir()      # Returns $REPO_ROOT/skills

# --- Reporting ---
skippy_pass()            # "  PASS: $1" + increment counter
skippy_warn()            # "  WARN: $1" + increment counter
skippy_fail()            # "  FAIL: $1" + increment counter
skippy_suggest()         # "    Fix: $1"
skippy_summary()         # Print "N passed, N warnings, N failures"
skippy_exit_status()     # Exit 0 if no failures, 1 otherwise

# --- Skill queries ---
skippy_is_installed()    # Check if skill is symlinked (modern or legacy)
skippy_list_skills()     # List all skill directories
skippy_skill_category()  # Extract category from SKILL.md frontmatter
```

### How to Source Without Breaking Standalone

**The critical constraint:** Each script must still work standalone (no build step, single-file execution). The `source` path must be reliable regardless of how the script is invoked.

**Pattern:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared library (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null || {
    # Fallback: inline minimal versions if common.sh missing
    echo "WARN: tools/lib/common.sh not found -- using inline fallbacks"
    skippy_repo_root() { cd "$(dirname "$0")/.." && pwd; }
    skippy_pass() { echo "  PASS: $1"; }
    skippy_fail() { echo "  FAIL: $1"; }
}
```

**Why the fallback matters:** If someone copies a single script out of the repo (e.g., just `verify.sh`), it should degrade gracefully -- not crash with "source: file not found." The fallback provides minimal inline implementations.

**For skill scripts** (`skills/*/scripts/*.sh`): Do NOT source common.sh. Skill scripts are independently installable and may not have `tools/lib/` in their path. The DRY extraction only applies to `tools/` scripts.

### Sourcing Path Problem

Scripts in `tools/` source from `tools/lib/common.sh` -- straightforward via `$SCRIPT_DIR/lib/common.sh`.

But `validate-hooks.sh` is also in `tools/` and uses the same patterns, so it works the same way.

`skippy-cleanup.sh` is in `skills/skippy/scripts/` and should NOT source common.sh. It's a skill script, not a tool script. Leave it standalone.

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `tools/lib/common.sh` | NEW | ~80-100 lines of shared functions |
| `tools/install.sh` | MODIFY | Replace inline functions with sourced versions |
| `tools/uninstall.sh` | MODIFY | Replace inline repo root resolution |
| `tools/verify.sh` | MODIFY | Replace inline pass/fail/warn with sourced versions |
| `tools/prereqs.sh` | MODIFY | Replace report_ok/report_missing with sourced versions |
| `tools/index-sync.sh` | MODIFY | Replace is_installed(), repo root resolution |
| `tools/validate-hooks.sh` | MODIFY | Replace inline pass/fail with sourced versions |

## Feature 5: deploy-service Configuration Mechanism

### Current Problem

`deploy-service` has 5 hardcoded placeholders throughout its files:

| Placeholder | Files | Purpose |
|-------------|-------|---------|
| `<your-server-ip>` | deploy-workflow.md, SKILL.md | Proxmox host |
| `<your-domain>` | deploy-workflow.md, SKILL.md | Wildcard SSL domain |
| `<your-proxy-host>` | deploy-workflow.md | nginx proxy LXC |
| `<your-dns-servers>` | deploy-workflow.md, find-next-ip.sh | DNS server IPs |
| `<your-network-1>`, `<your-network-2>` | find-next-ip.sh | Dual-NIC subnets |
| `<your-vaultwarden-url>` | install-base-stack.sh | Vaultwarden URL |
| `<your-proxy-vmid>` | deploy-workflow.md | Proxy container VMID |
| `<your-gateway>` | deploy-workflow.md | Network gateway |
| `<your-proxy-ip>` | deploy-workflow.md | Proxy server IP |

### Configuration File Design

**Location:** `skills/deploy-service/deploy.conf`

**Format:** Shell-sourceable key=value (simplest possible, no dependencies):

```bash
# deploy.conf -- deploy-service configuration
# Copy from deploy.conf.example and fill in your values.

# Proxmox host
DEPLOY_SERVER_IP=""

# Domain (wildcard SSL)
DEPLOY_DOMAIN=""

# Proxy LXC
DEPLOY_PROXY_HOST=""
DEPLOY_PROXY_VMID=""
DEPLOY_PROXY_IP=""

# Networking
DEPLOY_GATEWAY=""
DEPLOY_NET1=""        # e.g., 10.0.1
DEPLOY_NET2=""        # e.g., 10.0.2
DEPLOY_DNS_SERVERS="" # space-separated

# Vaultwarden
DEPLOY_VAULTWARDEN_URL=""
```

**Why shell key=value, not JSON/YAML:**
- Scripts can `source deploy.conf` directly -- zero parsing code
- No `jq` dependency for a domain-specific skill
- Users edit with any text editor
- `.gitignore` already covers `*.conf` pattern (add if needed)

### How Scripts Source the Config

```bash
# In find-next-ip.sh:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF="$SKILL_DIR/deploy.conf"

if [[ -f "$CONF" ]]; then
    source "$CONF"
else
    echo "ERROR: deploy.conf not found. Copy deploy.conf.example to deploy.conf and configure." >&2
    exit 1
fi

NET1="${DEPLOY_NET1:?DEPLOY_NET1 not set in deploy.conf}"
NET2="${DEPLOY_NET2:?DEPLOY_NET2 not set in deploy.conf}"
```

### Input Validation

Add a validation function in the deploy-workflow.md process section (AI-executed, not a script):

```
Before executing deployment:
1. Verify deploy.conf exists
2. Check all required variables are non-empty
3. Validate IP format (grep -E pattern)
4. Validate domain format (no protocol prefix)
5. Test SSH connectivity to DEPLOY_SERVER_IP
```

### Root Guard

`install-base-stack.sh` runs inside an LXC container via `pct exec` -- it's already running as root inside the container. The script itself doesn't need a root guard. But the deploy-workflow.md should validate that the SSH user has `pct` access before starting.

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `skills/deploy-service/deploy.conf.example` | NEW | Template with all variables, empty values |
| `skills/deploy-service/deploy.conf` | NEW (user creates) | .gitignore'd -- contains real values |
| `skills/deploy-service/scripts/find-next-ip.sh` | MODIFY | Source deploy.conf instead of inline placeholders |
| `skills/deploy-service/references/deploy-workflow.md` | MODIFY | Reference deploy.conf variables instead of angle-bracket placeholders |
| `skills/deploy-service/SKILL.md` | MODIFY | Document: "Copy deploy.conf.example, fill values" |
| `.gitignore` | MODIFY | Add `deploy.conf` (not the .example) |

## Feature 6: Version Bump Mechanism

### Version String Inventory

Version `0.1.0` appears in **25 locations** across 2 file types:

| File | Count | Format |
|------|-------|--------|
| `.claude-plugin/marketplace.json` | 13 | `"version": "0.1.0"` (1 top-level + 12 per-plugin) |
| `skills/*/SKILL.md` (12 skills) | 12 | `  version: 0.1.0` (YAML frontmatter) |
| **Total** | **25** | |

### bump-version.sh Design

```bash
#!/usr/bin/env bash
# bump-version.sh -- Atomically bump version across all 25 locations
#
# Usage:
#   bump-version.sh <new-version>           # Bump to specific version
#   bump-version.sh --patch                  # 0.1.0 -> 0.1.1
#   bump-version.sh --minor                  # 0.1.0 -> 0.2.0
#   bump-version.sh --major                  # 0.1.0 -> 1.0.0
#   bump-version.sh --dry-run <version>      # Show what would change
```

**Implementation strategy:**

1. Read current version from `marketplace.json` top-level `metadata.version` (single source of truth for "what version are we on now?")
2. Calculate new version (explicit or semver increment)
3. Discover all version locations:
   - `marketplace.json`: `jq` to update all 13 `.version` fields
   - `skills/*/SKILL.md`: `sed` to update YAML frontmatter `version:` line
4. `--dry-run`: Show file + line + old -> new for each location
5. Report: "Updated N files, N locations. Old: X, New: Y"

**Why a single script, not a `VERSION` file:**

GSD uses a `VERSION` file and distributes it. But skippy's version lives inside 25 files that are read by different consumers (marketplace.json by Claude Code's plugin system, SKILL.md by skill discovery). A VERSION file would be a 26th location that needs syncing. Instead, `marketplace.json` metadata.version is the canonical source, and `bump-version.sh` propagates atomically.

### Atomicity

The script modifies files in-place with `sed` and `jq`. If it fails mid-way, some files will have the new version and others won't. To handle this:

1. Validate all files exist before starting
2. Count expected replacements
3. After replacement, count actual replacements
4. If mismatch, report which files failed (but don't attempt rollback -- git handles that via `git checkout -- .`)

### Integration Points

| Integration | Type | Details |
|-------------|------|---------|
| `tools/bump-version.sh` | NEW | ~120 lines |
| `tools/lib/common.sh` | USED | Sources shared functions |
| `.claude-plugin/marketplace.json` | READ | Canonical version source |
| All 12 `skills/*/SKILL.md` | MODIFIED BY | sed replacement target |

## Data Flow -- How Features Interact

```
bump-version.sh -----> marketplace.json (canonical version)
      |                      |
      +----> skills/*/SKILL.md (12 files)
      |
      +----> (future: git tag)

common.sh <---- sourced by ---- tools/*.sh (6 scripts)
      |
      NOT sourced by ---- skills/*/scripts/*.sh (standalone)

tests/*.bats ----> tools/*.sh (under test)
      |
      +----> tests/test_helper/common.bash (shared setup)
      |
      NOT testing ---- skills/ (skill behavior is AI-driven)

review.md (command) ----> spawns 3 agents (reviewer, fixer, evaluator)
      |
      references ---- verification-loops.md, model-routing.md

deploy.conf ----> sourced by ---- deploy-service/scripts/*.sh
      |
      .gitignore'd (contains infrastructure secrets)
      deploy.conf.example tracked (template)

GSD reference docs ----> loaded by agents on demand
      |
      NOT runtime dependencies (AI reads and follows instructions)
```

## Build Order -- Dependency-Aware

```
Phase 1: tools/lib/common.sh + bats infrastructure
  - common.sh has NO dependencies on other new features
  - bats tests validate existing scripts (regression safety net)
  - Build order within phase: common.sh first, then refactor tools/, then tests

Phase 2: GSD pattern absorption (reference docs)
  - NO dependencies on Phase 1 (pure markdown)
  - Can run in PARALLEL with Phase 1
  - Build order within phase: plan-structure.md, state-tracking.md, phased-execution.md,
    wave-parallelism.md, checkpoints.md (ordered by dependency)

Phase 3: /skippy:review command
  - Depends on NOTHING new (references already exist from v1.1)
  - Can run in PARALLEL with Phases 1-2
  - Self-contained: one new file + two SKILL.md/INDEX.md updates

Phase 4: deploy-service config mechanism
  - Depends on NOTHING new
  - Can run in PARALLEL with Phases 1-3
  - Self-contained: config file + script modifications

Phase 5: Version bump mechanism
  - SHOULD come after common.sh (Phase 1) to source shared functions
  - SHOULD come after bats tests exist (Phase 1) to include bump-version.bats
  - Sequential after Phase 1

Phase 6: Integration + docs
  - Depends on ALL above
  - CONTRIBUTING.md, .gitattributes, CLAUDE.md updates, final verify
```

**Parallelism:** Phases 1-4 are fully independent. Phase 5 depends on 1. Phase 6 depends on all.

**Suggested wave structure:**

```
Wave 1: [Phase 1] [Phase 2] [Phase 3] [Phase 4]   (all parallel)
Wave 2: [Phase 5]                                   (needs Phase 1)
Wave 3: [Phase 6]                                   (needs all)
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Sourcing common.sh in Skill Scripts

**What people do:** Apply DRY extraction to `skills/*/scripts/*.sh` too.
**Why it's wrong:** Skill scripts are symlinked into `~/.claude/skills/` -- they can't reliably resolve `../../tools/lib/common.sh`. The path from installed skill to repo tools/ is not guaranteed.
**Do this instead:** Only `tools/` scripts source common.sh. Skill scripts remain standalone.

### Anti-Pattern 2: Making Tests Depend on Real ~/.claude/

**What people do:** Run bats tests against actual installation.
**Why it's wrong:** Tests modify state, flaky on different machines, can break real installation.
**Do this instead:** Override `$HOME` to temp directory in `setup()`. Every test is isolated.

### Anti-Pattern 3: Absorbing GSD's Runtime Tooling

**What people do:** Port `gsd-tools.cjs` and its 9 library modules to make skippy fully standalone.
**Why it's wrong:** 2000+ lines of Node.js for state management, template rendering, frontmatter parsing. Skippy's commands are AI-driven -- the agent reads markdown instructions and executes them. No runtime tooling needed.
**Do this instead:** Write reference docs that describe the patterns. The AI IS the runtime.

### Anti-Pattern 4: Single VERSION File as Source

**What people do:** Create a `VERSION` file and have all other files read from it.
**Why it's wrong:** SKILL.md and marketplace.json can't dynamically read a VERSION file -- they're static files consumed by Claude Code's discovery system. You'd need a build step to template them, violating the "no build step" constraint.
**Do this instead:** `bump-version.sh` does atomic find-and-replace across all 25 locations. The canonical version lives in `marketplace.json` metadata.

### Anti-Pattern 5: deploy.conf in ~/.config/

**What people do:** Put config in a global location for "cleanliness."
**Why it's wrong:** deploy-service is a skill that symlinks into `~/.claude/skills/`. The config must be discoverable relative to the skill directory, not a global path that may not exist.
**Do this instead:** `deploy.conf` lives next to `SKILL.md` in the skill directory. Discovered via `$SKILL_DIR/deploy.conf` or `$CLAUDE_SKILL_DIR/deploy.conf`.

## Scaling Considerations

| Concern | At v1.2 (25 version strings) | At v2.0 (50+ skills) | Mitigation |
|---------|------------------------------|---------------------|------------|
| Version bump speed | Instant (<1s for 25 files) | ~2s for 50 files | Still fine -- sed is fast |
| bats test suite | ~260 lines, runs in <5s | ~500 lines, <10s | Keep tests focused on tools/ |
| common.sh complexity | ~80-100 lines, 10 functions | ~150 lines, 15 functions | Split into common-path.sh, common-report.sh if >200 lines |
| GSD reference doc count | 5 new docs (~200 lines each) | Stable (GSD patterns don't grow) | No concern |

## Sources

- Direct inspection of GSD source: `~/.claude/get-shit-done/` (VERSION 1.22.4, 34 workflows, 13 references, 27 templates)
- Direct inspection of all 6 `tools/` scripts for DRY pattern analysis
- Direct inspection of `skills/deploy-service/` for placeholder analysis
- Grep analysis: 25 version string locations across 13 files
- bats-core documentation: [bats-core.readthedocs.io](https://bats-core.readthedocs.io/en/stable/)
- bats practical guide: [hackerone.com/blog/testing-bash-scripts-bats](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide)
- v1.1 architecture research (this file's predecessor, 2026-03-07)
- GSD `workflows/execute-plan.md` for wave-based parallelism and checkpoint patterns
- GSD `references/checkpoints.md` for checkpoint type taxonomy (777 lines)
- GSD `references/verification-patterns.md` for verification approaches (already synthesized in v1.1)

---
*Architecture research for: skippy-agentspace v1.2 -- Standalone Skippy*
*Researched: 2026-03-08*
