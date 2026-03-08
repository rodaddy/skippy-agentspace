# Requirements: skippy-agentspace

**Defined:** 2026-03-06
**Core Value:** Portable skills that work standalone with vanilla Claude Code, enhanced by PAI when present.

## v1.0 Requirements (Complete)

All 11 requirements shipped. See `milestones/v1.0-REQUIREMENTS.md` for details.

## v1.1 Requirements

Requirements for Portable PAI milestone. Each maps to roadmap phases 5-10.

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
- [ ] **CORE-05**: All 10 claude commands packaged for portable install
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

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Tooling

- **TOOL-01**: Skill scaffolding (`new-skill.sh`) -- generate correct skill directory
- **TOOL-02**: Collision detection in install.sh -- check for reserved command names
- **TOOL-03**: Reference doc metadata -- `last_verified`, `source`, `assumes` fields

### Testing

- **TEST-01**: Known-good GSD fixture for testing reconciliation parsing
- **TEST-02**: Plugin install smoke test via `/plugin install`

### Scale

- **SCALE-01**: Full 68-skill migration (v1.1 does ~10 essential)
- **SCALE-02**: Skill dependency auto-resolution
- **SCALE-03**: Cross-machine sync after bootstrap proven

## Out of Scope

| Feature | Reason |
|---------|--------|
| npm/bun package publishing | Private repo, git-based distribution |
| Web-based marketplace UI | INDEX.md + `/plugin install` is the interface |
| Auto-merging upstream changes | `/skippy:update` reports, human decides |
| Forking GSD, PAUL, or OMC | Parasitic approach -- ride upstream unchanged |
| Shell script bootstrap for symlinks | Unreliable -- use SETUP.md instructions instead |
| Multi-user support | Single-user reality |
| OMC runtime dependency | Cherry-pick ideas, not their Node.js runtime |
| BDD ceremony | Too much overhead for solo dev |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SPEC-01 | Phase 1 | Complete |
| SPEC-02 | Phase 1 | Complete |
| SPEC-03 | Phase 1 | Complete |
| SPEC-04 | Phase 2 | Complete |
| CMD-01 | Phase 3 | Complete |
| CMD-02 | Phase 3 | Complete |
| CMD-03 | Phase 3 | Complete |
| DOC-01 | Phase 4 | Complete |
| STRU-01 | Phase 1 | Complete |
| STRU-02 | Phase 4 | Complete |
| STRU-03 | Phase 2 | Complete |
| FOUN-01 | Phase 5 | Complete |
| FOUN-02 | Phase 5 | Complete |
| FOUN-03 | Phase 5 | Complete |
| FOUN-04 | Phase 5 | Complete |
| CORE-01 | Phase 6 | Complete |
| CORE-02 | Phase 6 | Complete |
| CORE-03 | Phase 6 | Complete |
| CORE-04 | Phase 6 | Complete |
| CORE-05 | Phase 6 | Deferred |
| CORE-06 | Phase 6 | Complete |
| HOOK-01 | Phase 7 | Complete |
| HOOK-02 | Phase 7 | Complete |
| HOOK-03 | Phase 7 | Complete |
| HOOK-04 | Phase 7 | Complete |
| HOOK-05 | Phase 7 | Complete |
| UPST-01 | Phase 8 | Complete |
| UPST-02 | Phase 8 | Complete |
| UPST-03 | Phase 8 | Complete |
| UPST-04 | Phase 8 | Complete |
| SKIL-01 | Phase 9 | Complete |
| SKIL-02 | Phase 9 | Complete |
| SKIL-03 | Phase 9 | Complete |
| SKIL-04 | Phase 9 | Complete |
| BOOT-01 | Phase 10 | Complete |
| BOOT-02 | Phase 10 | Complete |
| BOOT-03 | Phase 10 | Complete |
| BOOT-04 | Phase 10 | Complete |
| BOOT-05 | Phase 10 | Complete |

**Coverage:**
- v1.0 requirements: 11 total (all complete)
- v1.1 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-07 after v1.1 roadmap creation*
