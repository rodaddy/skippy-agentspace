# Changelog

All notable changes to skippy-agentspace are documented here.
## [1.3.0] - 2026-04-06

### What's New

**Cognitive Tiering (OB Dreaming)**
Open Brain now has a memory lifecycle system. Every entry gets a tier -- hot, warm, or cold -- based on how often it's accessed. Hot entries get boosted in search results (+0.3 RRF), cold entries get penalized (-0.2). This means the stuff you use most surfaces faster, and stale knowledge fades naturally.

- Use `set_tier` to manually promote important entries to hot
- Use `tier` param on `search_brain`, `search_all`, or `list_recent` to filter (e.g., show only hot entries)
- Access tracking logs every search hit to `entry_access_log` for frequency/recency analysis
- Nightly dream cycle (guided by Skippy at 3am) promotes/demotes/consolidates entries

**15 New Patterns from 5 Upstream Sources**
Re-audited GSD v1.34.2, OMC v4.10.2, gstack v0.15.13, PAUL v1.2, and superpowers v5.0.7. All 15 extracted patterns enrich existing abilities -- no new abilities needed (the 11-ability taxonomy holds stable).

### Added
- 4 new reference docs: `gates-taxonomy.md`, `sealed-eval.md`, `context-degradation.md`, `eval-integrity.md`
- Brain skill v0.3.0: `set_tier` tool + `tier` filter param on search/list (12 -> 13 tools)
- Open Brain upstream.json synced to cognitive tiering release
- 5 upstream.json files updated with current SHAs

### Fixed
- Capture-session v0.2.0: namespace resolution on all OB write calls (was missing, could write to wrong namespace)
- CLAUDE.md: OMC URL corrected to `Yeachan-Heo/oh-my-claudecode`

### Enriched
- `verification-loops.md` +5 patterns (diagnostic routing, evidence-before-claims, stall detection, audit-to-fix, DX boomerang)
- `audit-swarm.md` +3 patterns (adaptive gating, anti-slop mode, depth tiers)
- `plan-structure.md` +1 (coherence check)
- `ambiguity-scoring.md` +1 (3-point injection)
- `session-persistence.md` +1 (worktree-per-issue)

### How to Use the New Stuff

**Set an entry's tier:**
```bash
mcp2cli open-brain set_tier --params '{"id":"<entry-uuid>","table":"thoughts","tier":"hot"}'
```

**Search only hot entries:**
```bash
mcp2cli open-brain search_brain --params '{"query":"king capital architecture","tier":"hot"}'
```

**List recent cold entries (candidates for cleanup):**
```bash
mcp2cli open-brain list_recent --params '{"tier":"cold","days":30}'
```

**Check what's tracked:**
The `entry_access_log` table records every search hit with timestamp, query text, and context. This feeds the nightly dream cycle scoring.


## [1.2.0] - 2026-03-22

### Added
- 103 structural assertions across 22 categories (`evals/structural/runner.sh`)
- Behavioral eval suites for install experience (16 assertions) and repo quality (12 assertions)
- CI job runs structural evals on every push/PR
- VERSION file for semantic versioning
- GLOSSARY.md for ubiquitous language
- 8 new skills in marketplace.json (brain, capture-session, gh-review, prd, prd-to-issues, session-handoff, session-start, ubiquitous-language)
- gstack and superpowers upstream registrations
- Quick Start section in CLAUDE.md

### Fixed
- uninstall.sh: now removes copied directories, not just symlinks
- uninstall.sh: fallback function matches install.sh behavior
- uninstall.sh: interactive read guarded with terminal check for CI/automation
- uninstall.sh: shellcheck error (local outside function)
- install.sh: trap handler for cleanup of temporary backup dirs
- install.sh: backup naming collision (added PID suffix)
- install.sh: error messages now suggest available skills
- install.sh: dead code removed (unused install_skill_copy, COPY_MODE)

### Changed
- Eval runner split into modular category files (LAW 9 compliance)
- CLAUDE.md file tree updated to reflect all 24 skills
- INDEX.md regenerated with full skill inventory
- planner.md and researcher.md agents: added complexity: field

### Enriched
- trace SKILL.md: example output + reading guide (+38 lines)
- vaultwarden SKILL.md: 3 new gotchas + service patterns (+18 lines)
- correct SKILL.md: For Agents section (+13 lines)
- 3 SKILL.md files: added metadata blocks (prd, prd-to-issues, ubiquitous-language)

## [1.1.0] - 2026-03-08

### Added
- Portable PAI: 12 skills, upstream tracking, bootstrap installer
- Shared shell library (tools/lib/common.sh) with skippy_* helpers
- .gitattributes with export-ignore entries

## [1.0.0] - 2026-03-07

### Added
- Initial release: spec, packaging, commands, documentation
- 16 phases planned, core framework established
