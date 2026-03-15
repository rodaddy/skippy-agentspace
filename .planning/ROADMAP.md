# Roadmap: skippy-agentspace

## Milestones

- [x] **v1.0 Initial Release** - Phases 1-4 (shipped 2026-03-07)
- [x] **v1.1 Portable PAI** - Phases 5-10 (shipped 2026-03-08)
- [x] **v1.2 Standalone Skippy** - Phases 11-16 (shipped 2026-03-08)

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

<details>
<summary>v1.2 Standalone Skippy (Phases 11-16) - SHIPPED 2026-03-08</summary>

- [x] **Phase 11: Foundation** - Shared shell library and repo hygiene (.gitattributes) (completed 2026-03-08)
- [x] **Phase 12: Testing** - bats-core test suite with sandboxed HOME isolation (completed 2026-03-08)
- [x] **Phase 13: GSD Pattern Absorption** - Reference docs for standalone execution patterns (completed 2026-03-08)
- [x] **Phase 14: Audit Swarm** - `/skippy:review` multi-agent review command (completed 2026-03-08)
- [x] **Phase 15: Hardening** - deploy-service config mechanism and version management (completed 2026-03-08)
- [x] **Phase 16: Integration & Polish** - Final verification, doc consistency, CONTRIBUTING.md (completed 2026-03-08)

</details>

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
**Goal**: Users can install skippy via `/plugin marketplace add` with a single command
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

<details>
<summary>v1.2 Phase Details (Phases 11-16) - SHIPPED 2026-03-08</summary>

### Phase 11: Foundation
**Goal**: Extract shared shell functions into `tools/lib/common.sh` and add `.gitattributes` for clean distribution
**Depends on**: Phase 10 (v1.1 complete)
**Requirements**: FOUND-01, FOUND-02
**Plans**: 2/2 complete

Plans:
- [x] 11-01-PLAN.md -- Create tools/lib/common.sh shared library + .gitattributes (completed 2026-03-08)
- [x] 11-02-PLAN.md -- Migrate all 6 tools/ scripts to source common.sh (completed 2026-03-08)

### Phase 12: Testing
**Goal**: Establish a bats-core test suite with ~30 test cases covering all tool scripts, running in sandboxed HOME isolation
**Depends on**: Phase 11 (common.sh exists for testing)
**Requirements**: TEST-01, TEST-02, TEST-03
**Plans**: 3/3 complete

Plans:
- [x] 12-01-PLAN.md -- bats submodules + test helper + common-lib.bats tests (completed 2026-03-08)
- [x] 12-02-PLAN.md -- install.bats + uninstall.bats tests (safety-critical scripts) (completed 2026-03-08)
- [x] 12-03-PLAN.md -- verify.bats + index-sync.bats + validate-hooks.bats + CI workflow (completed 2026-03-08)

### Phase 13: GSD Pattern Absorption
**Goal**: Absorb GSD's core execution patterns as 4 standalone skippy reference docs
**Depends on**: Phase 10 (v1.1 complete)
**Requirements**: ABSORB-01, ABSORB-02, ABSORB-03, ABSORB-04, ABSORB-05, ABSORB-06, ABSORB-07
**Plans**: 3/3 complete

Plans:
- [x] 13-01-PLAN.md -- Create 4 standalone reference docs (phased-execution, state-tracking, plan-structure, checkpoints) (completed 2026-03-08)
- [x] 13-02-PLAN.md -- Create skippy-state.ts parser + update reconcile.md for markdown task format (completed 2026-03-08)
- [x] 13-03-PLAN.md -- GSD language cleanup across 8 reference docs, SKILL.md update, PROJECT.md update, delete superseded files (completed 2026-03-08)

### Phase 14: Audit Swarm
**Goal**: Implement `/skippy:review` as a multi-agent audit command with specialist review agents
**Depends on**: Phase 10 (v1.1 complete)
**Requirements**: SWARM-01, SWARM-02, SWARM-03, SWARM-04, SWARM-05
**Plans**: 2/2 complete

Plans:
- [x] 14-01-PLAN.md -- Agent definitions (6 subagents) + audit-swarm.md reference doc (completed 2026-03-08)
- [x] 14-02-PLAN.md -- /skippy:review command + SKILL.md, INDEX.md, CLAUDE.md integration (completed 2026-03-08)

### Phase 15: Hardening
**Goal**: Replace hardcoded placeholders in deploy-service with a config mechanism, and add version bump automation
**Depends on**: Phase 11 (common.sh exists for bump-version.sh to source)
**Requirements**: HARD-01, HARD-02, HARD-03
**Plans**: 2/2 complete

Plans:
- [x] 15-01-PLAN.md -- deploy-service config.env mechanism (HARD-01, HARD-03) (completed 2026-03-08)
- [x] 15-02-PLAN.md -- bump-version.sh version automation (HARD-02) (completed 2026-03-08)

### Phase 16: Integration & Polish
**Goal**: Final verification pass, documentation consistency, and README updates reflecting standalone identity
**Depends on**: Phases 11-15 (all v1.2 features complete)
**Requirements**: FOUND-03
**Plans**: 2/2 complete

Plans:
- [x] 16-01-PLAN.md -- CONTRIBUTING.md + CLAUDE.md/README.md standalone identity updates
- [x] 16-02-PLAN.md -- verify.sh review command fix + final verification pass

</details>

## Progress

All 16 phases across 3 milestones complete. 39 plans executed.

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
| 11. Foundation | v1.2 | 2/2 | Complete | 2026-03-08 |
| 12. Testing | v1.2 | 3/3 | Complete | 2026-03-08 |
| 13. GSD Pattern Absorption | v1.2 | 3/3 | Complete | 2026-03-08 |
| 14. Audit Swarm | v1.2 | 2/2 | Complete | 2026-03-08 |
| 15. Hardening | v1.2 | 2/2 | Complete | 2026-03-08 |
| 16. Integration & Polish | v1.2 | 2/2 | Complete | 2026-03-08 |
