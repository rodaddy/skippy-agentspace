# Compaction Resilience -- Mid-Session State Preservation

Adapted from OMC's pre-compact hook. Defines what to preserve when context compaction happens during a session. Fills the gap between context brackets (awareness of context pressure) and session persistence (cross-session transfer) -- this is the intra-session survival pattern.

## When to Apply

- When you notice context compression has occurred (messages summarized, detail lost)
- When self-monitoring suggests DEEP or CRITICAL bracket (see `context-brackets.md`)
- Before any operation that will consume significant context (large file reads, many agent spawns)
- Proactively when a long session crosses MODERATE bracket with significant work remaining

## Checkpoint Structure

A compaction checkpoint captures three things: what you were doing, what's left, and what you learned.

### Template

```markdown
## Compaction Checkpoint

### Active Work
- **Task:** [What you're working on -- be specific]
- **Phase:** [GSD phase number and name, if applicable]
- **Status:** [Where you are in the task -- what's done, what's in progress]
- **Current file:** [The file you're actively editing or about to edit]
- **Branch:** [Git branch name]

### Remaining Work
- [ ] [Next immediate step]
- [ ] [Step after that]
- [ ] [Remaining items, ordered by priority]
- **Blocked by:** [Anything preventing progress, or "nothing"]

### Learned Context
- [Key decisions made during this session that aren't in plan files]
- [Gotchas discovered -- things that didn't work or surprised you]
- [File locations or patterns you discovered that you'll need again]
- [Any user preferences or constraints mentioned verbally but not in docs]
```

## What to Include vs Skip

### Include (high value per token)
- Specific file paths you need to return to
- Decisions made and WHY (the reasoning, not just the choice)
- Error patterns discovered (what you tried that failed)
- User corrections or preferences stated during the session
- Dependency relationships between remaining tasks

### Skip (low value per token, or recoverable)
- File contents you've already read (re-read them)
- Detailed conversation history (compaction already summarized it)
- Standard project setup (it's in CLAUDE.md and PROJECT.md)
- Anything written to disk (STATE.md, PLAN.md, committed code)

## When to Create Checkpoints

| Trigger | Action |
|---------|--------|
| **Entering DEEP bracket** | Write a checkpoint to `.planning/STATE.md` or print it inline |
| **Before spawning 3+ agents** | Checkpoint first -- agent results will fill context |
| **Before large file read** | If the read might push you to CRITICAL, checkpoint first |
| **System compressed messages** | You're already in DEEP/CRITICAL -- checkpoint immediately |
| **Switching tasks mid-session** | Checkpoint the old task before starting the new one |

## Where to Write Checkpoints

In priority order:

1. **`.planning/STATE.md`** -- if you're in a GSD project, append to the session notes section
2. **Inline in conversation** -- print the checkpoint so it survives in the compacted summary
3. **Git commit message** -- if you have uncommitted work, commit with the checkpoint as the message body

Option 1 is best because it persists to disk. Option 2 is a fallback. Option 3 captures both code state and context state together.

## Recovery After Compaction

When you detect that compaction has occurred:

1. Check `.planning/STATE.md` for any checkpoints you wrote
2. Re-read the current phase's PLAN.md to re-anchor on the task
3. Run `git status` and `git log --oneline -5` to see where code stands
4. Resume from the "Remaining Work" list in your checkpoint

## Integration with Context Brackets

```
FRESH     -> No checkpoints needed, operate freely
MODERATE  -> Consider checkpointing if significant work remains
DEEP      -> Checkpoint NOW, then finish only current in-flight task
CRITICAL  -> Checkpoint, complete current step, suggest session wrap
```

## Integration Prompt

When operating in MODERATE+ context bracket:

```
You're deep in context. Before continuing, write a compaction checkpoint:
what you're working on (task, phase, current file), what remains (ordered steps),
and what you've learned (decisions, gotchas, discoveries). Write it to
.planning/STATE.md or print inline so it survives compaction.
```
