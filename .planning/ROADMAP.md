# Roadmap: skippy-agentspace

## Milestones

- [x] **v1.0 Initial Release** - Phases 1-4 (shipped 2026-03-07)
- [ ] **v1.1 Portable PAI** - Phases 5-10 (in progress)

## Phases

<details>
<summary>v1.0 Initial Release (Phases 1-4) - SHIPPED 2026-03-07</summary>

- [x] **Phase 1: Spec Compliance** - Align skill structure and paths to Agent Skills standard (completed 2026-03-07)
- [x] **Phase 2: Plugin Packaging** - Enable native `/plugin install` distribution (completed 2026-03-07)
- [x] **Phase 3: Command Validation** - Harden and validate all three skippy commands against real workflows (completed 2026-03-07)
- [x] **Phase 4: Documentation** - Cold session context and GSD dependency mapping (completed 2026-03-07)

</details>

### v1.1 Portable PAI

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (5.1, 5.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 5: Foundation** - Public/private content boundary and extensible upstream registry
- [ ] **Phase 6: Core Infrastructure** - Personas, LAWs, rules, commands, and CLAUDE.md template packaged as portable core
- [ ] **Phase 7: Hook Installation** - Non-destructive settings.json hook merging with manifest-driven install/uninstall
- [ ] **Phase 8: Upstream Analysis** - OMC as third upstream, cross-package analysis, and generic upstream checker
- [ ] **Phase 9: Skill System** - Selective install flags, skill migration tool, and ~10 essential skills ported
- [ ] **Phase 10: Bootstrap & Docs** - Prerequisite validation, setup/install/upgrade docs, and post-install verification

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

### Phase 5: Foundation
**Goal**: Architectural conventions are established so all subsequent phases build on a clean public/private boundary and an extensible upstream tracking system
**Depends on**: Phase 4 (v1.0 complete)
**Requirements**: FOUN-01, FOUN-02, FOUN-03, FOUN-04
**Success Criteria** (what must be TRUE):
  1. A documented convention distinguishes public content (safe to commit) from private content (never committed), and .gitignore enforces it
  2. Running `ls upstreams/` shows one directory per tracked upstream (gsd, paul), each containing an `upstream.conf` with repo URL, branch, and last-checked SHA
  3. Adding a new upstream source requires only creating a new directory under `upstreams/` with the standard files -- no script or code changes needed
  4. Existing `.versions` tracking data is present in the new upstream format with no data loss
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

### Phase 6: Core Infrastructure
**Goal**: The essential PAI operating layer -- personas, LAWs, rules, commands, and project templates -- is packaged as a portable, installable core that follows the slim SKILL.md pattern
**Depends on**: Phase 5 (public/private boundary defined)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, CORE-06
**Success Criteria** (what must be TRUE):
  1. All 4 personas (Skippy, Bob, Clarisa, April) exist as individual definition files under `core/` with name, style, and behavioral rules
  2. All 15 LAWs are packaged with enforcement descriptions (which are hook-enforced vs convention-enforced)
  3. A CLAUDE.md template exists that a new project can copy and customize, pre-wired with LAW references and persona defaults
  4. All 10 claude commands from `~/.claude/commands/` are packaged under `core/` with working symlink targets
  5. `core/SKILL.md` is under 150 lines, with all detail in `core/references/` subdirectories
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD
- [ ] 06-03: TBD

### Phase 7: Hook Installation
**Goal**: Users can install and uninstall PAI hooks into Claude Code's settings.json without destroying existing hook registrations from GSD, OMC, or other systems
**Depends on**: Phase 6 (hooks live in core/)
**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05
**Success Criteria** (what must be TRUE):
  1. A hook manifest file declares every hook with its event type, matcher pattern, command, and description
  2. Running the hook installer on a settings.json that already contains GSD hooks results in both PAI and GSD hooks present -- no GSD hooks removed or modified
  3. Running the hook uninstaller removes only PAI-registered hooks, leaving all other hooks intact
  4. Running the installer twice produces the same settings.json as running it once (idempotent)
  5. A timestamped backup of settings.json is created before any modification
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD

### Phase 8: Upstream Analysis
**Goal**: OMC is tracked as a third upstream source, cross-package patterns are identified and cherry-picked, and `/skippy:update` works generically against any registered upstream
**Depends on**: Phase 5 (upstream registry exists)
**Requirements**: UPST-01, UPST-02, UPST-03, UPST-04
**Success Criteria** (what must be TRUE):
  1. `upstreams/omc/` exists with upstream.conf pointing to oh-my-claudecode repo, and `/skippy:update` reports its version status alongside GSD and PAUL
  2. A cross-package analysis document identifies patterns that appear in 2+ upstreams (e.g., model routing, task verification, context management) with notes on which implementation is best
  3. At least 3 "best-of-breed" skippy reference docs exist that synthesize the strongest version of shared patterns across upstreams
  4. `/skippy:update` uses a generic upstream checker that iterates `upstreams/*/upstream.conf` instead of hardcoded repo URLs
**Plans**: TBD

Plans:
- [ ] 08-01: TBD
- [ ] 08-02: TBD

### Phase 9: Skill System
**Goal**: Users can selectively install individual skills or the full suite, and ~10 essential PAI skills are migrated into the portable format
**Depends on**: Phase 6 (core exists as installable unit)
**Requirements**: SKIL-01, SKIL-02, SKIL-03, SKIL-04
**Success Criteria** (what must be TRUE):
  1. `install.sh --core` installs only the core infrastructure; `install.sh --skill skippy-dev` installs a single skill; `install.sh --all` installs everything
  2. `migrate-skill.sh` takes a skill directory from `~/.config/pai/Skills/` and produces a portable version with slim SKILL.md + deep references under `skills/`
  3. At least 10 essential skills are migrated and installable, each with a SKILL.md under 150 lines
  4. INDEX.md lists all available skills with categories (core, workflow, utility, domain) and current install status
**Plans**: TBD

Plans:
- [ ] 09-01: TBD
- [ ] 09-02: TBD

### Phase 10: Bootstrap & Docs
**Goal**: A user on a fresh machine can clone this repo and reach a working PAI setup by following documented steps, with automated verification confirming everything is wired correctly
**Depends on**: Phases 5-9 (everything must exist before bootstrap can orchestrate it)
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05
**Success Criteria** (what must be TRUE):
  1. `prereqs.sh` checks for bun, jq, bash 4+, and git -- reports missing tools with install instructions (e.g., "brew install jq")
  2. SETUP.md walks a first-time user from clone to working PAI in numbered steps, with no assumed knowledge beyond "you have a Mac with Homebrew"
  3. INSTALL.md covers adding individual skills or components to an existing setup
  4. UPGRADE.md covers updating from a previous version without losing customizations
  5. A verification script confirms symlinks resolve, hooks are registered, commands are accessible, and core files are in place -- outputting pass/fail per check
**Plans**: TBD

Plans:
- [ ] 10-01: TBD
- [ ] 10-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 5 -> 6 -> 7 -> 8 -> 9 -> 10
(Phase 8 depends only on Phase 5 and could overlap with 6-7 in theory, but sequential execution is simpler.)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Spec Compliance | v1.0 | 1/1 | Complete | 2026-03-07 |
| 2. Plugin Packaging | v1.0 | 3/3 | Complete | 2026-03-07 |
| 3. Command Validation | v1.0 | 3/3 | Complete | 2026-03-07 |
| 4. Documentation | v1.0 | 2/2 | Complete | 2026-03-07 |
| 5. Foundation | v1.1 | 0/? | Not started | - |
| 6. Core Infrastructure | v1.1 | 0/? | Not started | - |
| 7. Hook Installation | v1.1 | 0/? | Not started | - |
| 8. Upstream Analysis | v1.1 | 0/? | Not started | - |
| 9. Skill System | v1.1 | 0/? | Not started | - |
| 10. Bootstrap & Docs | v1.1 | 0/? | Not started | - |
