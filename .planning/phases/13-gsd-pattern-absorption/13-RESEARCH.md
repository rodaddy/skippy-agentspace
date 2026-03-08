# Phase 13: GSD Pattern Absorption - Research

**Researched:** 2026-03-08
**Domain:** GSD workflow pattern extraction and standalone reference doc authoring
**Confidence:** HIGH

## Summary

Phase 13 absorbs GSD's core execution patterns (phased execution, state tracking, plan structure, checkpoints) from three large GSD workflow files (~1,700 lines total) into 4 standalone skippy reference docs (~100-150 lines each). The absorption also requires updating the reconcile command to parse skippy's own markdown+YAML task format instead of GSD's XML `<task>` blocks, removing GSD dependency language from ~40 occurrences across 7 reference docs + SKILL.md, deleting 2 files whose content migrates into the new docs, and updating PROJECT.md's constraint to allow bun/TypeScript.

The core challenge is compression without losing essential prompting patterns. GSD's execute-phase.md (460 lines) and execute-plan.md (450 lines) contain interleaved protocol, agent prompts, deviation rules, and error handling. The decision to target ~100-150 lines per doc (matching existing reference doc sizes of 54-99 lines) means roughly 85% compression -- the art is knowing which 15% to keep.

**Primary recommendation:** Write the 4 new reference docs first, then update reconcile to parse the new format, then do the language cleanup pass, then delete the superseded files. Order matters because the new docs define the format spec that reconcile must parse.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- 4 reference docs (not 5): phased-execution.md, state-tracking.md, plan-structure.md, checkpoints.md
- Wave-parallelism folds into phased-execution.md
- task-anatomy.md content merges into plan-structure.md then gets deleted
- gsd-dependency-map.md content extracted into new docs then gets deleted
- XML task blocks evolve to markdown headers + YAML fields
- Hybrid state ops: AI-native for refs, bun CLI for commands needing parsing
- Protocol + key prompts depth (~100-150 lines per doc)
- Source credit footers, not dependency language
- reconcile.md updated in this phase to parse new skippy format
- PROJECT.md constraint updated to allow bun/TypeScript

### Claude's Discretion
- Exact compression ratio per doc (100-150 line target is a guideline, not a hard limit)
- Which GSD prompting patterns are "key" enough to include vs. defer to deep refs
- Internal structure of each reference doc (sections, headers, formatting)
- How to handle the gsd-dependency-map.md extraction (which content goes where)
- Bun CLI scope -- minimal parser vs. more capable state tool

### Deferred Ideas (OUT OF SCOPE)
- Bun-based state CLI could grow into a general skippy-tools equivalent -- evaluate after Phase 13
- Deep reference files for edge cases in each pattern -- add as needed, don't pre-create
- Migration tool for existing .planning/ dirs using XML task format -- only if someone actually needs it
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ABSORB-01 | Reference docs absorb GSD phased execution pattern (plan -> execute -> verify cycle) | Mapped to `phased-execution.md` -- source content in execute-phase.md (460 lines), covers wave discovery, agent spawning, result aggregation, failure handling, phase verification |
| ABSORB-02 | Reference docs absorb GSD state tracking pattern (STATE.md, progress, position) | Mapped to `state-tracking.md` -- source content in state.md template (177 lines) + execute-plan.md state update steps + gsd-dependency-map.md STATE section |
| ABSORB-03 | Reference docs absorb GSD plan structure (frontmatter, tasks, verification criteria) | Mapped to `plan-structure.md` -- source content in execute-plan.md task format + summary.md template (249 lines) + task-anatomy.md (67 lines, absorbed entirely) |
| ABSORB-04 | Reference docs absorb GSD wave-based parallel execution and checkpoint handling | Wave parallelism folds into `phased-execution.md`; checkpoint handling gets own `checkpoints.md` -- source in checkpoints.md (777 lines) |
| ABSORB-05 | Reference docs absorb GSD verification loops (VERIFICATION.md, must_haves, gap closure) | Already covered by existing `verification-loops.md` (92 lines) -- only needs language update to remove GSD dependency framing. No new doc needed. |
| ABSORB-06 | All "requires GSD" mentions removed from docs and commands | 40 occurrences across 7 reference docs + SKILL.md identified via grep. Zero in tools/. See Language Cleanup section below. |
| ABSORB-07 | `/skippy:reconcile` works against any `.planning/` structure, not just GSD's | Reconcile command (125 lines) needs Step 3 rewrite: XML task extraction becomes markdown header + YAML field parsing. New format spec defined in plan-structure.md. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown | N/A | Reference doc format | Established pattern across all 11 existing reference docs |
| YAML frontmatter | N/A | Plan/summary metadata | Already used in all .planning/ artifacts |
| bun | 1.x (already installed) | TypeScript runtime for state parser | Already a prereq (hooks depend on it), checked by prereqs.sh |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TypeScript | bundled with bun | Type-safe state parsing | For `tools/lib/skippy-state.ts` -- reconcile parser |
| gray-matter | latest | YAML frontmatter parsing | If needed by skippy-state.ts for reliable frontmatter extraction |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bun + TypeScript | Pure shell (grep/sed/awk) | Shell parsing of YAML is fragile and error-prone. Bun is already a dependency. TypeScript wins for structured data. |
| gray-matter | Manual regex parsing | gray-matter handles edge cases (multiline strings, arrays). But adds a dependency. Manual regex may suffice for the simple frontmatter used here. |

**Installation:**
```bash
# bun already installed (prereqs.sh checks)
# gray-matter only if needed:
cd tools/lib && bun add gray-matter
```

**Recommendation:** Start with bun's built-in text processing (string split on `---` delimiters, then YAML.parse if bun supports it, or a 20-line manual parser). Only add gray-matter if edge cases demand it.

## Architecture Patterns

### Recommended File Structure
```
skills/skippy-dev/
  references/
    phased-execution.md     # NEW -- absorbs execute-phase.md + wave parallelism
    state-tracking.md        # NEW -- absorbs STATE.md lifecycle + progress tracking
    plan-structure.md        # NEW -- absorbs plan format + task anatomy + summary format
    checkpoints.md           # NEW -- absorbs checkpoint types + deviation rules
    task-anatomy.md          # DELETE after content merges into plan-structure.md
    gsd-dependency-map.md    # DELETE after content extracted into 4 new docs
    reconciliation.md        # UPDATE -- language cleanup only
    state-consistency.md     # UPDATE -- language cleanup only
    verification-loops.md    # UPDATE -- language cleanup only
    context-brackets.md      # UPDATE -- language cleanup only
    plan-boundaries.md       # UPDATE -- language cleanup only
    model-routing.md         # UPDATE -- language cleanup only
    session-persistence.md   # UPDATE -- language cleanup only
    structured-deliberation.md # UPDATE -- language cleanup only
    skill-extraction.md      # NO CHANGE (no GSD language)
  commands/
    reconcile.md             # UPDATE -- parse new markdown+YAML task format
  SKILL.md                   # UPDATE -- remove GSD dependency language, reference new docs
tools/
  lib/
    skippy-state.ts          # NEW -- bun-based parser for reconcile's structured data needs
.planning/
  PROJECT.md                 # UPDATE -- constraint change (allow bun/TypeScript)
```

### Pattern 1: Reference Doc Format (Established)
**What:** Consistent structure across all reference docs
**When to use:** Every new reference doc
**Example:**
```markdown
# [Title] -- [Subtitle]

[Opening line: what this is and what it's adapted from]

## [Core Content Sections]

[Protocol, rules, patterns -- the meat of the doc]

## Integration Points

- **Skippy reconcile:** [how this connects]
- **Plan creation:** [how this connects]
- **Phase execution:** [how this connects]

## When to Apply

- [Trigger condition 1]
- [Trigger condition 2]
- NOT for [anti-pattern]

---
*Source: Adapted from GSD execute-phase.md*
*Last reviewed: 2026-03-08*
```

### Pattern 2: Source Credit Footer (New for Absorbed Docs)
**What:** Attribution without dependency language
**When to use:** All 4 new reference docs
**Example:**
```markdown
---
*Source: Adapted from GSD execute-phase.md and execute-plan.md*
*Last reviewed: 2026-03-08*
```

Good: "Source: Adapted from GSD execute-phase.md"
Bad: "Requires GSD framework to be installed"
Bad: "Works with GSD's execute-phase workflow"

### Pattern 3: Task Format Evolution (XML to Markdown+YAML)
**What:** Skippy's own task format spec replacing GSD's XML blocks
**When to use:** Defined in plan-structure.md, parsed by reconcile

**GSD (old):**
```xml
<task type="auto">
  <name>Create auth middleware</name>
  <files>src/middleware/auth.ts</files>
  <action>Create JWT validation middleware</action>
  <verify>bun test tests/auth.test.ts</verify>
  <done>Protected routes return 401 without valid token</done>
</task>
```

**Skippy (new):**
```markdown
## Task 1: Create auth middleware
- files: `src/middleware/auth.ts`
- action: Create JWT validation middleware
- verify: `bun test tests/auth.test.ts`
- done: Protected routes return 401 without valid token
```

### Anti-Patterns to Avoid
- **Dependency language in reference docs:** Never "requires GSD" or "when GSD executes." Use "when executing a phase" or "during plan execution."
- **Duplicating existing reference docs:** verification-loops.md already covers post-implementation verification. The new docs complement, not overlap.
- **Over-compressing:** Losing the key agent prompting patterns that make GSD effective. The deviation rules (4 rules table), checkpoint types (3 types with percentages), and wave execution protocol are high-value content that must survive compression.
- **Creating a bun CLI that's too large:** The `skippy-state.ts` parser should be minimal -- just what reconcile needs for YAML frontmatter + markdown task extraction. Not a general-purpose state management tool (that's deferred).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter parsing | Regex-based shell parser | bun TypeScript with string split on `---` | YAML has edge cases (arrays, multiline) that break shell regex |
| Markdown heading extraction | grep + sed pipeline | bun TypeScript with regex on `## Task \d+:` | Structured parsing is more reliable and testable |
| Task status classification | Shell case statements | TypeScript enum + match logic | 4 status types (DONE/MODIFIED/SKIPPED/ADDED) with evidence gathering |

**Key insight:** The reconcile command is AI-driven (markdown command file), but its parsing needs are structured enough to warrant a small TypeScript helper. The hybrid approach -- AI reads the command intent, delegates parsing to `skippy-state.ts` -- gives reliability without ceremony.

## Common Pitfalls

### Pitfall 1: Losing Critical Prompting Patterns During Compression
**What goes wrong:** Reference docs become protocol summaries that miss the agent-facing prompts that make GSD effective.
**Why it happens:** Treating compression as "remove details" instead of "distill patterns."
**How to avoid:** Identify the 5-8 highest-value prompting patterns per source file. Include them verbatim or near-verbatim. Cut the scaffolding (boilerplate, examples of obvious things), keep the non-obvious patterns.
**Warning signs:** A reference doc that reads like a table of contents instead of actionable guidance.

**Highest-value patterns to preserve:**
- execute-phase.md: Wave grouping protocol, spot-check claims before reporting, context efficiency principle ("orchestrator stays lean ~10-15%")
- execute-plan.md: Deviation rules (4-rule table with priority), task commit protocol, checkpoint protocol (3 types with percentages 90/9/1)
- checkpoints.md: "If Claude can run it, Claude runs it" golden rule, auth gate pattern (try -> fail -> checkpoint -> auth -> retry), anti-patterns (asking user to do automatable work)
- state.md template: Size constraint (<100 lines), tier concept, pruning rules

### Pitfall 2: Reconcile Update Breaking Backward Compatibility
**What goes wrong:** Updated reconcile can't parse existing .planning/ directories that use the old XML format.
**Why it happens:** Hard-replacing XML parsing with markdown parsing.
**How to avoid:** The CONTEXT.md defers migration tooling. The reconcile command should parse skippy's format spec. Old XML projects can use old reconcile. This is absorption, not migration.
**Warning signs:** Reconcile command tries to handle both XML and markdown formats (scope creep).

### Pitfall 3: Overlapping With Existing Reference Docs
**What goes wrong:** New docs duplicate content already in verification-loops.md, state-consistency.md, or reconciliation.md.
**Why it happens:** GSD's source files contain content that was already cherry-picked into skippy in earlier phases.
**How to avoid:** Map each section of each new doc against existing docs. If content exists, reference it ("see verification-loops.md") instead of repeating it.
**Warning signs:** Same concept explained in two reference docs.

**Overlap map (verified by reading all existing docs):**
| New Doc | Overlaps With | Resolution |
|---------|--------------|------------|
| phased-execution.md | verification-loops.md (plan-level cycling) | Reference it: "see verification-loops.md for cycling protocol" |
| state-tracking.md | state-consistency.md (alignment checks) | Reference it: "see state-consistency.md for cross-file alignment" |
| state-tracking.md | session-persistence.md (tier concept) | Reference it: "see session-persistence.md for tier loading strategy" |
| plan-structure.md | reconciliation.md (AC verification) | Reference it: "see reconciliation.md for plan-vs-actual comparison" |
| plan-structure.md | plan-boundaries.md (scope protection) | Reference it: "see plan-boundaries.md for scope protection" |
| checkpoints.md | verification-loops.md (done criteria) | Reference it: "task verify/done fields defined in plan-structure.md" |

### Pitfall 4: GSD Language Cleanup Missing Occurrences
**What goes wrong:** After cleanup, grep still finds "GSD" or "gsd-executor" language in distributed content.
**Why it happens:** Incomplete grep patterns, or missing files from the scan.
**How to avoid:** Run verification grep after cleanup. The scan identified 40 occurrences across 7 files. Verify zero occurrences after changes (excluding historical/attribution uses).
**Warning signs:** Post-cleanup grep returns hits in distributed content (skills/, commands/).

### Pitfall 5: skippy-state.ts Scope Creep
**What goes wrong:** The bun parser grows into a full state management tool.
**Why it happens:** It's tempting to add "just one more feature" when you have a TypeScript entry point.
**How to avoid:** Limit to 3 functions: `parseFrontmatter()`, `extractTasks()`, `classifyTaskStatus()`. Everything else is AI-native (the reconcile command's markdown tells the agent what to do).
**Warning signs:** File exceeds 100 lines, or exports more than 3-4 functions.

## Code Examples

### New Task Format (plan-structure.md will define this)
```markdown
---
phase: 13-gsd-pattern-absorption
plan: 01
wave: 1
autonomous: true
files_modified:
  - skills/skippy-dev/references/phased-execution.md
  - skills/skippy-dev/references/state-tracking.md
requirements:
  - ABSORB-01
  - ABSORB-02
must_haves:
  truths:
    - "phased-execution.md covers wave-based parallel execution"
    - "state-tracking.md covers STATE.md lifecycle"
---

# Phase 13 Plan 01: Core Reference Docs

## Objective
Create phased-execution.md and state-tracking.md reference docs.

## Boundaries
### DO NOT CHANGE
- verification-loops.md (already complete)
- state-consistency.md (complement, don't overlap)

## Task 1: Create phased-execution.md
- files: `skills/skippy-dev/references/phased-execution.md`
- action: Absorb execute-phase.md wave discovery, agent spawning, result aggregation, failure handling into ~120-line reference doc
- verify: File exists, follows established reference doc format, no GSD dependency language
- done: phased-execution.md covers plan -> execute -> verify cycle with wave parallelism

## Task 2: Create state-tracking.md
- files: `skills/skippy-dev/references/state-tracking.md`
- action: Absorb STATE.md lifecycle, progress tracking, position markers, session handoff from state.md template and execute-plan.md state update steps
- verify: File exists, follows established reference doc format, no GSD dependency language
- done: state-tracking.md covers STATE.md creation, reading, writing, and size constraints
```

### Source Credit Footer Pattern
```markdown
---
*Source: Adapted from GSD execute-phase.md and execute-plan.md*
*Last reviewed: 2026-03-08*
```

### Language Replacement Examples
```
BEFORE: "Additive rules that sharpen GSD's planning and execution"
AFTER:  "Additive rules that sharpen planning and execution workflows"

BEFORE: "When spawning a gsd-planner agent, add:"
AFTER:  "When spawning a planner agent, add:"

BEFORE: "GSD agents inherit these rules. A gsd-executor in DEEP bracket should:"
AFTER:  "Executor agents inherit these rules. An executor in DEEP bracket should:"

BEFORE: "After `/gsd:execute-phase` completes"
AFTER:  "After phase execution completes"

BEFORE: "| `/skippy:reconcile` | **Heavy** -- reads PLAN.md, SUMMARY.md | Core function is comparing GSD artifacts |"
AFTER:  [DELETE -- this entire file (gsd-dependency-map.md) is being absorbed into the 4 new docs]
```

### Minimal skippy-state.ts Structure
```typescript
#!/usr/bin/env bun

// tools/lib/skippy-state.ts
// Structured data parser for reconcile command

interface Task {
  number: number;
  name: string;
  files: string[];
  action: string;
  verify: string;
  done: string;
}

interface Frontmatter {
  [key: string]: unknown;
}

export function parseFrontmatter(content: string): Frontmatter {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  // Parse YAML-like key: value pairs
  // ...
}

export function extractTasks(content: string): Task[] {
  // Match ## Task N: Title pattern
  const taskPattern = /^## Task (\d+): (.+)$/gm;
  // Extract fields below each heading
  // ...
}

export function classifyTaskStatus(
  planned: Task[],
  summary: string
): Array<{ task: Task; status: 'DONE' | 'MODIFIED' | 'SKIPPED' | 'ADDED' }> {
  // Compare planned tasks against summary evidence
  // ...
}

// CLI entry point when called directly
if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  // parse-frontmatter <file>
  // extract-tasks <file>
  // classify-tasks <plan-file> <summary-file>
}
```

## GSD Source Content Mapping

Detailed mapping of what goes where from each GSD source file.

### execute-phase.md (460 lines) -> phased-execution.md (~120-140 lines)

| GSD Section | Keep/Cut | Destination | Rationale |
|-------------|----------|-------------|-----------|
| Initialize (gsd-tools.cjs calls) | CUT | N/A | Tool-specific, not pattern |
| Handle branching | KEEP (condensed) | phased-execution.md | Branch strategy is a pattern |
| Discover and group plans | KEEP | phased-execution.md | Wave grouping is core |
| Execute waves (spawning, waiting, reporting) | KEEP | phased-execution.md | Core orchestration pattern |
| Checkpoint handling (between waves) | REFERENCE | "see checkpoints.md" | Avoid duplication |
| Aggregate results | KEEP (condensed) | phased-execution.md | Result reporting pattern |
| Close parent artifacts (decimal phases) | CUT | N/A | GSD-specific edge case |
| Verify phase goal | KEEP (condensed) | phased-execution.md | Phase verification trigger |
| Update roadmap | CUT | N/A | Tool-specific state updates |
| Offer next / auto-advance | CUT | N/A | UI/UX detail, not pattern |
| Context efficiency note | KEEP | phased-execution.md | Key architectural principle |
| Failure handling (classifyHandoffIfNeeded) | CUT | N/A | Claude Code bug workaround |
| Resumption | KEEP (condensed) | phased-execution.md | Resumability is a pattern |

### execute-plan.md (450 lines) -> plan-structure.md (~120 lines) + checkpoints.md (~130 lines)

| GSD Section | Keep/Cut | Destination | Rationale |
|-------------|----------|-------------|-----------|
| Init context | CUT | N/A | Tool-specific |
| Identify plan / parse segments | KEEP (condensed) | plan-structure.md | Plan discovery pattern |
| Agent tracking | CUT | N/A | GSD infra detail |
| Load prompt | KEEP (condensed) | plan-structure.md | Plan-as-prompt pattern |
| Execute (deviation rules) | KEEP | plan-structure.md or checkpoints.md | 4-rule table is high value |
| Auth gates | KEEP | checkpoints.md | Auth gate pattern is key |
| Deviation documentation | KEEP (condensed) | plan-structure.md | Summary deviation format |
| TDD execution | REFERENCE | "see verification-loops.md" | Already covered |
| Task commit protocol | KEEP (condensed) | plan-structure.md | Commit convention |
| Checkpoint protocol | KEEP | checkpoints.md | Core checkpoint pattern |
| Checkpoint return for orchestrator | CUT | N/A | GSD agent infra |
| Create summary | KEEP (condensed) | plan-structure.md | Summary format spec |
| Update state / roadmap | REFERENCE | "see state-tracking.md" | Cross-reference |

### checkpoints.md (777 lines) -> checkpoints.md (~130 lines)

| GSD Section | Keep/Cut | Destination | Rationale |
|-------------|----------|-------------|-----------|
| Overview + golden rules | KEEP | checkpoints.md | Core philosophy |
| 3 checkpoint types (90/9/1) | KEEP (condensed) | checkpoints.md | Type definitions |
| Execution protocol (stop/display/wait/verify/resume) | KEEP | checkpoints.md | Core protocol |
| Auth gates pattern | KEEP (condensed) | checkpoints.md | Key pattern |
| Automation reference (service CLI table) | CUT | N/A | Too specific, tool-dependent |
| Dev server automation | CUT | N/A | Too specific |
| CLI installation handling | CUT | N/A | Too specific |
| Anti-patterns (10 examples) | KEEP (2-3 best) | checkpoints.md | High value, but condensed |
| Writing guidelines | KEEP (condensed) | checkpoints.md | Placement rules |

### state.md template (177 lines) -> state-tracking.md (~100-120 lines)

| GSD Section | Keep/Cut | Destination | Rationale |
|-------------|----------|-------------|-----------|
| File template | KEEP (condensed) | state-tracking.md | Format spec |
| Purpose (problem/solution) | KEEP | state-tracking.md | Why STATE.md exists |
| Lifecycle (creation/reading/writing) | KEEP | state-tracking.md | Core lifecycle |
| Section descriptions | KEEP (condensed) | state-tracking.md | What each section does |
| Size constraint (<100 lines) | KEEP | state-tracking.md | Critical rule |

## GSD Language Cleanup Inventory

### Files Requiring Language Updates (ABSORB-06)

| File | Occurrences | Type of Change |
|------|-------------|----------------|
| `skills/skippy-dev/SKILL.md` | 3 | "GSD's planning" -> "planning workflows"; "GSD agents" -> "agents"; gsd-dependency-map reference removed |
| `skills/skippy-dev/references/task-anatomy.md` | 3 | "GSD plan" -> "plan"; "gsd-planner" -> "planner" -- then DELETE (merges into plan-structure.md) |
| `skills/skippy-dev/references/gsd-dependency-map.md` | 30+ | DELETE entire file (content absorbed into 4 new docs) |
| `skills/skippy-dev/references/state-consistency.md` | 2 | "GSD maintains state" -> "State is maintained"; remove `/gsd:remove-phase` reference |
| `skills/skippy-dev/references/reconciliation.md` | 2 | "After `/gsd:execute-phase`" -> "After phase execution"; "Before `/gsd:verify-work`" -> "Before verification" |
| `skills/skippy-dev/references/model-routing.md` | 7 | "GSD" -> "workflow framework" or remove; "gsd-executor" -> "executor" |
| `skills/skippy-dev/references/context-brackets.md` | 2 | "GSD agents" -> "Executor agents"; remove "gsd-executor" |
| `skills/skippy-dev/references/plan-boundaries.md` | 3 | "GSD plan" -> "plan"; "gsd-planner" -> "planner"; "gsd-executor" -> "executor" |
| `skills/skippy-dev/references/verification-loops.md` | 6 | "GSD" source reference -> "phased execution framework"; "gsd:verify-work" -> "verify-work" |
| `skills/skippy-dev/references/session-persistence.md` | 8 | "GSD" -> "phased execution" or remove; keep source attribution footer |
| `skills/skippy-dev/references/structured-deliberation.md` | 5 | "GSD plan-check" -> "plan-check"; remove GSD from source references |
| `skills/skippy-dev/commands/reconcile.md` | 2 (description + step 3) | "GSD phase" -> "phase"; XML task extraction -> markdown task extraction |
| `.planning/PROJECT.md` | 1 | Stack constraint update (add bun/TypeScript allowance) |

### Files NOT Requiring Changes (Exclusions)
- `.planning/` files (STATE.md, ROADMAP.md, etc.) -- project internals, historical context
- `CLAUDE.md` -- project description, not distributed content
- `CONVENTIONS.md` -- upstream registry is historical attribution
- `docs/` -- analysis docs are historical records
- `upstreams/` -- tracking data, not distributed

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification + grep validation |
| Config file | None -- Phase 12 (bats-core) is pending |
| Quick run command | `grep -r "requires GSD\|gsd-tools\|get-shit-done\|gsd-executor\|gsd-verifier\|gsd-planner" skills/ --include="*.md" -l` |
| Full suite command | `grep -rn "GSD" skills/ --include="*.md" \| grep -v "Source:\|Adapted from\|Sources:"` (finds non-attribution GSD mentions) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ABSORB-01 | phased-execution.md exists with correct content | smoke | `test -f skills/skippy-dev/references/phased-execution.md && wc -l < skills/skippy-dev/references/phased-execution.md` | Wave 0 |
| ABSORB-02 | state-tracking.md exists with correct content | smoke | `test -f skills/skippy-dev/references/state-tracking.md && wc -l < skills/skippy-dev/references/state-tracking.md` | Wave 0 |
| ABSORB-03 | plan-structure.md exists with task format spec | smoke | `test -f skills/skippy-dev/references/plan-structure.md && grep -q "## Task" skills/skippy-dev/references/plan-structure.md` | Wave 0 |
| ABSORB-04 | checkpoints.md exists with checkpoint types | smoke | `test -f skills/skippy-dev/references/checkpoints.md && grep -q "human-verify" skills/skippy-dev/references/checkpoints.md` | Wave 0 |
| ABSORB-05 | verification-loops.md updated (no GSD dependency language) | grep | `! grep -q "gsd-executor\|gsd:verify-work" skills/skippy-dev/references/verification-loops.md` | Existing file |
| ABSORB-06 | No GSD dependency language in distributed content | grep | `! grep -rn "requires GSD\|gsd-tools\|gsd-executor\|gsd-verifier\|gsd-planner" skills/ --include="*.md"` | N/A |
| ABSORB-07 | reconcile.md parses markdown task format | smoke | `grep -q "## Task" skills/skippy-dev/commands/reconcile.md && ! grep -q "<task" skills/skippy-dev/commands/reconcile.md` | Existing file |

### Sampling Rate
- **Per task commit:** Quick grep for GSD dependency language
- **Per wave merge:** Full grep scan across all skills/
- **Phase gate:** All 7 validation commands above pass

### Wave 0 Gaps
- [ ] No test framework yet (Phase 12 pending) -- validation is grep-based for this phase
- [ ] `tools/lib/skippy-state.ts` needs manual verification (no bats tests exist)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Parasitic on GSD (ride unchanged) | Standalone (absorb patterns, credit sources) | Phase 13 (v1.2) | Skippy IS the framework, no runtime GSD dependency |
| XML `<task>` blocks in plans | Markdown `## Task N: Title` + YAML fields | Phase 13 (v1.2) | Standard markdown, readable, parseable without XML parser |
| Shell scripts + markdown only | Shell + markdown + bun/TypeScript for structured parsing | Phase 13 (v1.2) | Better reliability for YAML/markdown parsing |
| GSD dependency language throughout | Source attribution footers only | Phase 13 (v1.2) | Standalone positioning, no "requires GSD" |

**Deprecated/outdated after Phase 13:**
- `gsd-dependency-map.md`: Entire file deleted -- content absorbed into 4 new docs
- `task-anatomy.md`: Entire file deleted -- content merged into plan-structure.md
- XML `<task>` block format: Replaced by markdown headers + YAML fields
- "Parasitic" positioning language: Replaced by "standalone with source attribution"

## Open Questions

1. **gray-matter dependency for skippy-state.ts**
   - What we know: bun has built-in capabilities for text processing. YAML frontmatter in .planning/ files uses simple structures (no multiline values, no complex nesting).
   - What's unclear: Whether a manual YAML parser (split on `---`, parse key:value lines) handles all edge cases in existing .planning/ files.
   - Recommendation: Start with manual parser. Add gray-matter only if edge cases surface. Keep the dependency optional.

2. **Deviation rules placement: plan-structure.md or checkpoints.md?**
   - What we know: Deviation rules are executed during plan execution (closer to plan-structure.md scope) but Rule 4 creates checkpoints (closer to checkpoints.md scope).
   - What's unclear: Whether splitting them across two docs is cleaner or more confusing.
   - Recommendation: Put deviation rules in plan-structure.md (they're part of the execution protocol for tasks) and cross-reference from checkpoints.md for Rule 4.

3. **SKILL.md update scope**
   - What we know: SKILL.md references `gsd-dependency-map.md` in its Maintenance table and says "sharpen GSD's planning." It also lists task-anatomy.md in the Enhancements table.
   - What's unclear: How much restructuring SKILL.md needs vs. simple text replacement.
   - Recommendation: Replace text references, update the Enhancements table to replace task-anatomy row with plan-structure, remove gsd-dependency-map from Maintenance. Keep changes minimal.

## Sources

### Primary (HIGH confidence)
- GSD execute-phase.md (460 lines) -- read in full, all patterns mapped
- GSD execute-plan.md (450 lines) -- read in full, all patterns mapped
- GSD checkpoints.md (777 lines) -- read in full, all patterns mapped
- GSD state.md template (177 lines) -- read in full, lifecycle documented
- GSD summary.md template (249 lines) -- read in full, format documented
- All 11 existing skippy reference docs -- read in full, format patterns confirmed
- Reconcile command (125 lines) -- read in full, parsing logic identified
- SKILL.md (130 lines) -- read in full, update points identified

### Secondary (MEDIUM confidence)
- grep results for GSD language across skills/ and tools/ -- comprehensive scan, 40 occurrences found
- CONVENTIONS.md -- confirmed shell library conventions and sourcing pattern
- PROJECT.md -- confirmed current constraint language needing update

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- bun already installed, reference doc format established across 11 docs
- Architecture: HIGH -- 4-doc structure decided by user, content mapping verified against source files
- Pitfalls: HIGH -- overlap mapping verified by reading every existing reference doc
- Language cleanup: HIGH -- grep results are definitive, 40 occurrences enumerated

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable -- GSD source files unlikely to change during this period)
