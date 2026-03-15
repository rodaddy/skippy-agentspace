# Project Research Summary

**Project:** skippy-agentspace v1.2 -- Standalone Skippy
**Domain:** Portable Claude Code skill framework -- standalone execution, multi-agent audit, automated testing, infrastructure hardening
**Researched:** 2026-03-08
**Confidence:** HIGH

## Executive Summary

Skippy-agentspace v1.2 transforms from a "parasitic skill" riding GSD into a standalone framework. The core challenge is absorbing GSD's execution patterns (phased execution, wave parallelism, state tracking, checkpoints) without absorbing its tooling (gsd-tools.cjs, 2000+ lines of Node.js). Research unanimously recommends absorbing patterns as markdown reference docs -- not code -- because skippy's commands are AI-driven: the agent IS the runtime. This sidesteps the entire "reimplement gsd-tools.cjs in bash" trap that would violate the project's no-build-step, shell-scripts-plus-markdown constraint. Five to six new reference docs under `skills/skippy/references/` complete the absorption, following the same pattern successfully used for 10 existing PAUL/OMC cherry-picks.

The headline feature is `/skippy:review`, a multi-agent audit swarm that spawns 3 specialist agents (reviewer, fixer, evaluator) to provide structured code review. This is well-supported by Claude Code's native Task() subagent system -- no experimental features needed. The critical risk here is real: a prior session had a red team agent run `uninstall --all` against real `$HOME`, nuking 71 installed skills. Every agent-spawning feature MUST override `$HOME` to a temp directory before any agent touches the filesystem.

The remaining v1.2 work is infrastructure hardening: extract a shared shell library from 6 duplicated tool scripts, add bats-core automated tests (the project currently has zero), create a deploy-service config mechanism to replace hardcoded placeholders, and add version bump automation across 25 version string locations. All of these are well-understood patterns with high-confidence research. The dependency chain is clear: shared library first (everything depends on it), tests next (safety net for refactoring), then features can parallelize.

## Key Findings

### Recommended Stack

The existing stack is locked (bash, markdown, symlinks, bun for hooks). v1.2 adds six capabilities within the existing constraint of no new runtime dependencies beyond git, bash 4+, bun, and jq.

**Core technologies:**
- **Markdown reference docs** for GSD pattern absorption -- distill 11,452 lines of GSD workflows into 5-6 skippy-native references. No code porting. Agents load on demand.
- **Claude Code Task() subagents** for `/skippy:review` -- native, production-ready subagent system. Explicitly NOT Agent Teams (experimental, adds coordination overhead for independent review agents).
- **bats-core 1.13.0** via brew for shell testing -- the community standard for bash. Helpers (bats-assert, bats-support, bats-file) via git submodules for portable `load` paths.
- **Single `tools/lib/common.sh`** for DRY extraction -- ~80-100 lines, `skippy_` namespaced functions, sourced by all 6 tool scripts with graceful fallback.
- **Shell-sourceable `deploy.conf`** for deploy-service config -- bash `source` with validation, zero parser dependencies. Gitignored for real values.
- **Plain `VERSION` file + `tools/bump-version.sh`** for version management -- inline semver bump, atomic update across 25 locations (13 in marketplace.json, 12 in SKILL.md files).

**Critical version requirements:** Bash 4.0+ (macOS ships 3.2), bats-core 1.13.0, Bun 1.0+, Git 2.20+.

See [STACK.md](STACK.md) for full rationale, alternatives considered, and stack patterns by capability.

### Expected Features

**Must have (table stakes -- required for "standalone" claim):**
- GSD pattern absorption as reference docs (phased execution, wave parallelism, state tracking, checkpoints, plan structure)
- GSD command independence validation (zero runtime dependency on gsd-tools.cjs)
- Shared shell library (DRY extraction from 1507 lines across 6 scripts)
- bats-core test suite (~30 tests, ~260+ lines -- currently zero automated tests)
- Version bump mechanism (25 locations across 13 files)

**Should have (differentiators):**
- `/skippy:review` multi-agent audit swarm (headline feature, 3-agent reviewer/fixer/evaluator pipeline)
- deploy-service config mechanism + input validation + root guards
- `.gitattributes` export-ignore
- CONTRIBUTING.md

**Defer (v1.3+):**
- Persistent findings database for audit swarm
- Per-file review caching
- deploy-service dry-run mode
- Skill scaffolding (`tools/new-skill.sh`)
- Full 68-skill migration
- Cross-machine sync

See [FEATURES.md](FEATURES.md) for dependency graph, MVP definition, and competitor analysis.

### Architecture Approach

v1.2 is additive -- new features integrate into the existing skill structure without reorganization. New reference docs go in `skills/skippy/references/`, the review command goes in `skills/skippy/commands/`, the shared library goes in `tools/lib/`, and tests go in `tests/` at repo root. The key architectural insight is that `tools/` scripts source `common.sh` but `skills/*/scripts/` do NOT -- skill scripts remain standalone per the portability constraint.

**Major components:**
1. **Reference docs (5-6 new)** -- absorbed GSD patterns as standalone markdown, loaded by agents on demand
2. **`/skippy:review` command** -- orchestrates 3 sequential agents (reviewer -> fixer -> evaluator) with structured output
3. **`tools/lib/common.sh`** -- shared functions for repo root resolution, pass/fail/warn reporting, skill queries
4. **`tests/` suite** -- bats-core tests with HOME isolation for all tool scripts
5. **`tools/bump-version.sh`** -- atomic version propagation across marketplace.json + 12 SKILL.md files
6. **`deploy.conf` mechanism** -- shell-sourceable config replacing 9 hardcoded placeholders in deploy-service

See [ARCHITECTURE.md](ARCHITECTURE.md) for full file tree, data flow diagram, build order, and anti-patterns.

### Critical Pitfalls

1. **Swarm agents destroy real HOME** -- A prior session had a red team agent run `uninstall --all` against real `$HOME`, nuking 71 skills. Prevention: override `HOME` to temp directory before ANY agent spawn, block destructive command patterns, include explicit `DO NOT MODIFY` boundaries in agent prompts.

2. **GSD absorption loses execution fidelity** -- GSD's execute-phase.md alone is 460 lines with dozens of edge cases (decimal phase handling, segment routing, deviation classification). Prevention: absorb by reference not rewrite, create a fidelity matrix mapping GSD behaviors to skippy equivalents, keep GSD upstream tracking active.

3. **Test suite modifies real filesystem** -- bats tests for install/uninstall/hooks that touch real `~/.claude/` instead of isolated temp dirs. Prevention: every test file's `setup()` MUST override `HOME` to `$BATS_TEST_TMPDIR`, CI safeguard refuses to run if HOME contains `.zshrc`.

4. **Shared library breaks standalone execution** -- Scripts fail when `source tools/lib/common.sh` can't find the file. Prevention: use `BASH_SOURCE[0]` not `$0` for path resolution, source with existence guard and graceful fallback, include guards to prevent double-sourcing.

5. **gsd-tools.cjs lock-in through absorbed patterns** -- GSD workflows call gsd-tools.cjs 15+ times per phase execution. Prevention: absorb PATTERNS as markdown, NOT tooling. Agents handle file manipulation directly. Grep all absorbed docs for zero `gsd-tools.cjs` references.

6. **Model availability breaks swarm** -- Rate limits or model deprecation stalls multi-agent execution. Prevention: design for sequential execution as default, role-based model selection from config, timeout handling for stalled agents.

See [PITFALLS.md](PITFALLS.md) for full analysis, recovery strategies, technical debt patterns, and "looks done but isn't" checklist.

## Implications for Roadmap

Based on research, suggested phase structure (6 phases):

### Phase 1: Foundation -- Shared Library + Test Infrastructure

**Rationale:** Everything depends on this. The shared library enables DRY refactoring of 6 tool scripts, and bats tests provide the safety net for that refactoring. Without tests, the DRY extraction and all subsequent changes are reckless. Architecture research confirms common.sh has NO dependencies on other new features.
**Delivers:** `tools/lib/common.sh` (~80-100 lines), refactored tool scripts sourcing it, `tests/` directory with bats infrastructure, ~30 test cases covering all tool scripts.
**Addresses:** Shared shell library (table stakes), bats-core test suite (table stakes).
**Avoids:** Pitfall 3 (test suite modifies real filesystem -- establish HOME isolation from day one), Pitfall 4 (shared library breaks standalone -- test the extraction itself).

### Phase 2: GSD Pattern Absorption

**Rationale:** Defines skippy's standalone identity. The reference docs make the "skippy IS the framework" claim true. Can run in PARALLEL with Phase 1 (pure markdown, no code dependencies). Architecture research confirms these are independent.
**Delivers:** 5-6 new reference docs (phased-execution.md, wave-parallelism.md, state-tracking.md, checkpoints.md, plan-structure.md), updated gsd-dependency-map.md, validated command independence.
**Addresses:** GSD pattern absorption (table stakes), GSD command independence (table stakes).
**Avoids:** Pitfall 2 (absorption loses fidelity -- use fidelity matrix), Pitfall 5 (gsd-tools.cjs lock-in -- absorb patterns not tooling).

### Phase 3: `/skippy:review` Audit Swarm

**Rationale:** Headline feature of v1.2. Benefits from stable foundation (Phase 1) and absorbed patterns (Phase 2 -- verification loops inform the swarm's cycling). Can run in parallel with Phase 2 since it depends on existing v1.1 references, not the new ones.
**Delivers:** `skills/skippy/commands/review.md` (~120 lines), 3-agent pipeline (reviewer/fixer/evaluator), structured findings output.
**Addresses:** `/skippy:review` audit swarm (differentiator).
**Avoids:** Pitfall 1 (swarm destroys real HOME -- sandbox design BEFORE agent logic), Pitfall 6 (model availability -- sequential default, configurable models).

### Phase 4: deploy-service Hardening

**Rationale:** Independent feature that replaces 9 hardcoded placeholders with a config mechanism. No dependencies on other phases. Can run in parallel with Phases 2-3.
**Delivers:** `deploy.conf.example` template, config loading with validation, input validation functions, root guards, updated deploy-workflow.md and find-next-ip.sh.
**Addresses:** deploy-service config mechanism (differentiator), input validation + root guards (differentiator).
**Avoids:** No critical pitfalls specific to this phase (standard bash patterns).

### Phase 5: Version Management

**Rationale:** Should come after Phase 1 (sources common.sh, includes bump-version.bats). Quick win -- ~120 line script with well-defined behavior.
**Delivers:** `VERSION` file, `tools/bump-version.sh` with --dry-run and --tag support, atomic update across 25 version locations.
**Addresses:** Version bump mechanism (table stakes).
**Avoids:** Anti-pattern of single VERSION file as dynamic source (marketplace.json is canonical, bump script propagates atomically).

### Phase 6: Integration + Documentation

**Rationale:** Depends on ALL above. Final integration, docs, verification.
**Delivers:** CONTRIBUTING.md, `.gitattributes` export-ignore, updated CLAUDE.md ("Skippy IS the framework"), final `verify.sh` run, INDEX.md regeneration.
**Addresses:** .gitattributes (should have), CONTRIBUTING.md (should have).
**Avoids:** No specific pitfalls -- this is polish.

### Phase Ordering Rationale

- **Phase 1 is foundational** -- all research files agree that shared library + tests must come first. Architecture research shows common.sh has zero dependencies on other features. Pitfalls research warns that refactoring without tests is reckless.
- **Phases 1-4 can parallelize** -- architecture research explicitly maps the dependency graph and confirms Phases 1-4 are independent. Only Phase 5 depends on Phase 1, and Phase 6 depends on all.
- **Review swarm is Phase 3, not Phase 1** -- despite being the headline feature, the swarm has the highest complexity and the most dangerous pitfall (real HOME destruction). Building it on top of tested infrastructure reduces risk.
- **Version management is late** -- it's low-risk, low-complexity, and depends on common.sh. Slot it as a quick win after the foundation stabilizes.

### Suggested Wave Structure

```
Wave 1: [Phase 1] [Phase 2] [Phase 3] [Phase 4]   (all parallelizable)
Wave 2: [Phase 5]                                   (needs Phase 1)
Wave 3: [Phase 6]                                   (needs all)
```

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (GSD Pattern Absorption):** 11,452 lines of GSD workflows to distill. Absorption boundary decisions (what to include, what to drop, what to mark "requires GSD") need careful analysis. The fidelity matrix is non-trivial.
- **Phase 3 (`/skippy:review` Swarm):** Real incident history demands careful sandbox design. The 3-agent sequential pipeline (reviewer -> fixer -> evaluator) needs prompt engineering and structured output format definition.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** bats-core is well-documented, DRY extraction is straightforward bash.
- **Phase 4 (deploy-service):** Shell-sourceable config is a standard pattern.
- **Phase 5 (Version Management):** Simple find-and-replace script.
- **Phase 6 (Integration):** Documentation and final verification.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies verified against official docs and direct codebase inspection. No speculative choices -- everything extends existing prereqs. |
| Features | HIGH | Feature list derived from direct codebase analysis (grep for duplication, placeholder audit, version string count). Dependency graph verified. |
| Architecture | HIGH | Based on direct inspection of all 6 tools/ scripts, all 12 skill directories, GSD source at ~/.claude/get-shit-done/. Integration points mapped file-by-file. |
| Pitfalls | HIGH | Includes a real incident (71 skills nuked by unsandboxed agent). All pitfalls cite specific code locations or documented behaviors. Recovery strategies provided. |

**Overall confidence:** HIGH

### Gaps to Address

- **macOS `readlink -f` incompatibility:** Research flags this but doesn't confirm whether existing scripts use it. Grep all bash scripts during Phase 1 planning to verify.
- **Swarm agent prompt engineering:** The 3-agent pipeline is architecturally sound but actual agent prompts (what the reviewer looks for, how the evaluator grades) need definition during Phase 3 planning.
- **GSD upstream drift detection:** Absorbed patterns will diverge from GSD over time. `/skippy:update` tracks upstream changes but doesn't auto-diff absorbed reference docs against their sources. This is a v1.3 concern.
- **CI runner selection:** Tests target macOS (BSD sed, no `readlink -f`). If CI is added, macOS runners are required but slower and more expensive. Consider whether CI is needed for a private solo-dev repo.
- **bats helper installation method:** STACK.md recommends git submodules for helpers, ARCHITECTURE.md shows brew paths (`/opt/homebrew/lib/`). Need to pick one approach during Phase 1 planning. Recommendation: git submodules (portable, reproducible).

## Sources

### Primary (HIGH confidence)
- GSD source code at `~/.claude/get-shit-done/` -- 34 workflows (11,452 lines), 13 references, 27 templates, VERSION 1.22.4
- Existing skippy-agentspace codebase -- 6 tools/ scripts (1507 lines), 12 skills, marketplace.json, all SKILL.md files
- deploy-service skill -- 9 unique placeholders across SKILL.md, deploy-workflow.md, find-next-ip.sh
- [bats-core official docs](https://bats-core.readthedocs.io/en/stable/) -- test lifecycle, helpers, temp directories
- [Claude Code official docs](https://code.claude.com/docs/) -- Task() system, sandboxing architecture

### Secondary (MEDIUM confidence)
- [Claude Code swarm orchestration patterns](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea) -- specialist subagent roles
- [metaswarm multi-agent framework](https://github.com/dsifry/metaswarm) -- 5-agent design review gate, 3-iteration cap
- [gruntwork-io/bash-commons](https://github.com/gruntwork-io/bash-commons) -- bash library best practices
- [OWASP 2026 -- Managing Agentic Blast Radius](https://medium.com/@parmindersk/managing-the-agentic-blast-radius-in-multi-agent-systems-owasp-2026-7f2a84337d8d) -- multi-agent containment
- [Anthropic engineering -- Claude Code sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing) -- filesystem + network isolation design

### Tertiary (LOW confidence -- needs validation)
- [Claude Code multi-agent guide](https://help.apiyi.com/en/claude-code-swarm-mode-multi-agent-guide-en.html) -- patterns verified but claims not cross-checked
- [shdotenv](https://github.com/ko1nksm/shdotenv) -- evaluated, rejected for this project

---
*Research completed: 2026-03-08*
*Ready for roadmap: yes*
