# Roadmap: skippy-agentspace

## Overview

Transform skippy-agentspace from a working-but-non-portable skill repo into a spec-compliant, plugin-packaged, validated skill marketplace. The journey follows the dependency chain: fix broken paths and structure first (so packaging doesn't copy broken files), package for plugin distribution second (so command testing includes the plugin install path), validate commands third (so docs describe working behavior), and document last (so documentation reflects reality).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Spec Compliance** - Align skill structure and paths to Agent Skills standard
- [ ] **Phase 2: Plugin Packaging** - Enable native `/plugin install` distribution
- [ ] **Phase 3: Command Validation** - Harden and validate all three skippy commands against real workflows
- [ ] **Phase 4: Documentation** - Cold session context and GSD dependency mapping

## Phase Details

### Phase 1: Spec Compliance
**Goal**: Skill files are portable and conform to the Agent Skills open standard -- any machine, any user, plugin or manual install
**Depends on**: Nothing (first phase)
**Requirements**: SPEC-01, SPEC-02, SPEC-03, STRU-01
**Success Criteria** (what must be TRUE):
  1. No absolute paths exist in any skill file -- all references use `${CLAUDE_SKILL_DIR}` or relative paths
  2. SKILL.md frontmatter passes Agent Skills spec validation (required fields: `name`, `description`; non-standard `triggers:` removed; `metadata:` block present with version and author)
  3. `scripts/` directory exists where `bin/` was -- all internal references updated, no broken script paths
  4. Skill follows progressive disclosure pattern -- slim SKILL.md entry point under 150 lines, detail in `references/` and `docs/`, navigation index present
**Plans**: 1 plan

Plans:
- [ ] 01-01-PLAN.md -- Fix paths, align frontmatter, rename bin/ to scripts/, verify structure

### Phase 2: Plugin Packaging
**Goal**: Users can install skippy-dev via `/plugin marketplace add` with a single command, and install tooling supports both modern and legacy targets
**Depends on**: Phase 1
**Requirements**: SPEC-04, STRU-03
**Success Criteria** (what must be TRUE):
  1. `.claude-plugin/plugin.json` exists with valid schema and `strict: false` pattern
  2. `marketplace.json` at repo root lists available skills with correct paths
  3. Install tooling (`tools/install.sh`) detects target environment and symlinks to `~/.claude/skills/` (modern) or `~/.claude/commands/` (legacy) correctly
  4. A clean clone of the repo can be installed via plugin system and skill loads without errors
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Command Validation
**Goal**: All three skippy commands run correctly against real workflows and survive edge cases
**Depends on**: Phase 2
**Requirements**: CMD-01, CMD-02, CMD-03
**Success Criteria** (what must be TRUE):
  1. `/skippy:reconcile` reads a real `.planning/` project with completed GSD phases, compares PLAN.md to execution output, and reports deviations without errors
  2. `/skippy:update` clones upstream repos to `~/.cache/` (not `/tmp/`), parses `.versions` without `source`, uses full SHA hashes, and state survives macOS reboot
  3. `/skippy:cleanup` quarantine mode moves files to quarantine dir with accurate space reporting, nuke mode deletes permanently, and empty dirs are recreated after cleanup
  4. All three scripts exit cleanly on missing inputs (no `.planning/`, no upstream repos, no files to clean) with informative error messages
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Documentation
**Goal**: A new session opening this repo immediately understands what it is, how it works, and what depends on what
**Depends on**: Phase 3
**Requirements**: DOC-01, STRU-02
**Success Criteria** (what must be TRUE):
  1. GSD dependency map exists documenting every `.planning/` integration point (file paths, field names, structure assumptions) with breakage risk annotations for upstream GSD changes
  2. CLAUDE.md includes origin story, architectural decisions, current project status, and enough context that a cold session can orient and begin work without asking questions
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Spec Compliance | 0/1 | Not started | - |
| 2. Plugin Packaging | 0/1 | Not started | - |
| 3. Command Validation | 0/2 | Not started | - |
| 4. Documentation | 0/1 | Not started | - |
