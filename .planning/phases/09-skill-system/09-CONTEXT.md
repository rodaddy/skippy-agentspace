# Phase 9: Skill System - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can selectively install individual skills or the full suite, and ~10 essential PAI skills are migrated into the portable format. Includes enhanced install.sh with selective flags, an AI-driven migration command, and INDEX.md evolution with categories and install status.

</domain>

<decisions>
## Implementation Decisions

### Skill Selection
- Primary criterion: daily driver frequency, then foundational chain, then portable value
- Hybrid discovery: AI scans ~/.config/pai/Skills/ and presents ranked candidates, user approves/rejects from their mental shortlist
- Duplicates flagged interactively during migration -- user picks which to keep/merge/drop
- Target count is a rough guide (~10-15), not a hard cap -- quality over count
- Unused duplicates cleaned up from the actual install during migration

### Migration Approach
- Migration tool is an AI command (markdown-based), not a shell script -- consistent with Phase 8 agent-driven operations decision
- PAI-specific features (persona references, LAW enforcement, hooks) stripped during migration with "PAI enhancements available" gap notes in SKILL.md
- Always dry-run first -- show file tree, SKILL.md preview, what gets stripped, then confirm before writing
- All skills flattened to standard layout: SKILL.md + references/ + commands/ + scripts/ -- consistency over preservation of source structure

### Install UX
- Flag style: positional args for skill names, --core and --all as special flags
  - `install.sh --core` installs core only
  - `install.sh skippy-dev` installs one skill
  - `install.sh skippy-dev homeassistant` installs multiple skills
  - `install.sh --all` installs everything
- No-arg behavior: show installed/available status table + usage help
- All skills are standalone -- no core dependency required. Maximum portability.
- uninstall.sh mirrors install.sh with selective uninstall (positional skill names, --all)

### INDEX.md Evolution
- 4 categories: core, workflow, utility, domain
- Badge-style install markers inline (e.g., `core [installed]`) -- no extra column
- Grouped by category with section headers (## Core, ## Workflow, etc.)
- Each category has its own table with Skill, Path, Commands columns

### Claude's Discretion
- Error handling strategy for install.sh (continue-on-error vs stop-on-first based on severity)
- INDEX.md sync trigger mechanism (on sync vs on install/uninstall)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tools/install.sh`: Dual-target installer (modern ~/.claude/skills/ vs legacy ~/.claude/commands/) with symlink support. Extend with --core, positional args, status display.
- `tools/uninstall.sh`: Clean symlink removal. Extend with selective uninstall.
- `tools/index-sync.sh`: Validates/regenerates INDEX.md from SKILL.md frontmatter. Extend with category grouping and install badge detection.
- `.claude-plugin/marketplace.json`: Plugin schema supports unlimited plugins (strict: false). Extend for newly migrated skills.
- `skills/core/SKILL.md` (116 lines) and `skills/skippy-dev/SKILL.md` (98 lines): Proven slim SKILL.md pattern under 150-line limit.

### Established Patterns
- Directory-per-skill under skills/ with mandatory SKILL.md + optional subdirectories
- YAML frontmatter schema: name, description, metadata (version, author, source)
- Slim entry points (<150 lines) with deep references in subdirectories
- Command specs as markdown with <objective>, <execution_context>, <process> structure
- Upstream tracking via upstreams/<name>/upstream.json

### Integration Points
- install.sh argument parsing (~line 25-50) for new flags
- INDEX.md structure for category grouping and badge markers
- marketplace.json plugins[] array for new skill plugin entries
- ~/.config/pai/Skills/ as source directory for migration scanning

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches. Key references:
- Phase 8's /skippy:update as model for AI-driven commands (markdown, not shell)
- Phase 5's decision that shell scripts handle validation only, AI handles operations
- Existing install.sh as the starting point for enhancement (not a rewrite)

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 09-skill-system*
*Context gathered: 2026-03-07*
