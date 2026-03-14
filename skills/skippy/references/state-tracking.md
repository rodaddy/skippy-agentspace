# State Tracking -- STATE.md Lifecycle

STATE.md lifecycle -- creation, reading, writing, and size management for project state. The single coordination file that enables session continuity and progress tracking across phases.

## Purpose

**Problem:** Information is captured in summaries, issues, and decisions but not systematically consumed. Sessions start without context.

**Solution:** A single, small file that is:
- Read first in every workflow
- Updated after every significant action
- Contains a digest of accumulated context
- Enables instant session restoration

## Format Specification

### Frontmatter (YAML)

| Field | Purpose | Example |
|-------|---------|---------|
| `milestone` | Current milestone name | `v1.2` |
| `milestone_name` | Human-readable name | `Standalone Skippy` |
| `status` | Current state | `in_progress`, `completed` |
| `stopped_at` | Last action description | `Phase 13 plan 01 complete` |
| `last_updated` | ISO timestamp | `2026-03-08T19:00:00Z` |
| `progress.total_phases` | Phase count | `16` |
| `progress.completed_phases` | Done count | `11` |
| `progress.total_plans` | Plan count across all phases | `27` |
| `progress.completed_plans` | Done plan count | `25` |
| `progress.percent` | Completion percentage | `93` |

### Body Sections

| Section | Contains | Update Frequency |
|---------|----------|-----------------|
| **Project Reference** | Link to PROJECT.md, core value one-liner, current focus | Phase transitions |
| **Current Position** | Phase N of M, Plan A of B, status, last activity, progress bar | After every plan |
| **Performance Metrics** | Velocity stats, per-phase table (plans, duration, files), trends | After every plan |
| **Accumulated Context** | Decisions, pending todos, blockers/concerns | After every plan |
| **Session Continuity** | Last session timestamp, stopped-at description, resume file path | Every session end |

## Lifecycle

### Creation
After ROADMAP.md is created during project initialization:
- Reference PROJECT.md for core value
- Initialize empty accumulated context sections
- Set position to "Phase 1, ready to plan"

### Reading (First Step of Every Workflow)
| Workflow | Why Read STATE.md |
|----------|------------------|
| Progress check | Present current status to user |
| Planning | Inform planning decisions with context |
| Execution | Know current position and pending work |
| Transition | Know what's complete before advancing |

### Writing (After Every Significant Action)

**After plan execution:**
- Update position (phase, plan, status)
- Record new decisions (detail in PROJECT.md, summary here)
- Add blockers/concerns discovered during execution
- Update performance metrics

**After phase transition:**
- Update progress bar and percentages
- Clear resolved blockers
- Refresh Project Reference date

### Pruning (At Phase Transitions)
- Keep only 3-5 most recent decisions in summary (full log in PROJECT.md)
- Remove resolved blockers
- Archive stale Working-tier context (Priority/Working/Reference tiers -- see session-persistence.md for full model)

## Size Constraint

**Keep STATE.md under 100 lines.**

It is a DIGEST, not an archive. If accumulated context grows too large:
- Move historical decisions to PROJECT.md Key Decisions table
- Keep only active blockers, remove resolved ones
- Summarize rather than enumerate (e.g., "5 pending todos -- see .planning/todos/")
- Performance metrics: keep per-phase table compact, archive old phases

**The goal is "read once, know where we are."** If it takes more than a quick scan to orient, the file is too long.

## Progress Calculation

```
progress = (completed_plans / total_plans_across_all_phases) * 100
```

Visual progress bar uses filled/empty blocks: `[######----] 60%`

Update after each plan completion by counting SUMMARY.md files against PLAN.md files on disk.

## Integration Points

- **Cross-file alignment:** See state-consistency.md for checks that STATE.md agrees with ROADMAP.md and phase directories
- **Tier-based loading:** See session-persistence.md for which sections to load based on context depth
- **Plan execution:** See plan-structure.md for what triggers STATE.md updates
- **Reconciliation:** See reconciliation.md for state drift detection

## When to Apply

- Starting any session (read Priority tier: Current Position)
- After completing any plan (update position, metrics, decisions)
- At phase transitions (prune, advance, refresh)
- When something "feels off" about project state (check alignment)
- NOT as a replacement for PROJECT.md -- STATE.md is the digest, PROJECT.md is the full record

---
*Source: Adapted from GSD state.md template and execute-plan.md state update protocol*
*Last reviewed: 2026-03-08*
