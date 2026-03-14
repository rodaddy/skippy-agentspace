# Model Routing -- Best-of-Breed Synthesis

Match model capability to task complexity for cost-efficient agent delegation. Synthesized from OMC and phased execution patterns.

## Source Upstreams

| Upstream | Implementation | Strength | Weakness |
|----------|---------------|----------|----------|
| OMC | Agent tiers (Haiku/Sonnet/Opus) with per-task routing via `agent-tiers.md` decision guide | Granular per-task model selection, explicit complexity classification, cost-aware | Assumes multi-agent runtime with Task delegation API |
| Phased Execution | `model_profile` in config.json (quality/speed/cost) applied globally per phase | Simple, one setting covers entire execution | No per-task routing -- complex and trivial tasks get the same model |

## Why This Version

The global profile approach is too coarse -- a phase doing both simple file edits and complex refactoring wastes tokens (or quality) by treating them identically. OMC's tier system is the right granularity but assumes its own agent runtime. This synthesis extracts the DECISION HEURISTIC from OMC's tiers and applies it to agent spawning (explore agents, executor agents) without requiring OMC's infrastructure.

## The Pattern

### Complexity Classification

Before delegating any task to a subagent, classify its complexity:

| Complexity | Model Tier | Signal Words | Examples |
|------------|-----------|--------------|----------|
| **LOW** | Haiku | lookup, list, check, rename, add export | Find all usages of X, add a missing import, update a version string |
| **MEDIUM** | Sonnet | implement, add feature, write tests, debug | Build an API endpoint, write integration tests, fix a failing test |
| **HIGH** | Opus | refactor, architect, analyze tradeoffs, debug complex | Redesign module structure, analyze performance bottleneck, review security model |

### Decision Rules

1. **Default to MEDIUM.** Most implementation work is standard complexity.
2. **Drop to LOW** when the task is mechanical -- no judgment required, just execution of a known pattern.
3. **Escalate to HIGH** when the task requires reasoning about tradeoffs, understanding system-wide impact, or synthesizing multiple concerns.
4. **When unsure, use MEDIUM.** Overshooting by one tier wastes less than undershooting (a failed LOW-tier attempt costs a retry at MEDIUM).

### Cost Awareness

The tier spread matters: LOW is roughly 10-20x cheaper than HIGH per token. A phase with 10 tasks where 6 are LOW, 3 are MEDIUM, and 1 is HIGH costs significantly less than routing all 10 to HIGH -- with no quality loss on the simple tasks.

## Integration Points

- **Executor agents:** When spawning explore or executor subagents, pass the appropriate model parameter based on task complexity classification.
- **Plan phase:** Planners can annotate tasks with expected complexity (LOW/MEDIUM/HIGH) to guide executor model selection.
- **Config.json model_profile:** Treat as a floor, not a ceiling. A "speed" profile means default to LOW unless complexity demands higher; a "quality" profile means default to MEDIUM with HIGH for complex work.

## When to Apply

- Spawning any subagent (explore, executor, researcher)
- Planning tasks that will be delegated to agents
- Reviewing execution costs after a phase completes
- NOT applicable to single-agent sessions where you are the only model running

---
*Sources: OMC `skills/ultrawork/SKILL.md` + `docs/shared/agent-tiers.md`. Adapted from GSD `config.json` model_profile.*
*Last reviewed: 2026-03-07*
