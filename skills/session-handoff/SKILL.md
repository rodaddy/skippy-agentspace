---
name: session-handoff
description: Generate a targeted first message for the next session -- captures decisions, failures, and next actions. Supports cross-directory handoffs.
allowed-tools: "Read,Write,Edit,Grep,Glob"
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
triggers:
  - /session-handoff
  - hand off to next session
  - handoff
  - pass the baton
---

# Session Handoff - Cross-Session Context Transfer

Generate a copy-paste-ready first message for the next Claude Code session. Not a summary -- a **targeted prompt** optimized for where work continues.

## Why

Context transfer between sessions is where 30-50% of productivity is lost. The first 5-10 minutes of every session is spent re-establishing context. A good handoff cuts that to zero.

## What Makes This Different from /checkpoint or /session-wrap

| Tool | What It Produces | Limitation |
|------|-----------------|------------|
| `/checkpoint` | Generic resume prompt | Same project, no decisions, no read list |
| `/session-wrap` | Session history files | Captures past, doesn't target next session |
| `/capture-session` | OB knowledge entries | Stores insights, doesn't generate a prompt |
| **`/session-handoff`** | **Targeted first message** | **Asks where + what, generates for THAT context** |

## Workflow

### Step 1: Ask Two Questions

Ask the user (use AskUserQuestion with structured options):

**Q1: Where is the next session?**
- Same project (default)
- Different directory (ask for path)
- Not sure yet (generate portable handoff)

**Q2: What should the next session do first?**
- Free text -- the user states the next action in their own words

### Step 2: Gather Context

Collect from the current session (parallel where possible):

```bash
# Git state
git branch --show-current
git log --oneline -5
git diff --stat HEAD~1 2>/dev/null

# Active state files
# Read: .planning/STATE.md (first 20 lines)
# Read: .reports/<project>/briefing.md (if exists)
```

Then review the conversation for:
- **Decisions made** -- architectural choices, trade-offs resolved, approaches picked
- **Failures/learnings** -- what went wrong, gotchas discovered, things that didn't work
- **Files changed** -- key files the next session needs to understand
- **Blockers** -- anything unresolved that carries forward

### Step 3: Build Read List

Identify 3-7 specific files the next session should read for full context. Prioritize:
1. Files that were created or heavily modified this session
2. State files (.planning/STATE.md, CLAUDE.md)
3. Any file referenced in decisions or blockers

For cross-directory handoffs, translate paths relative to the target project.

### Step 4: Generate Handoff Message

Output a fenced block the user can copy-paste as the first message in the next session:

```
--- HANDOFF ---

## Context
Project: <name> (<path>)
Branch: <branch>
Previous session: <date>

## What Was Done
- <3-5 bullets, terse>

## Decisions Made
- <decision>: <rationale> (rejected: <alternatives>)

## Failures/Learnings
- <what went wrong>: <what we learned>

## Blockers
- <unresolved issues, or "None">

## Read These First
1. `<path>` -- <why>
2. `<path>` -- <why>
3. `<path>` -- <why>

## Do This First
<user's stated next action, enriched with context>

--- END HANDOFF ---
```

### Step 5: Persist to Open Brain (optional)

If mcp2cli open-brain is available, save the handoff for cross-session retrieval:

```bash
mcp2cli open-brain session_save --params '{"summary": "<handoff summary>", "project": "<target project>", "tags": ["handoff", "<source-project>"], "key_decisions": [<decisions>], "next_steps": [<next action>], "blockers": [<blockers>]}'
```

If the target is a different directory, tag with both source and target project names so the receiving session can find it via `session_load`.

Fail gracefully -- the copy-paste message is the primary output, OB persistence is supplemental.

### Step 6: Present

Output the handoff block directly. Then:
- If same project: "Paste this as your first message after `/clear`"
- If cross-directory: "Paste this as your first message in `<target path>`"
- If portable: "Paste this wherever the next session starts"

## Rules

- The output IS the first message. No editing required.
- Decisions are CRITICAL -- capture the "why", not just the "what"
- Failures are valuable -- don't sanitize them
- Read list must be specific files with line-count hints, not vague pointers
- Cross-directory paths must be absolute or relative to the target
- Never exceed 40 lines in the handoff block -- concise beats complete
