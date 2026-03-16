---
name: capture-session
description: Capture insights from the current Claude Code session and save to Open Brain. Extracts decisions, learnings, and session context for long-term semantic storage.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
triggers:
  - /capture-session
  - capture this session
  - send to second brain
  - save session insights
---

# Capture Session - Save to Open Brain

Extract valuable knowledge from the current session and save directly to Open Brain for semantic search and retrieval.

## What Gets Captured

| Type | Open Brain Tool | Table |
|------|----------------|-------|
| **Decisions** | `log_decision` | decisions |
| **Learnings/Solutions** | `log_thought` | thoughts |
| **Session Summary** | `session_save` | sessions |

## Workflow

1. Summarize the current session (what was done, decisions made, problems solved)
2. Extract each decision, learning, and pattern
3. Save directly to Open Brain via mcp2cli

## Implementation

When triggered:

### Step 1: Summarize Session
Generate a brief session summary covering: what was worked on, key decisions, problems solved, and next steps.

### Step 2: Save Decisions
For each architectural or implementation decision made during the session:
```bash
mcp2cli open-brain log_decision --params '{"title": "<decision>", "rationale": "<why>", "alternatives": ["<alt1>", "<alt2>"], "tags": ["tag1", "tag2"]}'
```

### Step 3: Save Learnings
For each learning, gotcha, or solution discovered:
```bash
mcp2cli open-brain log_thought --params '{"content": "<learning with full context>", "tags": ["tag1", "tag2"]}'
```

### Step 4: Save Session Summary
```bash
mcp2cli open-brain session_save --params '{"summary": "<session summary>", "project": "<project>", "tags": ["session-capture"], "key_decisions": ["<decision1>"], "next_steps": ["<step1>"], "blockers": []}'
```

### Step 5: Confirm
Report what was captured:
```
Captured to Open Brain:
- N decisions
- N learnings/thoughts
- 1 session summary
```

## Graceful Degradation

If `mcp2cli open-brain` fails at any step:
1. Log a warning with the specific failure
2. Continue with remaining steps (don't abort on partial failure)
3. At the end, report what succeeded and what failed
4. Suggest manual capture for failed items

## Usage

At the end of a meaningful session:
```
/capture-session
```

With a custom note:
```
/capture-session "Fixed auth bug, switched to JWT tokens"
```
