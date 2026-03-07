# Requirements: skippy-agentspace

**Defined:** 2026-03-06
**Core Value:** Portable skills that work standalone with vanilla Claude Code, enhanced by PAI when present.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Spec Compliance

- [x] **SPEC-01**: All skill files use portable paths -- no hardcoded absolute paths, use `${CLAUDE_SKILL_DIR}` or relative paths
- [x] **SPEC-02**: SKILL.md frontmatter aligned to Agent Skills standard -- `name`, `description` required; non-standard `triggers:` field removed; `metadata:` block added with version and author
- [x] **SPEC-03**: `bin/` directory renamed to `scripts/` across all skills (Agent Skills spec convention)
- [x] **SPEC-04**: Plugin packaging -- `.claude-plugin/plugin.json` and `marketplace.json` enable native `/plugin install` from this repo

### Commands

- [x] **CMD-01**: `/skippy:reconcile` works end-to-end against a real `.planning/` project with completed GSD phases -- reads PLAN.md, compares to execution output, reports deviations
- [x] **CMD-02**: `/skippy:update` hardened -- clones to `~/.cache/` (not `/tmp/`), parses `.versions` safely (no `source`), uses full SHA hashes, survives macOS reboot
- [x] **CMD-03**: `/skippy:cleanup` validated -- quarantine and nuke modes both work correctly, space reporting accurate, empty dirs recreated after cleanup

### Documentation

- [ ] **DOC-01**: GSD dependency map -- document every GSD `.planning/` integration point (file paths, field names, structure assumptions) and breakage risk if GSD changes upstream

### Structure

- [x] **STRU-01**: Skill follows PAI pattern -- slim SKILL.md entry point, detail in `references/` and `docs/`, index file for navigation
- [ ] **STRU-02**: CLAUDE.md includes origin story, architectural decisions, current status, and enough context for cold session orientation
- [x] **STRU-03**: Install tooling supports both `~/.claude/skills/` (modern) and `~/.claude/commands/` (legacy) targets

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Tooling

- **TOOL-01**: Skill scaffolding (`new-skill.sh`) -- generate correct skill directory with SKILL.md template, valid frontmatter, directory stubs. Build when adding the second skill.
- **TOOL-02**: Collision detection in install.sh -- check for reserved command names before symlinking
- **TOOL-03**: Reference doc metadata -- add `last_verified`, `source`, `assumes` fields to each reference doc header

### Testing

- **TEST-01**: Known-good GSD fixture -- a synthetic `.planning/` directory with completed phases for testing reconciliation parsing
- **TEST-02**: Plugin install smoke test -- verify skills work when installed via `/plugin install` (cache path, `${CLAUDE_SKILL_DIR}` expansion)

## Out of Scope

| Feature | Reason |
|---------|--------|
| npm/bun package publishing | Private repo, git-based plugin marketplace achieves distribution |
| Web-based marketplace UI | Multiple community UIs exist. INDEX.md + `/plugin install` is the interface |
| Cross-agent portability testing | Agent Skills format is inherently portable. Test Claude Code only. |
| Auto-merging upstream changes | PROJECT.md explicitly rejects. `/skippy:update` reports, human decides. |
| Telemetry / analytics | Noise for a personal repo. Use git log. |
| Inter-skill dependencies | Self-contained skills only. Complexity not worth it. |
| MCP servers inside skills | Skills are procedural knowledge, not connectivity. |
| TypeScript/Node build step | Kills zero-dep portability. Shell + markdown only. |
| Hook-based enforcement | Hooks can't detect semantic context. Rules are self-enforced via reference docs. |
| BDD Given/When/Then ceremony | Too much overhead for solo dev projects |

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
| DOC-01 | Phase 4 | Pending |
| STRU-01 | Phase 1 | Complete |
| STRU-02 | Phase 4 | Pending |
| STRU-03 | Phase 2 | Complete |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-07 after roadmap creation*
