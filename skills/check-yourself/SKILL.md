---
name: check-yourself
description: Re-inject the rationalization defense table mid-session. Use when the agent is drifting, skipping protocol, or rationalizing past LAWs. The table auto-loads at session start but context drift can push it out.
triggers:
  - /check-yourself
  - check yourself
  - rationalization
  - stop rationalizing
  - follow the rules
  - read the defense table
---

# /check-yourself - Rationalization Defense Re-injection

Re-read the rationalization defense table and re-commit to protocol compliance.

## Workflow

1. Read `~/.claude/docs/rationalization-defense.md`
2. Output the FULL content to the user (this puts it back in active context)
3. State which LAW or table row you were about to violate (if applicable)
4. Re-commit: "I will follow the commitment protocol from this point forward"

## When to Use

- User says "check yourself", "follow the rules", "stop rationalizing"
- Agent notices it used "just", "quickly", "simply", "obviously" to justify a shortcut
- Agent has gone 5+ tool calls without updating the user
- Agent caught itself about to skip a skill, search, or explanation
- Context is deep and the session-start injection may have been compacted away

## Execution

Read the full doc and display it:

```
Read ~/.claude/docs/rationalization-defense.md
```

Then respond with:
- Which rule(s) you were drifting on
- Your corrected approach going forward
- Re-state your commitment protocol for the current task
