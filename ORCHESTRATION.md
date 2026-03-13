# Orchestration Protocol

A lightweight protocol for composing skills, personas, and agents into coordinated workflows. No framework required -- just structured patterns for combining what's already here.

## Core Concept

Individual skills solve individual problems. Real work crosses boundaries -- a feature needs planning, execution, review, and session handoff. Orchestration connects skills into pipelines.

Three building blocks:

- **Personas** define _who is thinking_ -- judgment style, communication, priorities
- **Skills** define _how to execute_ -- steps, scripts, references, templates
- **Agents** define _parallel capacity_ -- concurrent specialists working non-overlapping scopes

You combine them. The pattern is always the same: pick the right voice, load the right knowledge, dispatch the right workers.

## Patterns

### Pattern 1: Persona Phase

Switch personas as work moves through phases. Each persona brings different judgment to different stages.

**When to use:** Multi-stage work where the _type of thinking_ changes between stages.

**How it works:**
1. Identify the phases of your work
2. Match each phase to the persona whose judgment fits
3. Switch at phase boundaries -- carry context forward

**Example: New Feature Development**

```
Phase 1: Architecture (Bob)
  "persona bob"
  Load: skippy-dev/references/plan-structure.md
  Output: Architecture decision, plan with boundaries

Phase 2: Implementation (Skippy)
  "persona skippy"
  Load: skippy-dev/references/phased-execution.md
  Output: Working code, tests passing

Phase 3: Documentation (Clarisa)
  "persona clarisa"
  Output: User-facing docs, onboarding notes

Phase 4: Design Review (April)
  "persona april"
  Output: UX critique, visual alternatives
```

**Phase transition template:**
```
Phase [N] complete.
Decisions made: [list]
Artifacts created: [list]
Open questions: [list]
Switching to: [persona] for [next phase purpose]
```

**Rules:**
- One persona at a time. Don't blend voices in the same prompt.
- Switching is cheap. Do it whenever the type of thinking changes.
- The human decides which persona fits -- these are suggestions, not prescriptions.

---

### Pattern 2: Skill Stack

Load multiple reference docs simultaneously for deep work in a single domain. Skills don't conflict -- they layer.

**When to use:** Complex tasks where one skill's knowledge isn't enough.

**How it works:**
1. Identify the task domain
2. Load all relevant references from that domain
3. Work with the combined knowledge

**Example: Creating a Bulletproof Plan**

```
Load simultaneously:
  skippy-dev/references/plan-structure.md      -- task format, deviation rules
  skippy-dev/references/plan-boundaries.md     -- scope protection, DO NOT CHANGE
  skippy-dev/references/ambiguity-scoring.md   -- requirements clarity gate
  skippy-dev/references/pre-execution-gate.md  -- intercept vague requests
```

**Example: Hardened Execution**

```
Load simultaneously:
  skippy-dev/references/phased-execution.md        -- wave-based parallelism
  skippy-dev/references/parallel-file-ownership.md  -- non-overlapping agent scopes
  skippy-dev/references/state-tracking.md           -- STATE.md lifecycle
  skippy-dev/references/checkpoints.md              -- human verification gates
```

**Example: Session Resilience**

```
Load simultaneously:
  skippy-dev/references/session-persistence.md     -- context transfer
  skippy-dev/references/compaction-resilience.md   -- checkpoint before compaction
  skippy-dev/references/context-brackets.md        -- monitor context usage
```

**Common stacks:**

| Stack Name | References | Best For |
|------------|-----------|----------|
| Planning | plan-structure + plan-boundaries + ambiguity-scoring | Creating plans |
| Execution | phased-execution + parallel-file-ownership + state-tracking | Running plans |
| Quality | verification-loops + audit-swarm + state-consistency | Validating work |
| Resilience | session-persistence + compaction-resilience + context-brackets | Long sessions |

**Rules:**
- Stack freely -- references are additive, not conflicting.
- Don't load everything. Pick the 2-4 references that match the current task.
- Agents get references pasted into their prompts, not loaded via Read (per agent-reference pattern).

---

### Pattern 3: Skill Chain

Invoke skills sequentially for end-to-end workflows. The output of one skill feeds the next.

**When to use:** Repeatable processes with a defined sequence of steps.

**How it works:**
1. Define the sequence
2. Run each skill, passing output forward
3. Each skill handles its own domain -- no manual glue

**Example: Daily Development Cycle**

```
1. /check-todos          -- see what's pending
2. [pick a task, work]   -- execute
3. /skippy:reconcile     -- compare planned vs actual
4. /update-todo          -- mark progress
5. /session-wrap         -- commit session artifacts
```

**Example: New Project Bootstrap**

```
1. core templates        -- scaffold CLAUDE.md from template
2. /add-todo             -- capture initial backlog
3. Plan with skill stack -- create phased plan (Pattern 2)
4. Execute               -- run phases
5. /skippy:review        -- audit the result
6. /skippy:reconcile     -- verify plan alignment
```

**Example: Upstream Sync**

```
1. /skippy:update        -- check all upstreams for changes
2. [review suggestions]  -- decide what to cherry-pick
3. /skippy:review        -- audit the cherry-picked changes
4. /skippy:reconcile     -- verify nothing drifted
```

**Rules:**
- Each skill is autonomous -- it doesn't need to know about the chain.
- The human (or orchestrating agent) is the glue between steps.
- Skip steps that don't apply. Chains are templates, not rigid pipelines.

---

### Pattern 4: Audit Cycle

Spawn multiple specialist agents, aggregate findings, fix, and re-evaluate. The formalized version of "review from every angle."

**When to use:** After significant implementation, before declaring work complete.

**How it works:**
1. Define scope (phase, directory, or full repo)
2. Spawn specialist reviewers (security, code quality, architecture, consistency)
3. Aggregate findings to shared board
4. Fix agents address CRITICAL and HIGH findings
5. Re-evaluate -- cycle until clean (max 3 iterations)

**Built-in command:** `/skippy:review` handles this entire pattern.

**Manual orchestration for custom audits:**

```
Scope: skills/deploy-service/

Spawn in parallel:
  Agent 1: Security reviewer -- injection, secrets, permissions
  Agent 2: Code quality -- shellcheck, conventions, DRY
  Agent 3: Architecture -- portability, coupling, file size
  Agent 4: Consistency -- cross-reference with CONVENTIONS.md, CLAUDE.md

Shared board: .reports/skippy-review/findings-{timestamp}.md

Fix cycle:
  - Fix agents for CRITICAL/HIGH
  - Re-eval agent checks fixes didn't regress
  - Max 3 iterations
```

**Rules:**
- Always sandbox destructive reviewers (sandboxed HOME, backup first).
- Findings board is the single source of truth -- agents reference it, not each other.
- Fix agents get narrow scope (one finding at a time), not the full board.

---

### Pattern 5: Phase Handoff

Transfer context between execution phases, across sessions, or through context compaction. The "nothing gets lost" pattern.

**When to use:** Long-running work that spans multiple sessions or hits context limits.

**How it works:**
1. Before ending a phase/session, checkpoint the state
2. Use structured artifacts (STATE.md, SUMMARY.md) not memory
3. Next phase/session loads the checkpoint, not raw conversation history

**Checkpoint content:**

```
Current phase: [N] -- [name]
Status: [complete | in-progress | blocked]
Decisions made: [list with rationale]
Files changed: [list]
Open items: [what the next phase needs to resolve]
Blockers: [anything preventing progress]
```

**Triggering mechanisms:**

| Trigger | Action | Reference |
|---------|--------|-----------|
| Phase complete | Write SUMMARY.md, update STATE.md | state-tracking.md |
| Session ending | `/session-wrap` | session-persistence.md |
| Context getting deep | Checkpoint before compaction | compaction-resilience.md |
| Context bracket warning | Proactive checkpoint | context-brackets.md |

**Rules:**
- Structured artifacts over conversation summaries. STATE.md is parseable; "we did some stuff" isn't.
- Update STATE.md at every transition -- it's the single source of truth for project progress.
- `/session-wrap` is the canonical end-of-session action. Don't skip it.

---

## Quick Reference

### Pattern Selection

| Situation | Pattern |
|-----------|---------|
| Different thinking needed per stage | Persona Phase |
| Deep work in one domain | Skill Stack |
| Repeatable multi-step process | Skill Chain |
| Post-implementation quality gate | Audit Cycle |
| Long work spanning sessions | Phase Handoff |

### Persona Quick Reference

| Persona | Best For | Activate |
|---------|----------|----------|
| Skippy | Execution, review, debugging | "persona skippy" (default) |
| Bob | Architecture, trade-offs, teaching | "persona bob" |
| Clarisa | Docs, onboarding, encouragement | "persona clarisa" |
| April | Design, brainstorming, alternatives | "persona april" |

### Common Skill Chains

| Chain | Sequence |
|-------|----------|
| Daily dev | /check-todos -> work -> /skippy:reconcile -> /update-todo -> /session-wrap |
| Quality gate | /skippy:review -> fix -> /skippy:reconcile |
| Upstream sync | /skippy:update -> review -> /skippy:review |
| Session end | /update-todo -> /session-wrap |

### Skill Stacks

| Stack | Load Together |
|-------|--------------|
| Planning | plan-structure + plan-boundaries + ambiguity-scoring |
| Execution | phased-execution + parallel-file-ownership + state-tracking |
| Quality | verification-loops + audit-swarm + state-consistency |
| Resilience | session-persistence + compaction-resilience + context-brackets |

## Combining Patterns

Patterns compose. A real project uses multiple patterns together:

```
Project Lifecycle:

1. Requirements gathering
   Pattern: Persona Phase (Bob for analysis)
   Stack: Planning stack

2. Plan creation
   Pattern: Skill Stack (planning references)
   Chain: ambiguity-scoring -> plan-structure -> plan-boundaries

3. Execution
   Pattern: Persona Phase (Skippy for implementation)
   Stack: Execution stack
   Handoff: Phase Handoff between execution phases

4. Quality gate
   Pattern: Audit Cycle (/skippy:review)
   Stack: Quality stack

5. Reconciliation
   Chain: /skippy:reconcile -> /update-todo

6. Session close
   Chain: /session-wrap
   Handoff: Phase Handoff for next session
```

Patterns are composable building blocks, not rigid workflows. Use what fits, skip what doesn't.
