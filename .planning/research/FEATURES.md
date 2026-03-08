# Feature Research

**Domain:** Claude Code skill framework -- standalone execution, testing, multi-agent review, deployment hardening
**Researched:** 2026-03-08
**Confidence:** HIGH (most features researched against existing codebase + official docs)

## Feature Landscape

### Table Stakes (Users Expect These)

Features that a standalone skill framework must have. Missing these = the product still depends on GSD at runtime.

| Feature | Why Expected | Complexity | Depends On | Notes |
|---------|--------------|------------|------------|-------|
| GSD pattern absorption -- phased execution reference docs | Framework claims standalone; can't require GSD installed to understand phased execution, wave parallelism, state tracking, verification | MEDIUM | Nothing (first priority) | 6-8 reference docs synthesizing GSD's execute-phase, plan-phase, verify-work, checkpoints, state.md lifecycle, and wave-based parallelism. Same pattern as existing PAUL/OMC cherry-picks in `references/`. Not code -- markdown guidance agents load on demand |
| GSD pattern absorption -- command independence | `/skippy:reconcile` currently references GSD's `.planning/` structure. All skippy commands must work without GSD installed | LOW | Reference docs above | Commands already work standalone -- they read `.planning/` files directly. Validate they never import or exec GSD's `gsd-tools.cjs`. Add a `references/planning-structure.md` doc so agents know the file layout without GSD |
| Shared shell library (`tools/lib/common.sh`) | 6 tool scripts (1507 lines) duplicate REPO_ROOT detection, SKILLS_DIR setup, error output patterns, skill iteration loops. DRY violation makes maintenance painful | MEDIUM | Nothing | Extract: `resolve_repo_root()`, `resolve_skills_dir()`, `log_info/warn/error()`, `iterate_skills()`, `check_skill_exists()`, `read_frontmatter_field()`, `detect_install_target()`. Source via `. "$(dirname "$0")/lib/common.sh"`. Use `local` vars, prefix with `_skippy_` namespace to avoid conflicts |
| bats-core test suite | Shell scripts have zero automated tests. 11 scripts, 1500+ lines, critical install/uninstall/verify logic untested. Any refactoring (like DRY extraction) without tests is reckless | MEDIUM | Shared library (test the extracted functions) | Install via `git submodule add` under `test/libs/`. Target ~30 test cases covering: install.sh (modern/legacy/all/core modes), uninstall.sh (single/all/hooks), verify.sh (pass/fail scenarios), common.sh (every extracted function), index-sync.sh (generate/validate). ~260+ lines total |
| Version bump mechanism | Versions scattered across marketplace.json (13 occurrences of "0.1.0"), 12 SKILL.md frontmatter files. Manual bumping is error-prone and will be forgotten | LOW | Nothing | Single `tools/bump-version.sh` script. Read current version from VERSION file, bump major/minor/patch, update all SKILL.md frontmatter + marketplace.json. Tag with `git tag v$NEW_VERSION` |
| `.gitattributes` export-ignore | `.planning/` artifacts shouldn't ship in git archives or plugin downloads | LOW | Nothing | Single file, 2-3 lines: `.planning/ export-ignore`, `test/ export-ignore` |
| CONTRIBUTING.md | External contributors (or future-self after 6 months) need to know how to add skills, run tests, and follow conventions | LOW | Test suite (reference how to run tests) | Standard contributing guide: skill structure, naming conventions, test requirements, PR process |

### Differentiators (Competitive Advantage)

Features that make skippy-agentspace more than "GSD with extra docs." Not expected in a skill repo, but high-value.

| Feature | Value Proposition | Complexity | Depends On | Notes |
|---------|-------------------|------------|------------|-------|
| `/skippy:review` audit swarm command | Multi-agent code review that spawns N specialized reviewers (security, performance, correctness, style) in parallel, collects findings with severity ratings, synthesizes into a single report, and optionally applies fixes in a sandboxed branch | HIGH | Shared library (for script helpers), GSD pattern absorption (verification loop patterns inform the cycling) | This is the headline feature of v1.2. Pattern: orchestrator spawns 3-5 Task() agents with different review angles, each returns structured findings (file, line, severity, category, description, suggestion). Orchestrator deduplicates, ranks by severity, presents unified report. Optionally spawns a fixer agent on a throwaway branch for CRITICAL/HIGH findings. User decides what to merge |
| deploy-service configuration mechanism | deploy-service currently has `<your-server-ip>` placeholders everywhere. A real config mechanism makes it usable without manual find-replace on every deployment | MEDIUM | Shared library (for config loading helpers) | Use a `deploy-service.conf` file (shell-sourceable key=value, NOT dotenv -- no Node dependency). Loaded by scripts at runtime. Template ships with placeholder values and comments. Config file is gitignored (private content). Validate required values at script start with clear error messages |
| deploy-service input validation + root guards | Scripts currently trust all input -- no validation of service names, ports, RAM/disk values. No check for root vs non-root execution context | LOW | Config mechanism above | Add validation functions: `validate_service_name()` (alphanumeric + hyphens only), `validate_port()` (1024-65535 integer), `validate_size()` (number + unit). Add root guard: deploy scripts that SSH to Proxmox need confirmation, not accidental execution |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full GSD runtime absorption (reimplementing gsd-tools.cjs) | "Make skippy completely replace GSD" | gsd-tools.cjs is 2000+ lines of Node.js handling init, commit, roadmap parsing, config management. Reimplementing = massive maintenance burden and version drift against upstream | Absorb GSD's *patterns* as reference docs. Keep GSD as optional runtime enhancer. Skippy works standalone but GSD adds power when present |
| Auto-fixing in review swarm without user approval | "Just fix everything the swarm finds" | Autonomous code changes from multiple agents without human review defeats the purpose of an audit. Risk of conflicting fixes, false positives applied as code changes | Present findings, optionally prepare fixes on a sandboxed branch, but user approves merge. Same philosophy as `/skippy:update` -- report, human decides |
| Node.js/TypeScript test framework instead of bats-core | "Bun test is already a dependency for hooks" | Hooks are TypeScript. Tool scripts are bash. Testing bash with JavaScript creates a layer of indirection, subprocess management complexity, and non-obvious failure modes | Use bats-core for shell scripts (tests what they are). Hooks already have their own validation via `validate-hooks.sh`. Keep test stacks matched to source language |
| Semantic-release / conventional-changelog automation | "Full release pipeline with changelogs" | This is a private single-developer repo. Conventional commits are already used but the full semantic-release pipeline (npm publish, GitHub releases, changelogs) is overhead for git-based distribution | Simple `bump-version.sh` script with manual semver argument. No changelog generation -- ROADMAP.md and git log serve that purpose |
| Per-skill version tracking | "Each skill should have its own semver" | 12 skills, all in the same repo, all installed together. Independent versioning creates combinatorial compatibility questions for zero benefit in a monorepo | Single repo-level version. All skills share the same version. Bump once, update everywhere |
| Cross-skill dependencies | "Skill A should import from Skill B" | Creates coupling. One skill change cascades. Installation order matters. Debugging becomes hell | Self-contained skills. The shared library is for tools/, not for skills/. Skills remain standalone per existing constraint |

## Feature Dependencies

```
[Shared Shell Library (common.sh)]
    |
    +--enables--> [bats-core Test Suite] (test the extracted functions)
    |
    +--enables--> [deploy-service Config Mechanism] (config loading helpers)
    |                  |
    |                  +--enables--> [deploy-service Validation] (validate config values)
    |
    +--enables--> [/skippy:review Audit Swarm] (script utilities)

[GSD Pattern Absorption -- Reference Docs]
    |
    +--enables--> [GSD Command Independence Validation]
    |
    +--informs--> [/skippy:review Audit Swarm] (verification loop patterns)

[Version Bump Mechanism] -- standalone, no dependencies

[.gitattributes] -- standalone, no dependencies

[CONTRIBUTING.md]
    +--references--> [bats-core Test Suite] (how to run tests)
    +--references--> [Shared Shell Library] (coding conventions)
```

### Dependency Notes

- **bats-core requires shared library:** Testing extracted functions is the primary value. Testing duplicated code across 6 scripts is possible but wasteful -- extract first, test the canonical implementation.
- **deploy-service config requires shared library:** Config loading (source file, validate required keys, report missing) is a reusable pattern belonging in common.sh, not duplicated in deploy-service scripts.
- **Audit swarm is high-complexity and benefits from everything else being stable.** Build it last after the foundation (library, tests, GSD patterns) is solid.
- **Version bump and .gitattributes are independent.** Can slot into any phase as quick wins.

## Detailed Feature Research

### 1. GSD Pattern Absorption

**What GSD provides that skippy needs as standalone reference docs:**

| GSD Concept | Source File(s) | Skippy Reference Doc Target | Complexity |
|------------|----------------|------------------------------|------------|
| Phased execution lifecycle | `workflows/execute-phase.md` (460 lines) | `references/phased-execution.md` | MEDIUM |
| Wave-based parallel execution | `workflows/execute-phase.md` (execute_waves step) | `references/wave-parallelism.md` | LOW |
| Plan structure + task anatomy | `templates/phase-prompt.md` + existing `references/task-anatomy.md` | Update existing `task-anatomy.md` with GSD plan template fields (wave, depends_on, must_haves) | LOW |
| State tracking lifecycle | `templates/state.md` (177 lines) | `references/state-tracking.md` | LOW |
| Checkpoint handling | `references/checkpoints.md` (777 lines) | `references/checkpoint-patterns.md` | MEDIUM |
| Verification patterns | `references/verification-patterns.md` (613 lines) + `workflows/verify-work.md` (584 lines) | Update existing `references/verification-loops.md` with GSD verification patterns (stub detection, wiring checks, must_haves) | MEDIUM |
| Planning structure (.planning/ layout) | `templates/project.md`, `templates/roadmap.md`, `templates/state.md` | `references/planning-structure.md` | LOW |

**Absorption approach:** Same pattern used successfully for 10 existing reference docs (PAUL and OMC cherry-picks). Read upstream source, extract the transferable pattern, write as a standalone reference doc that any agent can load. Never copy GSD verbatim -- synthesize the principle.

**What NOT to absorb:**
- `gsd-tools.cjs` -- Node.js CLI that handles init, commit, roadmap parsing, config management. Too large and coupled to Node.js runtime.
- `bin/` scripts -- GSD's binary tools. Skippy's commands work without them.
- Agent definitions (`agents/*.md`) -- GSD's agent prompts are its own IP. Skippy synthesizes the patterns, not the prompts.

**Confidence:** HIGH -- this is the same process successfully used for 10 existing reference docs in v1.0 and v1.1.

### 2. Multi-Agent Audit Swarm (`/skippy:review`)

**How audit swarms work in the Claude Code ecosystem (2026):**

The audit swarm pattern has emerged as one of the most successful multi-agent use cases in Claude Code. Key elements from ecosystem research:

**Architecture:**
1. **Orchestrator** (main context) -- stays lean (~10-15% context), coordinates agents
2. **Specialist agents** (3-5 parallel) -- each has a focused review angle and fresh 200k context
3. **Synthesis step** -- orchestrator deduplicates and ranks findings
4. **Optional fixer** -- applies approved fixes on a sandboxed branch

**Specialist angles proven effective:**
- Security: injection, auth bypass, secret exposure, dependency vulnerabilities
- Correctness: logic errors, edge cases, error handling gaps, race conditions
- Performance: N+1 queries, unnecessary re-renders, memory leaks, blocking calls
- Maintainability: DRY violations, unclear naming, missing docs, dead code
- Conventions: project-specific rules from CLAUDE.md, CONVENTIONS.md

**Best practices from ecosystem:**
- 3-5 specialists maximum. More creates coordination overhead exceeding value (metaswarm uses 5 for design review gate, 3-iteration cap).
- Each specialist returns structured findings: `{file, line, severity, category, description, suggestion}`
- Orchestrator deduplicates by file+line proximity (within 3 lines = same finding)
- Severity: CRITICAL (must fix) > HIGH (should fix) > MEDIUM (recommended) > LOW (optional)
- Only CRITICAL and HIGH trigger optional fix suggestions
- Sandboxed fixes: create branch `review/YYYY-MM-DD`, apply fixes, user merges or discards

**Implementation for skippy:**
- New command at `skills/skippy-dev/commands/review.md`
- Command describes the orchestration pattern (spawn agents, collect findings, synthesize)
- Agents read `CLAUDE.md`, `CONVENTIONS.md`, and project-specific rules for context
- Scope: current branch diff from main (default), specific files (argument), or full codebase (`--all`)
- Output: structured report printed to terminal, optionally saved to `.planning/reviews/`
- Findings format follows existing verification-loops.md severity framework

**Confidence:** HIGH -- the multi-agent pattern is well-established in Claude Code, and the specific audit swarm variant has multiple proven implementations (metaswarm, OMC's code-review skill).

### 3. bats-core Testing

**Framework specifics (verified via official docs):**

- **Version:** 1.x (stable), Bash 3.2+ compatible (matches prereqs.sh compatibility target)
- **Installation:** `brew install bats-core` or git submodule (prefer submodule for repo-local reproducibility)
- **Helper libraries:** bats-assert, bats-support, bats-file -- install as submodules under `test/libs/`
- **Test file convention:** `test/*.bats`, named after script being tested

**Key syntax:**
```bash
@test "install.sh installs skill to modern target" {
  run bash "$REPO_ROOT/tools/install.sh" skippy-dev --target=skills
  assert_success
  assert_output --partial "INSTALLED (skills): skippy-dev"
  [ -L "$TEST_HOME/.claude/skills/skippy-dev" ]
}
```

**Test structure for this project:**

```
test/
  libs/              # git submodules: bats-core, bats-assert, bats-support, bats-file
  test_helper.bash   # shared setup: source common.sh, create temp dirs, set PATH
  install.bats       # install.sh tests (~8 cases)
  uninstall.bats     # uninstall.sh tests (~5 cases)
  verify.bats        # verify.sh tests (~5 cases)
  common.bats        # common.sh function tests (~8 cases)
  index-sync.bats    # index-sync.sh tests (~4 cases)
  bump-version.bats  # bump-version.sh tests (~4 cases)
```

**Testing patterns for this codebase:**
- `setup()` creates a temp skill directory with mock SKILL.md files, overrides HOME
- `teardown()` cleans up temp dirs and unsets env vars
- Use `run` helper + `assert_success`/`assert_failure` + `assert_output --partial`
- Test install.sh in both `--target=skills` and `--target=commands` modes against temp dirs
- Test verify.sh against known-good and known-bad skill fixtures
- Test common.sh functions individually (pure function testing)

**Estimated scope:** ~30 test cases, ~260-350 lines. Covers all 6 existing tool scripts plus the new common.sh and bump-version.sh.

**Confidence:** HIGH -- bats-core is the standard for bash testing, well-documented, stable API.

### 4. Shared Shell Library (`tools/lib/common.sh`)

**What to extract from existing 6 scripts (1507 lines):**

| Function | Currently Duplicated In | Purpose |
|----------|------------------------|---------|
| `_skippy_resolve_repo_root()` | install.sh, uninstall.sh, index-sync.sh, validate-hooks.sh, verify.sh | `$(cd "$(dirname "$0")/.." && pwd)` pattern |
| `_skippy_resolve_skills_dir()` | install.sh, uninstall.sh, index-sync.sh, verify.sh | `$REPO_ROOT/skills` with existence check |
| `_skippy_log_info()` | Ad-hoc `echo` across all scripts | Consistent `INFO:` prefix |
| `_skippy_log_warn()` | verify.sh has `warn()`, others use ad-hoc echo | Consistent `WARN:` prefix + optional counter |
| `_skippy_log_error()` | install.sh has several `echo "ERROR:` patterns | Consistent `ERROR:` prefix to stderr |
| `_skippy_iterate_skills()` | install.sh, index-sync.sh, verify.sh | `for skill_dir in "$SKILLS_DIR"/*/; do` pattern |
| `_skippy_check_skill_exists()` | install.sh (lines 147-155) | Validate skill dir + SKILL.md presence |
| `_skippy_read_frontmatter()` | install.sh, index-sync.sh, verify.sh | Parse SKILL.md YAML frontmatter fields with sed |
| `_skippy_detect_install_target()` | install.sh (detect_target function) | Modern vs legacy install target detection |

**Library conventions (following gruntwork-io/bash-commons best practices):**
- File: `tools/lib/common.sh`
- All functions prefixed `_skippy_` to avoid namespace collisions
- All variables declared `local` inside functions
- No global state -- functions take arguments, return via stdout or exit codes
- Log functions write to stderr (info/warn/error), data functions write to stdout
- Sourced via: `. "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"` (relative to calling script)
- Library file target: ~80-120 lines

**Confidence:** HIGH -- the duplicated patterns are clearly visible in existing code via grep analysis.

### 5. deploy-service Configuration

**Mechanism: shell-sourceable config file**

```bash
# deploy-service.conf.example (ships with repo, public)
DEPLOY_SERVER_IP=""           # Proxmox host IP
DEPLOY_DOMAIN=""              # Wildcard SSL domain
DEPLOY_PROXY_HOST=""          # VMID of nginx reverse proxy LXC
DEPLOY_PROXY_IP=""            # IP of proxy for DNS entries
DEPLOY_NET1_PREFIX=""         # e.g., 10.0.1
DEPLOY_NET2_PREFIX=""         # e.g., 10.0.2
DEPLOY_GATEWAY=""             # Gateway IP
DEPLOY_DNS_SERVERS=""         # Comma-separated DNS server VMIDs
DEPLOY_VMID_OFFSET=200        # Base VMID offset
DEPLOY_START_OCTET=13         # Starting IP octet to scan
```

**Loading pattern (uses shared library helpers):**
```bash
_skippy_load_deploy_config() {
  local config_file="${SKIPPY_DEPLOY_CONFIG:-$REPO_ROOT/skills/deploy-service/deploy-service.conf}"
  if [[ ! -f "$config_file" ]]; then
    _skippy_log_error "Config not found: $config_file"
    _skippy_log_error "Copy deploy-service.conf.example and fill in your values"
    return 1
  fi
  . "$config_file"
  local required=(DEPLOY_SERVER_IP DEPLOY_DOMAIN DEPLOY_PROXY_HOST DEPLOY_NET1_PREFIX DEPLOY_NET2_PREFIX)
  for var in "${required[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      _skippy_log_error "Required config missing: $var"
      return 1
    fi
  done
}
```

**Why shell-sourceable over JSON or dotenv:**
- No `jq` dependency for config reading (jq is for tools/ JSON manipulation, not runtime config)
- No Node.js/bun dependency
- Natural bash integration -- vars directly available after sourcing
- Consistent with project constraint: "shell scripts + markdown only"
- `.conf` extension distinguishes from `.env` (which implies Node.js dotenv semantics)

**Input validation functions:**
- `validate_service_name()` -- alphanumeric + hyphens, 1-63 chars (DNS label rules)
- `validate_port()` -- integer, 1024-65535 range
- `validate_size()` -- number + optional unit (512M, 2G, etc.)
- Root guard: require explicit `--yes-i-mean-it` flag for destructive Proxmox operations

**Confidence:** HIGH -- standard bash pattern, consistent with project constraints.

### 6. Version Bump Automation

**Version locations in this repo:**
1. `marketplace.json` -- 13 occurrences (1 metadata + 12 plugins), all `"version": "0.1.0"`
2. `skills/*/SKILL.md` -- 12 files, each with `version: 0.1.0` in YAML frontmatter
3. `VERSION` file (new) -- single source of truth, plain text

**Script: `tools/bump-version.sh`**
```
Usage: bump-version.sh [major|minor|patch] [--dry-run] [--tag]

  Reads current version from VERSION file
  Bumps the specified segment (default: patch)
  Updates: VERSION, marketplace.json (all 13), all SKILL.md frontmatter (12)
  --dry-run: prints what would change without modifying files
  --tag: creates annotated git tag v$NEW_VERSION
```

**Implementation approach:**
- Read current from `VERSION` file (single line, e.g., `0.1.0`)
- Parse with `IFS='.' read -r major minor patch`
- Increment requested segment, zero downstream segments
- Update `VERSION` file
- Update `marketplace.json` with `sed` (jq also available but sed is simpler for known patterns)
- Update SKILL.md files with `sed -i '' "s/version: $OLD/version: $NEW/"` (macOS-compatible)
- `--dry-run` prints files that would change + old/new version
- `--tag` creates `git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"`

**Why NOT semantic-release/standard-version/release-it:**
- Private single-developer repo with git-based distribution
- No npm publishing, no GitHub releases, no automated changelogs
- A 50-line bash script does exactly what's needed
- Consistent with project constraint: no Node.js dependencies for tooling

**Confidence:** HIGH -- straightforward implementation with well-understood tools.

## MVP Definition

### Launch With (v1.2)

Core milestone goal: "Skippy IS the framework -- no external dependencies on GSD, PAUL, or OMC at runtime."

- [ ] GSD pattern absorption -- 6-8 reference docs covering phased execution, state tracking, wave parallelism, checkpoints, verification, plan structure
- [ ] GSD command independence -- validate zero GSD runtime dependencies in all skippy commands
- [ ] Shared shell library (`tools/lib/common.sh`) -- DRY extraction from 6 tool scripts
- [ ] bats-core test suite -- ~30 tests covering all tool scripts
- [ ] `/skippy:review` audit swarm -- multi-agent review command with parallel specialist agents
- [ ] deploy-service config mechanism + validation + root guards
- [ ] Version bump script (`tools/bump-version.sh`)
- [ ] `.gitattributes` export-ignore
- [ ] CONTRIBUTING.md

### Add After Validation (v1.3+)

- [ ] Audit swarm persistent findings database -- track findings across reviews
- [ ] Per-file review caching -- skip unchanged files in subsequent reviews
- [ ] deploy-service dry-run mode -- show what would happen without executing
- [ ] Skill scaffolding (`tools/new-skill.sh`) -- deferred TOOL-01
- [ ] Collision detection in install.sh -- deferred TOOL-02

### Future Consideration (v2+)

- [ ] Full 68-skill migration (SCALE-01)
- [ ] Skill dependency auto-resolution (SCALE-02)
- [ ] Cross-machine sync (SCALE-03)
- [ ] Reference doc metadata fields (TOOL-03)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase Suggestion |
|---------|------------|---------------------|----------|------------------|
| Shared shell library | HIGH | MEDIUM | P1 | Early -- everything depends on it |
| GSD pattern absorption (ref docs) | HIGH | MEDIUM | P1 | Early -- defines standalone identity |
| bats-core test suite | HIGH | MEDIUM | P1 | After shared library extraction |
| `/skippy:review` audit swarm | HIGH | HIGH | P1 | After foundation is stable |
| Version bump mechanism | MEDIUM | LOW | P2 | Any time, quick win |
| deploy-service config + validation | MEDIUM | MEDIUM | P2 | After shared library |
| `.gitattributes` | LOW | LOW | P2 | Any time, 5-minute task |
| CONTRIBUTING.md | LOW | LOW | P2 | After tests exist to reference |
| GSD command independence | MEDIUM | LOW | P1 | Alongside pattern absorption |

**Priority key:**
- P1: Must have for v1.2 "Standalone Skippy" claim to be true
- P2: Should have, strengthens the release but not blocking

## Competitor/Upstream Feature Analysis

| Feature Area | GSD | PAUL | OMC | Skippy v1.2 Approach |
|-------------|-----|------|-----|---------------------|
| Phased execution | gsd-tools.cjs Node.js CLI, 2000+ lines | Single-agent sequential | JSON dispatch tables | Reference docs. No Node.js runtime. Agents follow markdown guidance |
| State tracking | STATE.md template + gsd-tools.cjs lifecycle | Checkpoint files | Session persistence hooks | Reference doc for STATE.md structure + lifecycle. Commands read/write directly |
| Verification | gsd-verifier agent + VERIFICATION.md + gap closure | UNIFY step (reconciliation) | UltraQA cycling (max 5 iterations) | Already synthesized in verification-loops.md. Add GSD must_haves/truths/artifacts patterns |
| Multi-agent review | Not built-in | Not supported (single-agent) | Code review skill with severity ratings | `/skippy:review` -- structured swarm, 3-5 specialists, shared findings, synthesis. Differentiator |
| Testing | No built-in framework | No testing | Jest for TypeScript hooks | bats-core for shell scripts. Matched to source language |
| Version management | VERSION file (plain number) | Not tracked | package.json | bump-version.sh updating all version locations in one command |
| Configuration | `.planning/config.json` via gsd-tools.cjs | None | JSON config files | Shell-sourceable `.conf` files. No JSON parsing dependency |

## Sources

### Verified (HIGH confidence)
- GSD source code: `~/.claude/get-shit-done/workflows/execute-phase.md`, `verify-work.md`, `plan-phase.md`
- GSD templates: `~/.claude/get-shit-done/templates/state.md`, `phase-prompt.md`
- GSD references: `~/.claude/get-shit-done/references/checkpoints.md`, `verification-patterns.md`
- Existing skippy-agentspace codebase: `tools/*.sh`, `skills/*/SKILL.md`, `CONVENTIONS.md`
- [bats-core official documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html)
- [bats-core GitHub repository](https://github.com/bats-core/bats-core)

### Cross-verified (MEDIUM confidence)
- [Claude Code Swarm Orchestration patterns](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [metaswarm multi-agent framework](https://github.com/dsifry/metaswarm)
- [gruntwork-io/bash-commons](https://github.com/gruntwork-io/bash-commons) -- bash library patterns
- [Modular Bash Library Patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/)
- [Automate Git Tag Versioning Using Bash](https://reemus.dev/tldr/git-tag-versioning-script)
- [HackerOne bats-core practical guide](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide)

### WebSearch-only (LOW confidence -- patterns verified but specific claims not cross-checked)
- [Claude Code multi-agent guide](https://help.apiyi.com/en/claude-code-swarm-mode-multi-agent-guide-en.html)
- [shdotenv -- POSIX dotenv tool](https://github.com/ko1nksm/shdotenv)

---
*Feature research for: skippy-agentspace v1.2 Standalone Skippy*
*Researched: 2026-03-08*
