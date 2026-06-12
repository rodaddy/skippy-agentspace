# Pitfalls Research

**Domain:** Framework absorption, multi-agent swarm commands, shell test suites, shared function libraries
**Researched:** 2026-03-08
**Confidence:** HIGH (all four domains researched with real incident data + official docs + codebase analysis)

## Critical Pitfalls

### Pitfall 1: Multi-Agent Swarm Runs Destructive Commands Against Real HOME

**What goes wrong:**
A multi-agent audit swarm -- specifically a "red team" or adversarial agent role -- executes destructive commands (like `uninstall.sh --all`) against the user's real `$HOME` instead of a sandboxed environment. This already happened in a prior session: a red team agent ran `uninstall --all` against real HOME, nuking 71 installed skills.

**Why it happens:**
Claude Code subagents inherit the parent's environment, including `$HOME`, `$PATH`, and filesystem access. There is no built-in per-agent sandboxing in Claude Code's Task system. The `--dangerously-skip-permissions` flag, if used for automation, gives all subagents full unsupervised access with no override mechanism. Even without that flag, agents spawned via Task inherit permission grants. When the swarm design includes adversarial roles (red team, chaos agent), those agents are explicitly instructed to find and exploit weaknesses -- and the filesystem is the weakest target.

**How to avoid:**
1. Override `HOME` to a temporary directory before spawning any swarm agent: `export HOME=$(mktemp -d)` in the swarm orchestrator
2. Pre-populate the fake HOME with the minimum structure needed (`.claude/skills/`, `.claude/settings.json`) by copying from real HOME
3. Never give swarm agents write access to real `$HOME` -- the orchestrator operates on the copy, then reports findings
4. Validate agent commands against an allowlist before execution -- block `rm -rf`, `unlink`, `uninstall --all` patterns
5. Use `--dry-run` flags on all destructive operations within the swarm
6. The swarm command prompt MUST include explicit `DO NOT MODIFY` boundaries for real filesystem paths

**Warning signs:**
- Swarm agent prompts include paths containing the user's real home directory
- Agent roles named "red team" or "adversarial" have shell access without sandboxing
- No `HOME` override in the swarm orchestrator setup
- Test runs that modify `~/.claude/skills/` or `~/.claude/settings.json`

**Phase to address:**
The `/skippy:review` audit swarm command phase. Sandboxing must be designed BEFORE any agent spawning logic. This is a phase 1 concern -- get the sandbox right first, then build agent roles on top.

---

### Pitfall 2: GSD Pattern Absorption Loses Execution Fidelity

**What goes wrong:**
When absorbing GSD patterns (phased execution, wave-based parallelism, state tracking, checkpoints, verification loops), the absorbed version loses critical behavioral details that made GSD work. The result is a framework that looks like GSD but produces inferior execution quality -- plans execute but verification is shallow, state tracking drifts, checkpoint handling is incomplete, or wave parallelism doesn't actually parallelize.

**Why it happens:**
GSD's execute-phase.md alone is 460 lines of precise orchestration logic. execute-plan.md is another 450 lines. These workflows encode dozens of edge cases: the `classifyHandoffIfNeeded` bug workaround, the auto-advance chain flag vs user preference distinction, decimal phase handling for gap closure, segment execution patterns (A/B/C routing), and 4-rule deviation classification. Absorption typically starts as "copy the key ideas" and accidentally omits 30-40% of edge case handling that separates a working framework from a demo.

The GSD dependency map (already documented in `skills/skippy/references/gsd-dependency-map.md`) identifies 4 HIGH-risk integration points and 2 MEDIUM-risk ones. Absorbing these patterns means taking ownership of maintaining all of them.

**How to avoid:**
1. Absorb by reference, not by rewrite. Start with markdown reference docs that document the patterns, not reimplemented shell scripts
2. Map every GSD workflow step to a skippy equivalent before writing code. If a step has no equivalent, explicitly decide: absorb or drop
3. Create a fidelity matrix: for each GSD pattern, list what behaviors it produces, then verify the skippy version produces identical behaviors
4. Keep the GSD upstream tracking working during absorption -- if GSD improves a pattern you absorbed, you need to know
5. Absorb incrementally: phased execution first (highest value), then state tracking, then checkpoints, then wave parallelism. Each one is usable independently

**Warning signs:**
- Absorbed patterns are described as "simplified versions" without documenting what was dropped
- No test coverage for absorbed workflow logic
- State tracking drifts after 3+ phases (progress percentages don't match reality)
- Checkpoint handling works for happy path but fails when agents return structured state

**Phase to address:**
GSD pattern absorption phase. Must come AFTER the test suite exists, so absorption can be verified against behavioral tests.

---

### Pitfall 3: Shell Test Suite Modifies Real Filesystem

**What goes wrong:**
bats-core tests for install.sh, uninstall.sh, and hook management scripts read from or write to the user's real `~/.claude/` directory, `~/.claude/settings.json`, or `~/.claude/skills/`. Tests pass on the developer's machine (where skills are installed) and fail in CI (clean environment), or worse -- tests silently modify the developer's real installation.

**Why it happens:**
The scripts under test are designed to operate on `$HOME`. install.sh creates symlinks in `~/.claude/skills/`. uninstall.sh removes them. install-hooks.sh modifies `~/.claude/settings.json`. Without explicit `HOME` isolation in test setup, every test invocation touches real files. Bash has no import sandboxing -- when you `source install.sh` or run it, it executes in the current environment.

bats-core provides `$BATS_TEST_TMPDIR` (per-test) and `$BATS_FILE_TMPDIR` (per-file) that are automatically cleaned up. But the developer must explicitly override `HOME` to use them -- bats does not do this automatically.

**How to avoid:**
1. Every test file MUST start with `setup()` that overrides HOME:
   ```bash
   setup() {
       export ORIGINAL_HOME="$HOME"
       export HOME="$BATS_TEST_TMPDIR"
       mkdir -p "$HOME/.claude/skills"
       mkdir -p "$HOME/.claude/commands"
   }
   ```
2. Pre-populate the fake HOME with necessary fixtures (skeleton `settings.json`, dummy skill directories)
3. Never reference hardcoded paths like `/Users/rico/` in test files
4. Add a CI safeguard: the test runner script should refuse to run if `$HOME` points to a real home directory (check for `.bashrc` or `.zshrc` existence)
5. Use `$BATS_TEST_TMPDIR` for per-test isolation, `$BATS_FILE_TMPDIR` for shared fixtures within a test file
6. Test both the "modern" (`~/.claude/skills/`) and "legacy" (`~/.claude/commands/`) install targets -- the install.sh already handles both

**Warning signs:**
- Tests that `source` scripts outside of `setup()` -- bats documentation warns this can trip up the framework
- No `HOME` override visible in `setup()` function
- Tests that pass locally but fail in CI (or vice versa)
- `git diff` after running tests shows changes to `~/.claude/settings.json`

**Phase to address:**
The bats-core test suite phase. This is a DAY ONE concern -- the test harness must establish HOME isolation before any test is written. Retrofitting isolation onto existing tests is much harder.

---

### Pitfall 4: Shared Library Breaks Standalone Script Execution

**What goes wrong:**
After extracting common functions into `tools/lib/common.sh`, individual scripts (install.sh, uninstall.sh, verify.sh) fail when run from unexpected locations, when the lib directory doesn't exist, or when `common.sh` has a syntax error that prevents sourcing. Scripts that previously worked standalone now have a hard dependency on the library being present.

**Why it happens:**
Bash `source` fails hard. If `source tools/lib/common.sh` can't find the file, the script exits (under `set -e`). Path resolution is fragile -- `$(dirname "$0")` breaks when scripts are called via symlink (which is how skills are installed). The repo's constraint says "No cross-skill imports. Each skill is a standalone directory" but `tools/lib/common.sh` creates exactly that kind of cross-script dependency.

Currently, 4 scripts independently define `REPO_ROOT` using the same pattern:
```bash
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
```
And 3 scripts independently define `SKILLS_DIR="$REPO_ROOT/skills"`. This is the duplication that motivates DRY extraction, but the cure can be worse than the disease.

**How to avoid:**
1. Use `BASH_SOURCE[0]` instead of `$0` for path resolution -- `$0` breaks when sourced, `BASH_SOURCE[0]` always points to the current file
2. Resolve symlinks before calculating paths: `SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"` -- this handles the symlink install case
3. Source with a guard: check file existence before sourcing, with a clear error message
   ```bash
   LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd 2>/dev/null)" || { echo "ERROR: Cannot find lib/"; exit 1; }
   source "$LIB_DIR/common.sh" || { echo "ERROR: Failed to load common.sh"; exit 1; }
   ```
4. Use bash include guards to prevent double-sourcing:
   ```bash
   [ -n "$_COMMON_SH_LOADED" ] && return || readonly _COMMON_SH_LOADED=1
   ```
5. Keep the library minimal -- only extract truly shared code (REPO_ROOT resolution, SKILLS_DIR, output formatting). Don't extract functions used by only one script
6. Every script must remain runnable without the library for basic `--help` output -- degrade gracefully

**Warning signs:**
- `common.sh` has more than 100 lines (it's growing beyond "common utilities" into framework logic)
- Scripts fail with "No such file or directory" when run from a different working directory
- A syntax error in `common.sh` breaks ALL scripts simultaneously (single point of failure)
- `readlink -f` used on macOS without checking for GNU coreutils (macOS `readlink` doesn't support `-f` natively -- use `readlink` without `-f` or check for `greadlink`)

**Phase to address:**
The DRY extraction phase. Extract minimally, test the extraction itself (can each script still run standalone from any directory?), and verify symlink-based invocation still works.

---

### Pitfall 5: Absorbed Framework Creates GSD Lock-In Through gsd-tools.cjs Dependency

**What goes wrong:**
GSD's execution workflows rely heavily on `gsd-tools.cjs` -- a Node.js CLI that handles init, state management, roadmap updates, config, commit formatting, and phase indexing. Absorbing GSD's patterns without absorbing this tool creates a runtime dependency on GSD being installed. But absorbing the tool means maintaining a 2000+ line Node.js file, violating the project's "shell scripts + markdown only" constraint.

**Why it happens:**
GSD's workflows call `gsd-tools.cjs` at least 15 times during a single phase execution: `init`, `phase-plan-index`, `config-get`, `config-set`, `state advance-plan`, `state update-progress`, `state record-metric`, `state add-decision`, `state record-session`, `roadmap update-plan-progress`, `phase complete`, `commit`, `requirements mark-complete`, `find-phase`. These aren't convenience wrappers -- they encode complex JSON manipulation, YAML parsing, and file update logic that would be extremely painful to replicate in bash.

**How to avoid:**
1. Don't absorb gsd-tools.cjs at all. Instead, absorb the PATTERNS (phased execution, state tracking, verification) as markdown reference docs that Claude agents follow
2. Let agents handle the file manipulation directly (they're better at YAML/JSON editing than bash scripts)
3. If executable tooling is needed, write minimal bash utilities for the 3-4 most common operations (init, progress update, commit) -- not the full 15+ command surface
4. Document which GSD CLI calls are "pattern" (agents can replicate the behavior) vs "infrastructure" (requires tooling)
5. Accept that some GSD patterns are too tool-dependent to absorb cleanly -- mark them as "requires GSD" rather than half-absorbing

**Warning signs:**
- Plans reference `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs"` in absorbed workflow docs
- TypeScript/Node.js dependencies creeping into a "shell scripts + markdown only" project
- Absorbed workflows that silently fail when GSD isn't installed
- Shell scripts attempting complex YAML parsing (fragile regex, sed hacks)

**Phase to address:**
GSD pattern absorption phase. Must decide the absorption boundary BEFORE implementation: which patterns become reference docs (agent-executed) vs which become shell tooling.

---

### Pitfall 6: Multi-Agent Swarm Model Availability Assumptions

**What goes wrong:**
The `/skippy:review` audit swarm design assumes multiple agent roles (reviewer, fixer, evaluator) can run in parallel using specific models. But model availability varies: API rate limits, model deprecation, tier access restrictions, and cost spikes from parallel execution can silently degrade or block the swarm.

**Why it happens:**
GSD's model routing already handles this (executor_model, verifier_model from config), but a swarm with 3-5 simultaneous agents multiplies the problem. If the swarm is designed to use Opus for the evaluator role and the user hits rate limits, the swarm stalls. If it falls back to a weaker model, evaluation quality drops. The swarm orchestrator doesn't know about these constraints because Claude Code's Task system doesn't expose model availability pre-flight.

**How to avoid:**
1. Design the swarm for sequential execution as the default, with parallel as an optimization. The swarm must work serially even if it's slower
2. Don't hardcode model names -- use role-based model selection (reviewer_model, fixer_model) that reads from config, with sensible defaults
3. Implement timeout handling: if a swarm agent doesn't respond within N minutes, report partial results rather than hanging
4. Log token usage per agent role so cost visibility is clear
5. The swarm command should accept a `--dry-run` flag that shows what agents would be spawned without actually spawning them

**Warning signs:**
- Swarm tests pass with Opus but fail with Sonnet (model capability assumption)
- No timeout handling -- swarm hangs when an agent stalls
- Parallel agent spawning without rate limit awareness
- No cost estimation before swarm execution

**Phase to address:**
The `/skippy:review` command phase. Model routing should be configurable from the start, with sequential execution as the safe default.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Copy-paste GSD workflow text as reference docs | Fast absorption, keeps working immediately | Stale copies diverge from GSD upstream over time | Acceptable for v1.2 if `/skippy:update` continues tracking GSD upstream |
| Hardcode model names in swarm prompts | Quick to implement | Breaks when models are deprecated or renamed | Never -- always use config-driven model selection |
| Skip HOME isolation in early tests | Tests pass faster locally | Tests eventually modify real HOME; CI failures | Never -- establish isolation in first test file |
| Single `common.sh` for all shared code | Fast DRY extraction | Single point of failure, grows into god-file | Acceptable if capped at ~50 lines and reviewed quarterly |
| Test only happy paths for install/uninstall | Quick coverage metric | Misses edge cases (dangling symlinks, permission errors, missing directories) | Only for initial test suite -- expand in subsequent phase |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| GSD upstream tracking during absorption | Stop tracking GSD after absorbing its patterns ("we don't need it anymore") | Continue tracking -- GSD will improve patterns you absorbed, and you need to know about breaking changes |
| bats-core helper libraries | Loading `bats-support` and `bats-assert` from global install | Vendor helpers as git submodules under `test/test_helper/` for reproducible CI |
| Claude Code Task system for swarm | Assuming Task agents can interact with each other | Each Task agent is isolated -- use files or the orchestrator as the communication bus |
| settings.json hook merging during tests | Testing hook install against real settings.json | Use a fixture settings.json in `$BATS_TEST_TMPDIR` -- never touch the real one |
| macOS vs Linux path resolution | Using `readlink -f` (GNU-only) | Use `cd "$(dirname ...)" && pwd` pattern or check for `greadlink` |
| `set -euo pipefail` in sourced libraries | Library function returns non-zero, kills the sourcing script | Use `|| true` for expected non-zero returns, or `set +e` around specific calls |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Swarm agents with unrestricted shell access | Agent executes `rm -rf $HOME`, deletes user data (this happened) | Override HOME, use allowlisted commands, block destructive patterns |
| Swarm agents reading `~/.claude/settings.json` or MCP configs | Agents could extract API keys, MCP server URLs, credential paths | Sanitize or omit sensitive config from the sandbox environment |
| Test scripts that `eval` user input | Command injection via test fixture filenames or env vars | Never `eval` -- use arrays for command construction |
| Absorbed workflow docs containing hardcoded local paths | Paths like `/Users/rico/` or `/Volumes/ThunderBolt/` leak into reference docs | Grep for hardcoded paths as a CI check (already done for IP addresses in v1.1) |

## "Looks Done But Isn't" Checklist

- [ ] **GSD absorption:** All 15 `gsd-tools.cjs` call sites accounted for (replaced, wrapped, or documented as requiring GSD) -- verify no silent failures when GSD is absent
- [ ] **Test suite HOME isolation:** Every `.bats` file has `setup()` that overrides HOME -- grep for `export HOME` in each test file
- [ ] **Swarm sandbox:** Swarm orchestrator creates temp HOME before ANY agent spawn -- verify with a test that checks `$HOME` inside a spawned agent
- [ ] **common.sh portability:** Run each script that sources common.sh from 3 locations: repo root, tools/ directory, and via symlink from `~/.claude/skills/` -- verify all 3 work
- [ ] **Swarm dry-run:** `/skippy:review --dry-run` shows agent plan without executing -- verify it doesn't spawn any Tasks
- [ ] **macOS readlink:** No `readlink -f` calls in any bash script -- grep and verify
- [ ] **Absorbed patterns completeness:** Each absorbed GSD pattern has a behavioral test (not just "file exists" but "produces correct state transitions")
- [ ] **uninstall.sh safety:** `uninstall.sh --all` only removes symlinks pointing INTO this repo -- verify it doesn't touch other projects' symlinks (already implemented but must be tested)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Swarm nukes real HOME skills | MEDIUM | Re-run `install.sh --all` from the repo. If settings.json corrupted, restore from timestamped backup (install-hooks.sh creates these). If custom skills lost, restore from `~/.config/pai/Skills/` source. |
| Absorbed GSD pattern diverges from upstream | LOW | Run `/skippy:update` to detect GSD changes, diff against absorbed reference docs, update manually. No code rewrite needed if patterns are reference docs. |
| Test suite modifies real HOME | LOW-MEDIUM | Check `git status` in `~/.claude/`. Restore settings.json from backup. Re-run `install.sh` for skills. If hooks corrupted, run `install-hooks.sh`. |
| common.sh breaks all scripts | LOW | Delete `source common.sh` line from affected script, inline the 2-3 functions it used. Scripts are designed to be standalone -- the shared code is convenience, not necessity. |
| Model unavailable during swarm | LOW | Re-run swarm after rate limit resets. If model deprecated, update config to use new model name. Sequential fallback means partial results are still useful. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Swarm nukes real HOME | `/skippy:review` swarm phase (sandbox design) | Test: spawned agent's `$HOME` is a temp directory, not real HOME |
| GSD absorption loses fidelity | GSD absorption phase | Fidelity matrix: each absorbed pattern has behavioral test matching GSD output |
| Test suite modifies real HOME | bats-core test suite phase (first thing built) | CI check: test runner refuses to run if HOME contains `.zshrc` |
| Shared library breaks standalone | DRY extraction phase | Test: each script runs successfully from repo root, tools/, and via symlink |
| gsd-tools.cjs lock-in | GSD absorption phase (design decision) | Grep for `gsd-tools.cjs` in all absorbed docs -- zero references |
| Model availability assumptions | `/skippy:review` swarm phase | Test: swarm completes in sequential mode without model-specific logic |
| Hardcoded paths in absorbed docs | GSD absorption phase | CI grep for `/Users/`, `/Volumes/`, `/home/` in reference docs |

## Sources

- [bats-core official documentation -- writing tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- temp directory scoping, setup/teardown lifecycle
- [bats-core GitHub -- cleanup temp files issue](https://github.com/bats-core/bats-core/issues/226) -- BATS_TEST_TMPDIR isolation patterns
- [Bash include guard pattern](https://coderwall.com/p/it3b-q/bash-include-guard) -- preventing double-sourcing
- [BashPitfalls -- Greg's Wiki](https://mywiki.wooledge.org/BashPitfalls) -- canonical bash scripting mistakes
- [Baeldung -- include files in bash](https://www.baeldung.com/linux/source-include-files) -- sourcing patterns, BASH_SOURCE vs $0
- [OWASP 2026 -- Managing Agentic Blast Radius](https://medium.com/@parmindersk/managing-the-agentic-blast-radius-in-multi-agent-systems-owasp-2026-7f2a84337d8d) -- multi-agent trust and containment
- [Edera -- Production AI Agent Sandboxing](https://edera.dev/stories/what-ai-agent-sandboxing-means-for-production-infrastructure) -- infrastructure-level isolation
- [Claude Code Sandboxing docs](https://code.claude.com/docs/en/sandboxing) -- official sandbox architecture
- [Anthropic engineering -- Claude Code sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing) -- filesystem + network isolation design
- [Claude Code sandbox security analysis](https://smartscope.blog/en/generative-ai/claude/claude-code-sandbox-security-2025/) -- subagent inheritance, permission bypass risks
- [Check Point Research -- CVE-2025-59536](https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/) -- hook-based RCE vectors
- Codebase analysis: `tools/install.sh`, `tools/uninstall.sh`, `tools/verify.sh`, `skills/core/hooks/install-hooks.sh` -- duplicated patterns identified
- Codebase analysis: `skills/skippy/references/gsd-dependency-map.md` -- 4 HIGH, 2 MEDIUM risk GSD dependencies
- GSD workflow analysis: `execute-phase.md` (460 lines), `execute-plan.md` (450 lines), `checkpoints.md` (777 lines) -- complexity of patterns being absorbed
- Real incident: prior session where red team agent ran `uninstall --all` against real HOME, removing 71 installed skills

---
*Pitfalls research for: v1.2 Standalone Skippy -- framework absorption, multi-agent swarm, shell testing, shared libraries*
*Researched: 2026-03-08*
