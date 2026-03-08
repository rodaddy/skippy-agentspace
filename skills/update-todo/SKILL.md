---
name: update-todo
description: Update any todo or idea -- add progress notes, complete, defer, or drop. Works with both project todos and global ideas.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: workflow
---

# Update Todo - Progress & Completion Tracking

Unified tool for updating any todo or idea, regardless of scope. Handles progress updates, completion with post-mortem, deferrals, and drops.

## When to Use

- Adding progress notes to an in-progress todo or idea
- Completing a project todo or global idea
- Deferring an item to someday
- Dropping an item that's no longer relevant
- Updating status mid-work (blockers, partial progress, scope changes)

## Workflow

### Step 1: Identify the Item

If the user specifies which todo, read it directly. Otherwise, run `/check-todos` first to list items and let the user pick.

**Locations to check:**
- Project todos: `{CWD}/.planning/todos/pending/*.md`
- Global ideas: `<dev-root>/.claude_ideas/active/*.md`
- Someday: `<dev-root>/.claude_ideas/someday/*.md`

### Step 2: Determine the Action

Use AskUserQuestion if not obvious from context:
- **Add progress notes** -- append update, keep in current location
- **Complete** -- add completion notes, move to completed
- **Defer** -- add reason, move to someday
- **Drop** -- add reason, move to dropped
- **Update scope** -- modify the original description/plan

### Step 3: Apply the Update

See `references/update-formats.md` for detailed templates for each action type (progress, completion, deferral, drop).

### Step 4: Update Frontmatter

Add the appropriate date field to the YAML frontmatter:
- Progress: `updated: YYYY-MM-DD`
- Completed: `completed: YYYY-MM-DD`
- Deferred: `deferred: YYYY-MM-DD`
- Dropped: `dropped: YYYY-MM-DD`

### Step 5: Move the File (if status changed)

| Action | From | To |
|--------|------|-----|
| Complete (project) | `.planning/todos/pending/` | `.planning/todos/completed/` |
| Complete (idea) | `.claude_ideas/active/` | `.claude_ideas/completed/` |
| Defer (idea) | `.claude_ideas/active/` | `.claude_ideas/someday/` |
| Defer (project) | `.planning/todos/pending/` | `.planning/todos/deferred/` |
| Drop (idea) | `.claude_ideas/active/` | `.claude_ideas/dropped/` |
| Drop (project) | `.planning/todos/pending/` | `.planning/todos/dropped/` |
| Reactivate (someday) | `.claude_ideas/someday/` | `.claude_ideas/active/` |

Create the target directory if it doesn't exist. Progress updates don't move the file.

### Step 6: Update Related Docs (if applicable)

If the update resulted in gotchas relevant to a service or system, suggest using `/correct` if the gotcha is a recurring mistake.

## Rules

- **Never skip completion notes.** Even if it seems obvious, document what happened.
- **Be specific in gotchas.** Include actual commands, file paths, config values.
- **Keep it concise.** Scannable bullet points and numbered lists, not essays.
- **Progress updates are cheap.** Don't wait until completion -- update mid-work.
- **Preserve history.** Never overwrite previous progress updates. Append new ones.

## Output

```
Updated: <todo title>
Action: <progress/completed/deferred/dropped/reactivated>
Location: <current file path>
Notes: <summary of what was added>
```

## References

- `references/update-formats.md` -- Detailed templates for each update action type
