# Context Brackets -- Self-Monitoring Protocol

Adapted from PAUL's context-management.md. Since Claude can't expose exact context usage to hooks, this is **rule-based self-monitoring** -- you estimate your bracket and adjust behavior accordingly.

## Brackets

| Bracket | Estimated Usage | Trigger Signs |
|---------|----------------|---------------|
| **FRESH** | <30% used | Session just started, few tool calls, small conversation |
| **MODERATE** | 30-60% used | Several file reads, multiple tool rounds, substantial conversation |
| **DEEP** | 60-80% used | Many files read, long conversation, multiple agent spawns |
| **CRITICAL** | >80% used | System has compressed prior messages, extensive multi-step work |

## Behavioral Rules

### FRESH (<30%)
- Operate normally
- Read full files when useful
- Spawn agents freely
- Explore broadly

### MODERATE (30-60%)
- Prefer targeted reads (offset/limit) over full file reads
- Delegate research to explore agents instead of reading directly
- Summarize findings before moving on (don't re-read later)

### DEEP (60-80%)
- **Stop exploring, start finishing**
- Use agents for any remaining research
- Don't read new files unless absolutely necessary
- If significant work remains, suggest `/session-wrap` and continue in a new session
- Keep responses concise

### CRITICAL (>80%)
- **Wrap up immediately**
- Complete only the current in-flight task
- No new file reads, no new agents
- Suggest `/session-wrap` after the current task
- If the system has already compressed messages, you're here

## Self-Monitoring Cues

You can't check a percentage, but these signals tell you where you are:

- **Compression happened:** You're in DEEP or CRITICAL. The system only compresses when context is filling up.
- **Agent count:** Each agent spawn consumes context for the result. 5+ agents in a session = likely MODERATE+.
- **File reads:** Each full file read adds hundreds to thousands of tokens. 10+ file reads = likely MODERATE+.
- **Conversation length:** If the user has sent 15+ messages with substantial responses, you're likely MODERATE+.

## Integration with GSD

GSD agents inherit these rules. A gsd-executor in DEEP bracket should:
1. Complete the current plan wave
2. Commit progress
3. Report back rather than starting new waves
4. Let the orchestrator decide whether to continue or wrap
