# Phase 13: GSD Pattern Absorption - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Absorb GSD's core execution patterns as standalone skippy reference docs and update reconcile to work against skippy's own format spec. After this phase, skippy IS the framework -- no GSD/PAUL/OMC runtime dependency needed. GSD remains credited as a source, not required as a dependency.

</domain>

<decisions>
## Implementation Decisions

### Reference doc structure (4 docs, not 5)
- Merge where content naturally fits rather than creating 5 separate docs
- Final doc set:
  - `phased-execution.md` -- phase discovery, wave-based parallel spawning, agent coordination, result aggregation (absorbs wave-parallelism)
  - `state-tracking.md` -- STATE.md lifecycle, progress tracking format, position markers, session handoff (absorbs from gsd-dependency-map.md STATE section)
  - `plan-structure.md` -- PLAN.md format spec, task block structure, verification criteria, frontmatter fields (absorbs task-anatomy.md content)
  - `checkpoints.md` -- checkpoint types (human-verify, human-decision, autonomous), transition rules, deviation handling (4 rules), state during waits
- Delete `task-anatomy.md` after its content merges into `plan-structure.md`
- Delete `gsd-dependency-map.md` after its content is extracted into the 4 new docs

### Absorption depth
- Protocol spec + key agent prompting patterns (~100-150 lines per doc)
- Deep reference files can be added later for edge cases -- follows the slim-core-with-deep-refs architecture
- NOT a full pattern library -- leave detailed edge cases and error recovery for future deep refs

### Task format evolution
- Evolve GSD's XML `<task>` blocks to markdown headers + YAML fields
- Format: `## Task N: Title` followed by `files:`, `action:`, `verify:`, `done:` fields
- Skippy owns this format spec -- it's documented in `plan-structure.md`

### Standalone reconcile
- `/skippy:reconcile` works against skippy's own format spec only
- Reconcile command updated in this phase (not deferred) to parse the new markdown+YAML task format
- Format spec defined in skippy's reference docs is the canonical source

### State operations (hybrid approach)
- Reference docs describe the protocol (AI-native) -- Claude reads/writes .planning/ files directly
- Commands needing reliable parsing (reconcile) get a small bun-based parser (e.g., `tools/lib/skippy-state.ts`)
- No python -- bun is already a prerequisite (hooks use it)
- Update PROJECT.md constraint from "shell scripts + markdown only" to "shell scripts + markdown for tools, bun/TypeScript for structured data operations"

### GSD attribution
- Source credit, not dependency: each doc gets a `Source: Adapted from GSD execute-phase.md` footer
- No "requires GSD" language anywhere in distributed content
- GSD credited like an academic citation -- where it came from, not what you need installed

### Language cleanup scope
- Scan skills/, tools/, and commands/ for GSD dependency language (ABSORB-03)
- CLAUDE.md and .planning/ keep historical references -- project internals, not distributed content
- Skippy doesn't prevent coexistence with GSD -- absorption is about independence, not exclusion
- Configurable by user -- others may want to keep GSD alongside skippy

### Claude's Discretion
- Exact compression ratio per doc (100-150 line target is a guideline, not a hard limit)
- Which GSD prompting patterns are "key" enough to include vs. defer to deep refs
- Internal structure of each reference doc (sections, headers, formatting)
- How to handle the gsd-dependency-map.md extraction (which content goes where)
- Bun CLI scope -- minimal parser vs. more capable state tool

</decisions>

<specifics>
## Specific Ideas

- "On updates/upgrade to GSD, we will have a new one to refactor in anyway" -- the absorption is a repeatable process, not a one-time migration. `/skippy:upgrade` would re-run absorption when GSD changes upstream.
- Task format preview that resonated: `## Task 1: Create auth middleware` with `files:`, `action:`, `verify:`, `done:` YAML fields below it.
- "I know what I want, but I'm not gonna force it on others" -- skippy should be opinionated for the owner but permissive for adopters.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tools/lib/common.sh`: Shared shell library (skippy_pass, skippy_warn, skippy_fail, skippy_summary) -- use for any new shell scripts
- `skills/skippy-dev/references/`: 11 existing reference docs, established format (50-100 lines, structured sections)
- `skills/skippy-dev/commands/reconcile.md`: Current reconcile command -- needs update to parse new format
- `skills/skippy-dev/references/verification-loops.md`: Already covers post-implementation verification -- don't duplicate
- `skills/skippy-dev/references/state-consistency.md`: Already covers cross-file alignment -- complement, don't overlap

### Established Patterns
- Reference doc format: Header with purpose + source, When/Where section, Core protocol, Integration points
- Slim core pattern: SKILL.md <150 lines, detail in references/
- Commands are markdown (AI-driven), not shell scripts -- except where structured data parsing needs bun

### Integration Points
- `skills/skippy-dev/SKILL.md` -- may need updates to reference new docs
- `CONVENTIONS.md` -- upstream registry tracks GSD as source
- `PROJECT.md` -- stack constraint needs updating (shell + bun)
- `prereqs.sh` -- already checks for bun (no change needed)

</code_context>

<deferred>
## Deferred Ideas

- Bun-based state CLI could grow into a general `skippy-tools` equivalent -- evaluate after Phase 13 execution
- Deep reference files for edge cases in each pattern -- add as needed, don't pre-create
- Migration tool for existing .planning/ dirs using XML task format -- only if someone actually needs it

</deferred>

---

*Phase: 13-gsd-pattern-absorption*
*Context gathered: 2026-03-08*
