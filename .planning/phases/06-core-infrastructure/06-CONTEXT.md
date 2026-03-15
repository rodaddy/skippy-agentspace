# Phase 6: Core Infrastructure - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Package PAI's essential operating layer -- personas, LAWs, rules/style, and project templates -- as a portable, installable `core/` skill following the slim SKILL.md pattern. Commands are deferred to a later phase pending todo system research.

</domain>

<decisions>
## Implementation Decisions

### Directory Layout
- Maximally minimal top level: ONLY `SKILL.md` at `core/` root
- Everything else lives under `references/` with topic subdirectories
- SKILL.md uses topic sections pointing to subdirs (~50 lines), not a full file-by-file table
- Agents do a second lookup into the relevant subdir only when needed -- keeps initial context load minimal
- Structure:
  ```
  core/
    SKILL.md
    references/
      personas/
      laws/
      rules/
      templates/
  ```

### LAW Files
- Individual files per LAW: `law-01-never-assume.md`, `law-02-checkbox-questions.md`, etc.
- ALL LAWs must be hook-enforced -- if a LAW can't be hook-enforced, it should be adjusted or removed until it can
- No separate index file -- SKILL.md's topic section points to the `laws/` directory
- Individual files enable independent iteration on each LAW (adjust, remove, add)

### Persona Files
- Full persona prompt fragments -- each file is a self-contained injectable unit
- Content structure inspired by OpenClaw's soul.md pattern: personality, core values, behavioral boundaries, style rules, example responses, switching triggers
- PAI naming convention (not OpenClaw naming): `references/personas/skippy.md`, not `skippy-soul.md`
- Switching mechanism (`persona bob`) swaps which persona file gets injected

### user.md Concept
- user.md is a first-class core concept (inspired by OpenClaw's USER.md)
- Template lives in `core/references/templates/user.md.template` -- shows structure and prompts for what to fill in
- Actual user content stays external/private (never in repo)
- Agents know to look for user.md at a standard path

### CLAUDE.md Template
- Opinionated starter (~80-100 lines), not minimal scaffold
- Placeholders with defaults for stack preferences: `{package_manager: bun}`, `{python_runner: uv}`, etc. -- defaults to PAI preferences but clearly customizable
- Per-project persona selection via `{default_persona}` placeholder
- Cascade: project CLAUDE.md persona overrides global default persona
- Includes: LAW references, persona default, stack preferences, skills-first reminder, verification loop, key files table, corrections section

### Claude's Discretion
- Exact line counts per file (within the 150-line SKILL.md and 750-line file limits)
- How to extract content from existing PAI definitions (which files to read, how to restructure)
- Persona example response selection (which examples best illustrate each persona)
- Template placeholder syntax (curly braces, comments, or other convention)

</decisions>

<specifics>
## Specific Ideas

- OpenClaw's soul.md pattern: personality + core values + behavioral boundaries + example responses. Good structure for persona files. Research: https://github.com/aaronjmars/soul.md
- Existing personas defined in `~/.config/pai/Skills/CORE/SKILL.md` and `~/.config/pai-private/rules/style/communication-style.md` -- extract and restructure, don't start from scratch
- LAW definitions currently in `~/.claude/CLAUDE.md` -- extract each LAW into its own file with enforcement metadata
- Per-persona critical thinking styles already defined (Skippy: sarcasm, Bob: analysis, Clarisa: supportive concern, April: creative alternatives) -- preserve these in persona files

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/skippy/SKILL.md` (12 lines) -- reference model for slim SKILL.md pattern
- `skills/skippy/references/` -- 5 reference docs demonstrating the deep-doc pattern
- `CONVENTIONS.md` -- documents public/private boundary and upstream.json schema
- `upstreams/` -- directory-per-item extensibility pattern (apply same thinking to laws/)

### Established Patterns
- Slim entry point + deep references (proven in skippy)
- Frontmatter standard: name, description, metadata (version, author, source)
- Directory-as-registry: adding new items = creating new directory/file, no code changes
- Shell scripts + markdown only, no build step

### Integration Points
- `CLAUDE.md` Key Files table -- core/ needs a reference here
- `INDEX.md` -- auto-generated skill registry, needs core skill entry
- Installation flow (Phase 9-10) -- core/ contents get symlinked into `~/.claude/`

</code_context>

<deferred>
## Deferred Ideas

- **Command packaging (CORE-05)** -- Defer to a later phase. Many existing commands are LAW reinforcement for context degradation. Todo commands need research across GSD, PAUL, OpenClaw implementations first. Consider a single `/refresh` command vs individual reinforcement commands.
- **Todo system cherry-pick** -- Survey todo implementations across all upstream packages (GSD, PAUL, OpenClaw, etc.) and cherry-pick the best approach. Do this research before packaging add-todo/check-todos.
- **OpenClaw cascade resolution** -- Full cascade (global defaults -> agent overrides -> workspace overrides) is more sophisticated than needed for Phase 6. Revisit for Phase 9-10 install experience.
- **LAW enforcement gap analysis** -- LAWs 10-14 are currently "convention-enforced" (manual). User decision: all LAWs must be hook-enforced. Gap analysis needed to determine what hooks are required.

</deferred>

---

*Phase: 06-core-infrastructure*
*Context gathered: 2026-03-07*
