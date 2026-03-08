# Session Persistence -- Best-of-Breed Synthesis

Tiered state persistence matching urgency to storage strategy. Synthesized from OMC and GSD.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC | `.omc/notepad.md` with three tiers: Priority Context (always loaded, 500 char limit), Working Memory (timestamped, auto-pruned after 7 days), Manual (never pruned) | Tiered urgency with automatic lifecycle management, compaction-resilient | Requires MCP tools (`state_write`, `notepad_write`), OMC-specific file paths |
| GSD | `.planning/STATE.md` -- git-tracked markdown with position, decisions, blockers, metrics | Persistent across sessions, version-controlled, human-readable, portable | Flat structure -- no urgency tiers, no auto-pruning, grows unbounded |

## Why This Version

GSD's STATE.md is the right persistence MECHANISM -- git-tracked, portable, no MCP dependency, works with vanilla Claude Code. But it treats all state as equally important, which wastes context when loading it. OMC's contribution is the CONCEPT of tiered urgency: not all state deserves equal attention at session start. This synthesis applies OMC's three-tier mental model to GSD's existing artifact structure, without adding new files or tools.

## The Pattern

### Three Tiers of Persistence

| Tier | Purpose | GSD Artifact | Load When | Lifecycle |
|------|---------|-------------|-----------|-----------|
| **Priority** | Critical facts needed every session | STATE.md "Current Position" section | Always -- first thing loaded | Updated each session, never pruned |
| **Working** | Active investigation context, recent decisions | STATE.md "Accumulated Context" + SUMMARY.md files | When resuming work on that phase | Pruned when phase completes or becomes stale |
| **Reference** | Permanent project knowledge, architectural decisions | PROJECT.md, CONTEXT.md, CLAUDE.md | On demand when relevant | Never pruned, updated rarely |

### Priority Tier Rules

The Priority tier is what an agent reads FIRST to orient itself. Keep it small and current:

- **Must contain:** Current phase, current plan, last activity, immediate blockers
- **Size limit:** Keep under 500 characters of essential facts (mirrors OMC's Priority Context limit)
- **Update frequency:** Every session end
- **Anti-pattern:** Stuffing historical decisions into Priority. Those belong in Working or Reference tier.

### Working Tier Rules

Working context is session-scoped knowledge that's valuable now but decays:

- **Contains:** Recent decisions, active debugging breadcrumbs, current task progress, recent commit hashes
- **Stored in:** STATE.md "Decisions" and "Blockers" sections, plus the most recent SUMMARY.md
- **Pruning signal:** When a phase completes, its Working context graduates to Reference (via SUMMARY.md) or gets discarded
- **Staleness:** If a Working entry hasn't been referenced in 3+ sessions, consider moving it to Reference or removing it

### Reference Tier Rules

Reference context is permanent project knowledge:

- **Contains:** Architectural decisions, project constraints, key file locations, established patterns
- **Stored in:** PROJECT.md, CONTEXT.md, CLAUDE.md
- **Load pattern:** Load on demand when the current task touches that domain
- **Never pruned:** But periodically reviewed for accuracy (stale reference is worse than no reference)

### Context Bracket Integration

Adapt loading behavior based on context depth (see `context-brackets.md`):

| Bracket | Priority | Working | Reference |
|---------|----------|---------|-----------|
| FRESH | Load fully | Load fully | Load relevant sections |
| MODERATE | Load fully | Load summaries only | Load on demand |
| DEEP | Load fully | Skip -- rely on artifacts | Skip -- rely on artifacts |
| CRITICAL | Load fully | Skip entirely | Skip entirely |

## Integration Points

- **GSD session start:** Load STATE.md Priority tier (Current Position section) immediately. Load Working tier if resuming active work.
- **GSD session end:** Update STATE.md Priority tier with final position. Prune stale Working entries.
- **GSD phase transitions:** Graduate Working context to Reference (captured in SUMMARY.md). Reset Working tier for new phase.
- **Context brackets:** Tier loading adapts based on current bracket depth.

## When to Apply

- Starting any new session (load Priority tier)
- Resuming work after interruption (load Priority + Working tiers)
- Researching architectural context (load Reference tier on demand)
- Wrapping up a session (update Priority, prune Working)
- NOT a replacement for STATE.md -- this is a mental model for HOW to use STATE.md effectively

---
*Sources: OMC `skills/note/SKILL.md`, GSD `.planning/STATE.md` conventions*
*Last reviewed: 2026-03-07*
