# Context Degradation -- 5 Failure Modes

Taxonomy of how context window content degrades agent performance. Each mode has distinct symptoms, triggers, and mitigations. Recognizing the mode is half the fix -- most context problems are treated as "the model got confused" when the real issue is a specific, addressable degradation pattern.

**Source:** Agent-Skills-for-Context-Engineering (academic, Peking University)
**Cherry-picked:** 2026-04-06

## The 5 Modes

### 1. Lost-in-the-Middle

Information placed in the middle of long contexts is underweighted relative to content near the start or end. The agent "forgets" or deprioritizes mid-context content.

- **Symptoms:** Agent ignores instructions or facts that are present but buried in the middle of context
- **Trigger:** Context exceeds ~30K tokens with critical info not at boundaries
- **Mitigation:** Place critical information at context start (system prompt, CLAUDE.md) or end (recent messages). Repeat key constraints at both boundaries.
- **In skippy:** CLAUDE.md placement, LAWs at top of system prompt, recent user instruction anchoring

### 2. Context Poisoning

Injected, outdated, or incorrect information actively misleads the agent. Unlike distraction (mode 3), poisoned context is wrong, not just irrelevant.

- **Symptoms:** Agent confidently acts on false premises, cites stale data as current
- **Trigger:** Stale session state loaded without recency check, copy-pasted content from outdated sources, prompt injection in user-supplied content
- **Mitigation:** Source attribution on all loaded content. Recency timestamps. Validate state files against actual repo state before trusting them.
- **In skippy:** `session-start` scout validates STATE.md against git log; brain queries include timestamps

### 3. Distraction

Irrelevant but plausible context dilutes the agent's attention budget. The content is not wrong -- it is just not useful for the current task.

- **Symptoms:** Agent references tangential information, responses become unfocused, token budget wasted on irrelevant details
- **Trigger:** Loading full file contents when only a section is needed, bulk skill/reference loading, kitchen-sink system prompts
- **Mitigation:** Aggressive pruning. Tier-based loading (load summaries first, details on demand). Only load references relevant to the current task.
- **In skippy:** Reference docs are loaded individually by relevance, not bulk-loaded. Skills use slim SKILL.md + references/ architecture to avoid front-loading everything.

### 4. Confusion

Contradictory information from multiple sources causes the agent to oscillate between conflicting directives or pick one arbitrarily.

- **Symptoms:** Agent alternates between approaches, gives inconsistent answers across turns, hedges excessively
- **Trigger:** Multiple sources define the same concept differently, outdated docs contradict current docs, merged context from different sessions
- **Mitigation:** Single source of truth per fact. Explicit conflict detection ("if X says A but Y says B, X wins"). Version/timestamp all authoritative docs.
- **In skippy:** CLAUDE.md is canonical for project rules. LAWs override all other instructions. Each reference doc cites its source to resolve conflicts.

### 5. Context Clash

Instructions from different authority levels conflict. Unlike confusion (mode 4, which is about facts), clash is about competing directives.

- **Symptoms:** Agent violates a rule while following a different rule, or freezes when rules conflict
- **Trigger:** Skill instructions contradict CLAUDE.md, user request conflicts with LAW, session context overrides project defaults
- **Mitigation:** Explicit priority ordering. In PAI: LAWs > CLAUDE.md > skill instructions > session context > user convenience requests. When conflict detected, flag it rather than silently choosing.
- **In skippy:** LAW priority is documented and enforced. Skills cannot override LAWs. Conflict flagging is required (LAW 1: Never Assume).

## Degradation vs Workflow Stage

| Mode | Planning | Execution | Review | Session Mgmt |
|------|:--------:|:---------:|:------:|:------------:|
| Lost-in-the-middle | Low risk (short context) | High risk (long sessions) | Medium | High risk (loaded state) |
| Context poisoning | Medium (stale plans) | High (stale state) | Low | High (old session data) |
| Distraction | Medium (excess refs) | High (bulk file reads) | Low | Medium |
| Confusion | High (multiple specs) | Medium | High (conflicting reviews) | Low |
| Context clash | Low | Medium (skill vs LAW) | Low | Medium (session vs project) |

## How Skippy Patterns Mitigate Degradation

| Skippy Pattern | Modes Addressed |
|---------------|----------------|
| `session-persistence.md` tiering | Distraction (tier-based loading), Lost-in-the-middle (priority context at boundaries) |
| `compaction-resilience.md` checkpoints | Lost-in-the-middle (re-anchor after compaction), Context poisoning (fresh state) |
| `context-brackets.md` awareness | Distraction (prune in DEEP+), Lost-in-the-middle (reduce scope as context grows) |
| LAW priority chain | Context clash (explicit ordering), Confusion (single authority) |

## When to Apply

- When debugging why an agent "ignored" information that was in its context
- When designing context loading strategies for skills or session management
- When context is large (MODERATE+ bracket) and agent behavior degrades
- When merging context from multiple sources (session restore, multi-agent aggregation)

## Integration Points

- **session-persistence.md** -- Tiered persistence directly mitigates distraction and lost-in-the-middle by controlling what loads and where it sits in context.
- **compaction-resilience.md** -- Compaction checkpoints are a recovery mechanism for lost-in-the-middle after context compression.
- **context-brackets.md** -- Bracket awareness is the detection layer; this taxonomy is the diagnosis layer. Brackets tell you WHEN degradation is likely; this doc tells you WHICH mode and HOW to fix it.

---
*Sources: "Agent-Skills-for-Context-Engineering" (Peking University). Mitigations adapted for PAI/skippy workflow patterns.*
*Last reviewed: 2026-04-06*
