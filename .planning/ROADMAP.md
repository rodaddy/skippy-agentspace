# Roadmap: skippy-agentspace

## Milestones

- [x] **v1.0 Initial Release** - Phases 1-4 (shipped 2026-03-07)
- [x] **v1.1 Portable PAI** - Phases 5-10 (shipped 2026-03-08)
- [ ] **v1.2 Standalone Skippy** - Phases 11-16 (in progress)

## Phases

<details>
<summary>v1.0 Initial Release (Phases 1-4) - SHIPPED 2026-03-07</summary>

- [x] **Phase 1: Spec Compliance** - Align skill structure and paths to Agent Skills standard (completed 2026-03-07)
- [x] **Phase 2: Plugin Packaging** - Enable native `/plugin install` distribution (completed 2026-03-07)
- [x] **Phase 3: Command Validation** - Harden and validate all three skippy commands against real workflows (completed 2026-03-07)
- [x] **Phase 4: Documentation** - Cold session context and GSD dependency mapping (completed 2026-03-07)

</details>

<details>
<summary>v1.1 Portable PAI (Phases 5-10) - SHIPPED 2026-03-08</summary>

- [x] **Phase 5: Foundation** - Public/private content boundary and extensible upstream registry (completed 2026-03-07)
- [x] **Phase 6: Core Infrastructure** - Personas, LAWs, rules, and CLAUDE.md template packaged as portable core (completed 2026-03-07)
- [x] **Phase 7: Hook Installation** - Non-destructive settings.json hook merging with manifest-driven install/uninstall (completed 2026-03-07)
- [x] **Phase 8: Upstream Analysis** - OMC as third upstream, cross-package analysis, and generic upstream checker (completed 2026-03-08)
- [x] **Phase 9: Skill System** - Selective install flags, skill migration tool, and ~10 essential skills ported (completed 2026-03-08)
- [x] **Phase 10: Bootstrap & Docs** - Prerequisite validation, setup/install/upgrade docs, and post-install verification (completed 2026-03-08)

</details>

### v1.2 Standalone Skippy

- [x] **Phase 11: Foundation** - Shared shell library and repo hygiene (.gitattributes) (completed 2026-03-08)
- [ ] **Phase 12: Testing** - bats-core test suite with sandboxed HOME isolation
- [ ] **Phase 13: GSD Pattern Absorption** - Reference docs for standalone execution patterns
- [ ] **Phase 14: Audit Swarm** - `/skippy:review` multi-agent review command
- [ ] **Phase 15: Hardening** - deploy-service config mechanism and version management
- [ ] **Phase 16: Integration & Polish** - Final verification, doc consistency, CONTRIBUTING.md

## Phase Details

<details>
<summary>v1.0 Phase Details (Phases 1-4) - SHIPPED 2026-03-07</summary>

### Phase 1: Spec Compliance
**Goal**: Skill files are portable and conform to the Agent Skills open standard
**Depends on**: Nothing (first phase)
**Requirements**: SPEC-01, SPEC-02, SPEC-03, STRU-01
**Success Criteria** (what must be TRUE):
  1. No absolute paths exist in any skill file
  2. SKILL.md frontmatter passes Agent Skills spec validation
  3. `scripts/` directory exists where `bin/` was
  4. Skill follows progressive disclosure pattern
**Plans**: 1/1 complete

Plans:
- [x] 01-01: Fix paths, align frontmatter, rename bin/ to scripts/, verify structure

### Phase 2: Plugin Packaging
**Goal**: Users can install skippy-dev via `/plugin marketplace add` with a single command
**Depends on**: Phase 1
**Requirements**: SPEC-04, STRU-03
**Success Criteria** (what must be TRUE):
  1. `.claude-plugin/marketplace.json` exists with valid schema
  2. marketplace.json lists available skills with correct paths
  3. Install tooling detects target environment and symlinks correctly
  4. A clean clone can be installed via plugin system
**Plans**: 3/3 complete

Plans:
- [x] 02-01: Create marketplace.json
- [x] 02-02: Rewrite install.sh with dual-target support
- [x] 02-03: Rewrite uninstall.sh + update INDEX.md + CLAUDE.md

### Phase 3: Command Validation
**Goal**: All three skippy commands run correctly against real workflows
**Depends on**: Phase 2
**Requirements**: CMD-01, CMD-02, CMD-03
**Success Criteria** (what must be TRUE):
  1. `/skippy:reconcile` reads a real `.planning/` project and reports deviations
  2. `/skippy:update` clones upstream repos with persistent state
  3. `/skippy:cleanup` quarantine and nuke modes work correctly
  4. All scripts exit cleanly on missing inputs
**Plans**: 3/3 complete

Plans:
- [x] 03-01: Enhance reconcile.md for multi-plan phases
- [x] 03-02: Fix update script bugs
- [x] 03-03: Fix cleanup script TMPDIR quarantine bug

### Phase 4: Documentation
**Goal**: A new session opening this repo immediately understands what it is and how it works
**Depends on**: Phase 3
**Requirements**: DOC-01, STRU-02
**Success Criteria** (what must be TRUE):
  1. GSD dependency map exists with breakage risk annotations
  2. CLAUDE.md includes origin story, architecture, and cold-session context
**Plans**: 2/2 complete

Plans:
- [x] 04-01: GSD dependency map with breakage risk annotations
- [x] 04-02: Rewrite CLAUDE.md as cold-session brief

</details>

<details>
<summary>v1.1 Phase Details (Phases 5-10) - SHIPPED 2026-03-08</summary>

### Phase 5: Foundation
**Goal**: Architectural conventions are established so all subsequent phases build on a clean public/private boundary and an extensible upstream tracking system
**Depends on**: Phase 4 (v1.0 complete)
**Requirements**: FOUN-01, FOUN-02, FOUN-03, FOUN-04
**Success Criteria** (what must be TRUE):
  1. A documented convention distinguishes public content (safe to commit) from private content (never committed), and .gitignore enforces it
  2. Running `ls upstreams/` shows one directory per tracked upstream (gsd, paul), each containing an `upstream.json` with repo URL, branch, and last-checked SHA
  3. Adding a new upstream source requires only creating a new directory under `upstreams/` with the standard files -- no script or code changes needed
  4. Existing `.versions` tracking data is present in the new upstream format with no data loss
**Plans**: 2/2 complete

Plans:
- [x] 05-01-PLAN.md -- Public/private content boundary (CONVENTIONS.md, .gitignore, CLAUDE.md ref)
- [x] 05-02-PLAN.md -- Upstream registry (upstreams/gsd + paul, .versions removal)

### Phase 6: Core Infrastructure
**Goal**: The essential PAI operating layer -- personas, LAWs, rules, and project templates -- is packaged as a portable, installable core that follows the slim SKILL.md pattern
**Depends on**: Phase 5 (public/private boundary defined)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, CORE-06
**Note**: CORE-05 (command packaging) deferred per discuss-phase decision.
**Plans**: 3/3 complete

Plans:
- [x] 06-01-PLAN.md -- Personas and LAWs extraction (4 persona files + 15 LAW files)
- [x] 06-02-PLAN.md -- Rules and templates (4 rule files + 2 template files)
- [x] 06-03-PLAN.md -- SKILL.md entry point + INDEX.md/marketplace.json/CLAUDE.md integration

### Phase 7: Hook Installation
**Goal**: Users can install and uninstall PAI hooks into Claude Code's settings.json without destroying existing hook registrations from GSD, OMC, or other systems
**Depends on**: Phase 6 (hooks live in core/)
**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05
**Plans**: 3/3 complete

Plans:
- [x] 07-01-PLAN.md -- Manifest + shared lib (types, context, feedback utilities)
- [x] 07-02-PLAN.md -- 15 LAW hook scripts (10 ports + 5 new)
- [x] 07-03-PLAN.md -- Installer, uninstaller, INSTALL.md, SKILL.md update

### Phase 8: Upstream Analysis
**Goal**: OMC is tracked as a third upstream source, cross-package patterns are identified and cherry-picked, and `/skippy:update` works generically against any registered upstream
**Depends on**: Phase 5 (upstream registry exists)
**Requirements**: UPST-01, UPST-02, UPST-03, UPST-04
**Plans**: 3/3 complete

Plans:
- [x] 08-01-PLAN.md -- OMC upstream registration + cross-package analysis document
- [x] 08-02-PLAN.md -- Best-of-breed reference docs (3-5 synthesized pattern guides)
- [x] 08-03-PLAN.md -- Generic AI-driven /skippy:update + legacy cleanup

### Phase 9: Skill System
**Goal**: Users can selectively install individual skills or the full suite, and ~10 essential PAI skills are migrated into the portable format
**Depends on**: Phase 6 (core exists as installable unit)
**Requirements**: SKIL-01, SKIL-02, SKIL-03, SKIL-04
**Plans**: 3/3 complete

Plans:
- [x] 09-01-PLAN.md -- Selective install/uninstall (install.sh + uninstall.sh enhancement)
- [x] 09-02-PLAN.md -- INDEX.md categories + /skippy:migrate AI command
- [x] 09-03-PLAN.md -- Migrate ~10 essential skills + integration files

### Phase 10: Bootstrap & Docs
**Goal**: A user on a fresh machine can clone this repo and reach a working PAI setup by following documented steps, with automated verification confirming everything is wired correctly
**Depends on**: Phases 5-9 (everything must exist before bootstrap can orchestrate it)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05
**Plans**: 2/2 complete

Plans:
- [x] 10-01-PLAN.md -- prereqs.sh + verify.sh (bootstrap scripts)
- [x] 10-02-PLAN.md -- SETUP.md, INSTALL.md, UPGRADE.md, README.md, /skippy:upgrade command

</details>

### Phase 11: Foundation
**Goal**: Extract shared shell functions into `tools/lib/common.sh` and add `.gitattributes` for clean distribution
**Depends on**: Phase 10 (v1.1 complete)
**Requirements**: FOUND-01, FOUND-02
**Success Criteria** (what must be TRUE):
  1. `tools/lib/common.sh` exists with `skippy_`-namespaced functions for repo root resolution, pass/warn/fail reporting, and install status detection
  2. All 6 `tools/` scripts source `common.sh` with graceful fallback if the file is missing
  3. No skill scripts (`skills/*/scripts/*.sh`) source `common.sh` -- they remain standalone per portability constraint
  4. `.gitattributes` marks `.planning/` and other dev-only paths as `export-ignore`
  5. `bats tests/common-lib.bats` passes (if tests exist from Phase 12; otherwise manual verification)
**Plans**: 2 plans

Plans:
- [ ] 11-01-PLAN.md -- Create tools/lib/common.sh shared library + .gitattributes
- [ ] 11-02-PLAN.md -- Migrate all 6 tools/ scripts to source common.sh

### Phase 12: Testing
**Goal**: Establish a bats-core test suite with ~30 test cases covering all tool scripts, running in sandboxed HOME isolation
**Depends on**: Phase 11 (common.sh exists for testing)
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria** (what must be TRUE):
  1. `bats tests/` runs ~30 tests and produces TAP-format output with correct exit codes
  2. Every test file's `setup()` overrides `HOME` to `$BATS_TEST_TMPDIR` -- no test ever touches real `~/.claude/`
  3. Test helper at `tests/test_helper/common.bash` loads bats-support and bats-assert
  4. CI workflow at `.github/workflows/test.yml` runs tests on macOS runner
  5. All tests pass on a clean clone (no pre-existing installation required)
**Plans**: TBD

### Phase 13: GSD Pattern Absorption
**Goal**: Absorb GSD's core execution patterns as standalone skippy reference docs, removing all runtime dependency on GSD
**Depends on**: Phase 10 (v1.1 complete -- no dependency on Phases 11-12)
**Requirements**: ABSORB-01, ABSORB-02, ABSORB-03, ABSORB-04, ABSORB-05, ABSORB-06, ABSORB-07
**Success Criteria** (what must be TRUE):
  1. Five new reference docs exist under `skills/skippy-dev/references/`: `phased-execution.md`, `state-tracking.md`, `plan-structure.md`, `wave-parallelism.md`, `checkpoints.md`
  2. Each reference doc is a standalone skippy specification -- no "requires GSD" language, no references to `gsd-tools.cjs`
  3. `grep -r "requires GSD\|gsd-tools" skills/ tools/` returns zero matches (excluding gsd-dependency-map.md historical notes)
  4. `/skippy:reconcile` works against any `.planning/` directory following skippy's own format specification
  5. `gsd-dependency-map.md` updated with header noting format absorption -- risks reframed as "format drift" not "GSD dependency"
**Plans**: TBD

### Phase 14: Audit Swarm
**Goal**: Implement `/skippy:review` as a multi-agent audit command that spawns specialist review agents with sandboxed execution
**Depends on**: Phase 10 (v1.1 complete -- uses existing references for agent prompts)
**Requirements**: SWARM-01, SWARM-02, SWARM-03, SWARM-04, SWARM-05
**Success Criteria** (what must be TRUE):
  1. `skills/skippy-dev/commands/review.md` exists following the standard command pattern (YAML frontmatter + process)
  2. Running `/skippy:review` spawns 4 specialist agents: security, code quality, architecture, and consistency reviewers
  3. A shared findings board (markdown file) aggregates results with severity ratings and cross-references
  4. Fix agents apply changes via atomic commits, and an evaluator agent verifies fixes and checks for regressions
  5. All agent execution overrides `$HOME` to a temp directory -- no agent touches real `~/.claude/` (learned from 71-skill nuke incident)
**Plans**: TBD

### Phase 15: Hardening
**Goal**: Replace hardcoded placeholders in deploy-service with a config mechanism, and add version bump automation
**Depends on**: Phase 11 (common.sh exists for bump-version.sh to source)
**Requirements**: HARD-01, HARD-02, HARD-03
**Success Criteria** (what must be TRUE):
  1. `skills/deploy-service/config.env.example` exists with all 9 configuration variables documented
  2. `skills/deploy-service/config.env` is gitignored; scripts source it with validation (`:?` parameter expansion for required values)
  3. `tools/bump-version.sh` reads current version from `marketplace.json`, accepts `--patch`/`--minor`/`--major`/`--dry-run`, and updates all 25 version locations across 13 files
  4. Running `bump-version.sh --dry-run --patch` shows all files that would change without modifying anything
  5. After a real bump, `grep -r "old-version" .claude-plugin/ skills/*/SKILL.md` returns zero matches
**Plans**: TBD

### Phase 16: Integration & Polish
**Goal**: Final verification pass, documentation consistency, and README updates reflecting "Skippy IS the framework"
**Depends on**: Phases 11-15 (all v1.2 features complete)
**Requirements**: FOUND-03
**Success Criteria** (what must be TRUE):
  1. `CONTRIBUTING.md` documents: how to add a skill, how to run tests, how to submit changes, and the slim SKILL.md convention
  2. `CLAUDE.md` updated to reflect standalone identity -- "Skippy IS the framework" replaces "No GSD modification" constraint
  3. `tools/verify.sh` passes with zero failures after all v1.2 changes
  4. `INDEX.md` regenerated with `/skippy:review` in skippy-dev's command list
  5. README.md updated with test instructions (`bats tests/`) and standalone framing
**Plans**: TBD

## Progress

**Execution Order:**

Phases 11-12 are sequential (tests depend on common.sh). Phases 13-14 are independent of 11-12 and can run in parallel. Phase 15 depends on Phase 11. Phase 16 depends on all.

```
Wave 1: [Phase 11] [Phase 13] [Phase 14]   (parallelizable)
Wave 2: [Phase 12] [Phase 15]              (need Phase 11)
Wave 3: [Phase 16]                          (needs all)
```

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Spec Compliance | v1.0 | 1/1 | Complete | 2026-03-07 |
| 2. Plugin Packaging | v1.0 | 3/3 | Complete | 2026-03-07 |
| 3. Command Validation | v1.0 | 3/3 | Complete | 2026-03-07 |
| 4. Documentation | v1.0 | 2/2 | Complete | 2026-03-07 |
| 5. Foundation | v1.1 | 2/2 | Complete | 2026-03-07 |
| 6. Core Infrastructure | v1.1 | 3/3 | Complete | 2026-03-07 |
| 7. Hook Installation | v1.1 | 3/3 | Complete | 2026-03-07 |
| 8. Upstream Analysis | v1.1 | 3/3 | Complete | 2026-03-08 |
| 9. Skill System | v1.1 | 3/3 | Complete | 2026-03-08 |
| 10. Bootstrap & Docs | v1.1 | 2/2 | Complete | 2026-03-08 |
| 11. Foundation | 2/2 | Complete    | 2026-03-08 | - |
| 12. Testing | v1.2 | 0/0 | Planned | - |
| 13. GSD Pattern Absorption | v1.2 | 0/0 | Planned | - |
| 14. Audit Swarm | v1.2 | 0/0 | Planned | - |
| 15. Hardening | v1.2 | 0/0 | Planned | - |
| 16. Integration & Polish | v1.2 | 0/0 | Planned | - |
