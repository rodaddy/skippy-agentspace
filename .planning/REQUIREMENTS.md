# Requirements: skippy-agentspace

**Defined:** 2026-03-06
**Core Value:** Portable skills that work standalone with vanilla Claude Code, enhanced by PAI when present.

## v1.0 Requirements (Validated)

All 11 requirements shipped 2026-03-07. See `milestones/v1.0-REQUIREMENTS.md` for details.

## v1.1 Requirements (Validated)

All 28 requirements shipped 2026-03-08. Phases 5-10 complete.

### Foundation

- [x] **FOUN-01**: Public/private content boundary is defined and documented
- [x] **FOUN-02**: Extensible upstream registry replaces hardcoded GSD+PAUL tracking
- [x] **FOUN-03**: Adding a new upstream is creating a directory, not changing code
- [x] **FOUN-04**: Existing `.versions` data migrated to new upstream format

### Core Infrastructure

- [x] **CORE-01**: Personas (Skippy, Bob, Clarisa, April) packaged as portable definitions
- [x] **CORE-02**: LAWs (15) packaged with enforcement descriptions
- [x] **CORE-03**: Style rules and communication conventions packaged
- [x] **CORE-04**: CLAUDE.md template available for new projects
- [x] **CORE-05**: All 10 claude commands packaged for portable install (deferred to v1.2+)
- [x] **CORE-06**: Core follows slim SKILL.md + deep references pattern

### Hooks

- [x] **HOOK-01**: Hook manifest declares all hooks and their settings.json registrations
- [x] **HOOK-02**: Hook installer merges into settings.json via jq without destroying existing hooks
- [x] **HOOK-03**: Hook uninstaller cleanly removes only our hooks
- [x] **HOOK-04**: Hook operations are idempotent (safe to re-run)
- [x] **HOOK-05**: settings.json is backed up before any modification

### Upstream Analysis

- [x] **UPST-01**: OMC added as third upstream source in registry
- [x] **UPST-02**: Cross-package analysis identifies patterns common across GSD, PAUL, and OMC
- [x] **UPST-03**: Best-of-breed skippy versions created for common patterns
- [x] **UPST-04**: `/skippy:update` uses generic upstream checker instead of hardcoded repos

### Skill System

- [x] **SKIL-01**: install.sh supports selective install (--core, --skill, --all flags)
- [x] **SKIL-02**: migrate-skill.sh imports skills from ~/.config/pai/Skills/ into portable format
- [x] **SKIL-03**: ~10 essential skills migrated with slim SKILL.md + deep references
- [x] **SKIL-04**: INDEX.md updated with categories and install status

### Bootstrap & Docs

- [x] **BOOT-01**: prereqs.sh validates required tools (bun, jq, bash 4+, git)
- [x] **BOOT-02**: SETUP.md provides step-by-step first-time setup instructions
- [x] **BOOT-03**: INSTALL.md provides instructions for adding skills/components
- [x] **BOOT-04**: UPGRADE.md provides instructions for updating from previous version
- [x] **BOOT-05**: Verification script confirms everything is wired correctly after setup

## v1.2 Requirements

Requirements for Standalone Skippy milestone. Phases 11-16.

### Foundation

- [ ] **FOUND-01**: `tools/lib/common.sh` extracts shared functions (`REPO_ROOT`, `pass`/`warn`/`fail`, `is_installed`) used by 3+ scripts
- [ ] **FOUND-02**: `.gitattributes` marks `.planning/` as `export-ignore` for distribution
- [ ] **FOUND-03**: `CONTRIBUTING.md` documents how to add skills, run tests, and submit changes

### Testing

- [ ] **TEST-01**: bats-core test suite with ~30 test cases covering install/uninstall/verify/index-sync
- [ ] **TEST-02**: All tests run in sandboxed `HOME` (never touch real `~/.claude/`)
- [ ] **TEST-03**: Test runner integrable with CI (TAP output, exit codes)

### GSD Absorption

- [ ] **ABSORB-01**: Reference docs absorb GSD phased execution pattern (plan -> execute -> verify cycle)
- [ ] **ABSORB-02**: Reference docs absorb GSD state tracking pattern (STATE.md, progress, position)
- [ ] **ABSORB-03**: Reference docs absorb GSD plan structure (frontmatter, tasks, verification criteria)
- [ ] **ABSORB-04**: Reference docs absorb GSD wave-based parallel execution and checkpoint handling
- [ ] **ABSORB-05**: Reference docs absorb GSD verification loops (VERIFICATION.md, must_haves, gap closure)
- [ ] **ABSORB-06**: All "requires GSD" mentions removed from docs and commands
- [ ] **ABSORB-07**: `/skippy:reconcile` works against any `.planning/` structure, not just GSD's

### Audit Swarm

- [ ] **SWARM-01**: `/skippy:review` command spawns 4 specialist review agents (security, code quality, architecture, consistency)
- [ ] **SWARM-02**: Shared findings board aggregates results with cross-references
- [ ] **SWARM-03**: Fix agents address actionable findings with atomic commits
- [ ] **SWARM-04**: Re-evaluation loop verifies fixes and finds regressions
- [ ] **SWARM-05**: All swarm testing runs in sandboxed HOME with backup-restore

### Hardening

- [ ] **HARD-01**: deploy-service uses shell-sourceable `config.env` with validation (replaces 9 hardcoded placeholders)
- [ ] **HARD-02**: Version bump script updates VERSION file + all 25 version locations across 13 files
- [ ] **HARD-03**: `config.env.example` committed, `config.env` gitignored

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Tooling

- **TOOL-01**: Skill scaffolding (`new-skill.sh`) -- generate correct skill directory
- **TOOL-02**: Collision detection in install.sh -- check for reserved command names
- **TOOL-03**: Reference doc metadata -- `last_verified`, `source`, `assumes` fields

### Scale

- **SCALE-01**: Full 68-skill migration (v1.1 does ~10 essential)
- **SCALE-02**: Skill dependency auto-resolution
- **SCALE-03**: Cross-machine sync after bootstrap proven

### Swarm Enhancements

- **SWRM-01**: Persistent findings database for audit swarm
- **SWRM-02**: Per-file review caching
- **SWRM-03**: deploy-service dry-run mode

## Out of Scope

| Feature | Reason |
|---------|--------|
| Porting gsd-tools.cjs | Agent IS the runtime -- absorb patterns as markdown, not code |
| Real-time agent communication | Shared file is sufficient for sequential agent pipeline |
| CI/CD pipeline setup | Test runner is CI-ready (TAP output), pipeline is user's choice |
| Mobile/cross-platform support | macOS + Linux only |
| npm/bun package publishing | Private repo, git-based distribution |
| Web-based marketplace UI | INDEX.md + `/plugin install` is the interface |
| Auto-merging upstream changes | `/skippy:update` reports, human decides |
| Forking GSD, PAUL, or OMC | Parasitic approach -- ride upstream unchanged |
| Multi-user support | Single-user reality |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SPEC-01 | Phase 1 | Validated (v1.0) |
| SPEC-02 | Phase 1 | Validated (v1.0) |
| SPEC-03 | Phase 1 | Validated (v1.0) |
| SPEC-04 | Phase 2 | Validated (v1.0) |
| CMD-01 | Phase 3 | Validated (v1.0) |
| CMD-02 | Phase 3 | Validated (v1.0) |
| CMD-03 | Phase 3 | Validated (v1.0) |
| DOC-01 | Phase 4 | Validated (v1.0) |
| STRU-01 | Phase 1 | Validated (v1.0) |
| STRU-02 | Phase 4 | Validated (v1.0) |
| STRU-03 | Phase 2 | Validated (v1.0) |
| FOUN-01 | Phase 5 | Validated (v1.1) |
| FOUN-02 | Phase 5 | Validated (v1.1) |
| FOUN-03 | Phase 5 | Validated (v1.1) |
| FOUN-04 | Phase 5 | Validated (v1.1) |
| CORE-01 | Phase 6 | Validated (v1.1) |
| CORE-02 | Phase 6 | Validated (v1.1) |
| CORE-03 | Phase 6 | Validated (v1.1) |
| CORE-04 | Phase 6 | Validated (v1.1) |
| CORE-05 | Phase 6 | Deferred |
| CORE-06 | Phase 6 | Validated (v1.1) |
| HOOK-01 | Phase 7 | Validated (v1.1) |
| HOOK-02 | Phase 7 | Validated (v1.1) |
| HOOK-03 | Phase 7 | Validated (v1.1) |
| HOOK-04 | Phase 7 | Validated (v1.1) |
| HOOK-05 | Phase 7 | Validated (v1.1) |
| UPST-01 | Phase 8 | Validated (v1.1) |
| UPST-02 | Phase 8 | Validated (v1.1) |
| UPST-03 | Phase 8 | Validated (v1.1) |
| UPST-04 | Phase 8 | Validated (v1.1) |
| SKIL-01 | Phase 9 | Validated (v1.1) |
| SKIL-02 | Phase 9 | Validated (v1.1) |
| SKIL-03 | Phase 9 | Validated (v1.1) |
| SKIL-04 | Phase 9 | Validated (v1.1) |
| BOOT-01 | Phase 10 | Validated (v1.1) |
| BOOT-02 | Phase 10 | Validated (v1.1) |
| BOOT-03 | Phase 10 | Validated (v1.1) |
| BOOT-04 | Phase 10 | Validated (v1.1) |
| BOOT-05 | Phase 10 | Validated (v1.1) |
| FOUND-01 | Phase 11 | Pending |
| FOUND-02 | Phase 11 | Pending |
| FOUND-03 | Phase 16 | Pending |
| TEST-01 | Phase 12 | Pending |
| TEST-02 | Phase 12 | Pending |
| TEST-03 | Phase 12 | Pending |
| ABSORB-01 | Phase 13 | Pending |
| ABSORB-02 | Phase 13 | Pending |
| ABSORB-03 | Phase 13 | Pending |
| ABSORB-04 | Phase 13 | Pending |
| ABSORB-05 | Phase 13 | Pending |
| ABSORB-06 | Phase 13 | Pending |
| ABSORB-07 | Phase 13 | Pending |
| SWARM-01 | Phase 14 | Pending |
| SWARM-02 | Phase 14 | Pending |
| SWARM-03 | Phase 14 | Pending |
| SWARM-04 | Phase 14 | Pending |
| SWARM-05 | Phase 14 | Pending |
| HARD-01 | Phase 15 | Pending |
| HARD-02 | Phase 15 | Pending |
| HARD-03 | Phase 15 | Pending |

**Coverage:**
- v1.0 requirements: 11 total (all validated)
- v1.1 requirements: 28 total (all validated)
- v1.2 requirements: 22 total (all pending)
- Mapped to phases: 61
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-08 after v1.2 roadmap creation*
