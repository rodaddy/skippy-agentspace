# Requirements: skippy-agentspace

**Defined:** 2026-03-06
**Core Value:** Portable skills that work standalone with vanilla Claude Code, enhanced by PAI when present.

## v1.0 Requirements (Complete)

All 11 requirements shipped. See `milestones/v1.0-REQUIREMENTS.md` for details.

## v1.1 Requirements

Requirements for Portable PAI milestone. Each maps to roadmap phases 5-10.

### Foundation

- [ ] **FOUN-01**: Public/private content boundary is defined and documented
- [ ] **FOUN-02**: Extensible upstream registry replaces hardcoded GSD+PAUL tracking
- [ ] **FOUN-03**: Adding a new upstream is creating a directory, not changing code
- [ ] **FOUN-04**: Existing `.versions` data migrated to new upstream format

### Core Infrastructure

- [ ] **CORE-01**: Personas (Skippy, Bob, Clarisa, April) packaged as portable definitions
- [ ] **CORE-02**: LAWs (15) packaged with enforcement descriptions
- [ ] **CORE-03**: Style rules and communication conventions packaged
- [ ] **CORE-04**: CLAUDE.md template available for new projects
- [ ] **CORE-05**: All 10 claude commands packaged for portable install
- [ ] **CORE-06**: Core follows slim SKILL.md + deep references pattern

### Hooks

- [ ] **HOOK-01**: Hook manifest declares all hooks and their settings.json registrations
- [ ] **HOOK-02**: Hook installer merges into settings.json via jq without destroying existing hooks
- [ ] **HOOK-03**: Hook uninstaller cleanly removes only our hooks
- [ ] **HOOK-04**: Hook operations are idempotent (safe to re-run)
- [ ] **HOOK-05**: settings.json is backed up before any modification

### Upstream Analysis

- [ ] **UPST-01**: OMC added as third upstream source in registry
- [ ] **UPST-02**: Cross-package analysis identifies patterns common across GSD, PAUL, and OMC
- [ ] **UPST-03**: Best-of-breed skippy versions created for common patterns
- [ ] **UPST-04**: `/skippy:update` uses generic upstream checker instead of hardcoded repos

### Skill System

- [ ] **SKIL-01**: install.sh supports selective install (--core, --skill, --all flags)
- [ ] **SKIL-02**: migrate-skill.sh imports skills from ~/.config/pai/Skills/ into portable format
- [ ] **SKIL-03**: ~10 essential skills migrated with slim SKILL.md + deep references
- [ ] **SKIL-04**: INDEX.md updated with categories and install status

### Bootstrap & Docs

- [ ] **BOOT-01**: prereqs.sh validates required tools (bun, jq, bash 4+, git)
- [ ] **BOOT-02**: SETUP.md provides step-by-step first-time setup instructions
- [ ] **BOOT-03**: INSTALL.md provides instructions for adding skills/components
- [ ] **BOOT-04**: UPGRADE.md provides instructions for updating from previous version
- [ ] **BOOT-05**: Verification script confirms everything is wired correctly after setup

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
| FOUN-01 | Phase 5 | Pending |
| FOUN-02 | Phase 5 | Pending |
| FOUN-03 | Phase 5 | Pending |
| FOUN-04 | Phase 5 | Pending |
| CORE-01 | Phase 6 | Pending |
| CORE-02 | Phase 6 | Pending |
| CORE-03 | Phase 6 | Pending |
| CORE-04 | Phase 6 | Pending |
| CORE-05 | Phase 6 | Pending |
| CORE-06 | Phase 6 | Pending |
| HOOK-01 | Phase 7 | Pending |
| HOOK-02 | Phase 7 | Pending |
| HOOK-03 | Phase 7 | Pending |
| HOOK-04 | Phase 7 | Pending |
| HOOK-05 | Phase 7 | Pending |
| UPST-01 | Phase 8 | Pending |
| UPST-02 | Phase 8 | Pending |
| UPST-03 | Phase 8 | Pending |
| UPST-04 | Phase 8 | Pending |
| SKIL-01 | Phase 9 | Pending |
| SKIL-02 | Phase 9 | Pending |
| SKIL-03 | Phase 9 | Pending |
| SKIL-04 | Phase 9 | Pending |
| BOOT-01 | Phase 10 | Pending |
| BOOT-02 | Phase 10 | Pending |
| BOOT-03 | Phase 10 | Pending |
| BOOT-04 | Phase 10 | Pending |
| BOOT-05 | Phase 10 | Pending |

**Coverage:**
- v1.0 requirements: 11 total (all complete)
- v1.1 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-07 after v1.1 roadmap creation*
