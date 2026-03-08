# Phased Execution -- Standalone Protocol

Standalone protocol for phased plan execution with wave-based parallelism. Covers plan discovery, wave grouping, agent coordination, and result aggregation.

## Core Principle

**Orchestrator coordinates, executors implement.** The orchestrator stays lean (~10-15% context) -- it discovers plans, groups them into waves, spawns executor agents, and aggregates results. Each executor gets a fresh context window to work with, preserving peak quality on every plan.

## Phase Discovery

At phase start, scan the phase directory for plan files and group by wave number from each plan's YAML frontmatter:

1. **Find plans:** List all `*-PLAN.md` files in the phase directory
2. **Check completion:** Skip plans that already have a matching `*-SUMMARY.md`
3. **Read frontmatter:** Extract `wave` number, `depends_on`, and `autonomous` fields
4. **Group by wave:** Plans with the same wave number execute together

Plans without a `wave` field default to wave 1. Plans with `depends_on` must run after their dependencies complete.

## Wave Execution

Execute waves in sequence. Within a wave, plans run in parallel (if parallelization is enabled) or sequentially.

### Per-Wave Protocol

```
For each wave (ascending order):

1. DESCRIBE -- Read each plan's objective. State what's being built and why.
   Bad:  "Executing terrain generation plan"
   Good: "Procedural terrain using Perlin noise -- height maps,
          biome zones, collision meshes. Required before vehicle
          physics can interact with ground."

2. SPAWN -- Launch executor agents for each plan in the wave.
   Pass plan paths only -- executors read files themselves.
   Each executor: read plan, execute tasks, commit atomically,
   create SUMMARY.md, update STATE.md.

3. WAIT -- Block until all agents in this wave complete.

4. VERIFY -- Spot-check each SUMMARY.md before reporting:
   - Do first 2 files from key-files.created exist on disk?
   - Does git log show at least 1 commit for this plan?
   - Is there a "Self-Check: FAILED" marker?
   If any check fails, route to failure handling.

5. REPORT -- Summarize what was built, note deviations.
   Bad:  "Wave 2 complete. Proceeding to Wave 3."
   Good: "Terrain system complete -- 3 biome types, height-based
          texturing, physics collision meshes. Vehicle physics
          (Wave 3) can now reference ground surfaces."

6. PROCEED -- Move to the next wave.
```

## Context Efficiency

The orchestrator's job is coordination, not execution. Keep orchestrator context lean:

| Role | Context Budget | What It Does |
|------|---------------|--------------|
| Orchestrator | ~10-15% | Discover, group, spawn, aggregate |
| Executor | Fresh 200k each | Read plan, implement, verify, commit |

Never bleed execution details into orchestrator context. Executors load their own plan files, read their own source files, and make their own implementation decisions.

## Branching Strategy

Phase execution optionally creates a branch before starting:

| Strategy | When | Branch Name |
|----------|------|-------------|
| none | Default | Stay on current branch |
| phase | Multi-plan phases | `phase-{N}-{name}` |
| milestone | Major releases | `milestone-{name}` |

All task commits go to the active branch. Merging is the user's responsibility.

## Resumption

A partially-completed phase resumes cleanly:

1. Re-run phase execution on the same phase directory
2. Discovery finds completed SUMMARYs and skips those plans
3. Execution resumes from the first incomplete plan
4. Wave grouping recalculates -- completed plans are excluded from their waves

STATE.md tracks: last completed plan, current wave, pending checkpoints.

## Failure Handling

| Scenario | Action |
|----------|--------|
| One plan fails in a wave | Complete the wave, report failure, ask: retry or continue? |
| All plans in a wave fail | Systemic issue -- stop, report for investigation |
| Dependency chain breaks | Wave N fails, Wave N+1 dependents likely fail -- user chooses attempt or skip |
| Checkpoint unresolvable | Skip plan or abort phase -- record partial progress in STATE.md |

**Never start the next wave if a required dependency in the current wave failed.**

## Phase Verification

After all waves complete, trigger a verification pass:

1. Verify the phase achieved its GOAL (from ROADMAP.md), not just completed tasks
2. Cross-reference requirement IDs from plan frontmatter against REQUIREMENTS.md
3. Check `must_haves` against actual codebase state
4. Produce a VERIFICATION.md with status: `passed`, `human_needed`, or `gaps_found`

If gaps are found, a gap-closure cycle generates targeted plans to address them (see verification-loops.md for cycling protocol).

## Integration Points

- **Checkpoints between waves:** See checkpoints.md for checkpoint handling protocol
- **Verification cycling:** See verification-loops.md for bounded iteration on failures
- **State updates:** See state-tracking.md for STATE.md updates after each plan completes
- **Plan format:** See plan-structure.md for PLAN.md specification

## When to Apply

- Executing any multi-plan phase
- Resuming a partially-completed phase after interruption
- Running gap-closure plans after verification finds issues
- NOT for single ad-hoc tasks outside the phased structure

---
*Source: Adapted from GSD execute-phase.md*
*Last reviewed: 2026-03-08*
