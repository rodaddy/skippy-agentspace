---
name: add-todo
description: Scope-aware todo/idea capture - routes to project (.planning/todos/) or global (.claude_ideas/) store. Supports single items and bulk extraction.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
---

# Add Todo - Scope-Aware Capture

Create new todos in the appropriate scope (project vs global). Supports single items and bulk extraction from existing docs.

## When to Use

- User says "remember to..." or similar phrasing indicating future work
- Capturing an idea that doesn't fit current work
- Creating a project todo for work specific to the current codebase
- Extracting todos from STATE.md, checkpoint docs, or session notes

## Workflow

### Step 1: Gather Information

If not already provided, collect:
- **Title** (short, descriptive)
- **Description** (what needs to be done, why it matters)
- **Priority** (high/medium/low, default: medium)
- **Tags** (optional, e.g. [infra, automation, testing])
- **Steps** (optional numbered list if workflow is clear)

### Step 2: Detect Scope

**Project todo** if:
- CWD has a `.planning/` directory
- User explicitly says "project todo"
- Content is specific to the current codebase

**Global idea** if:
- CWD does NOT have a `.planning/` directory
- User explicitly says "global idea" or "global todo"
- Content is infrastructure, tooling, or cross-project

**If ambiguous:** Ask the user to clarify.

### Step 3: Create the File

**Filename:** Slugified from title (lowercase, hyphens, no special chars).

**Location:**
- Project todos: `{CWD}/.planning/todos/pending/<filename>.md`
- Global ideas: `<dev-root>/.claude_ideas/active/<filename>.md`

Create the target directory if it doesn't exist.

**File format:**

```markdown
---
tags: [tag1, tag2]
project: <project-name>
added: YYYY-MM-DD
priority: <high|medium|low>
---

# Title

Description of what needs to be done and why.

1. Step 1 (if applicable)
2. Step 2
```

### Step 4: Confirm Output

```
Created: <title>
Scope: <project|global>
Priority: <priority>
Location: <absolute file path>
```

## Bulk Mode

For extracting todos from existing docs, see `references/bulk-extraction.md`.

## Rules

- **Never guess scope.** If ambiguous, ask the user.
- **Filename conflicts:** If slug exists, append `-2`, `-3`, etc.
- **Tags are optional.** Don't force them if none fit.
- **Steps are optional.** Only include if workflow is clear.
- **Priority defaults to medium.** Only high if explicitly urgent.
- **Date format:** YYYY-MM-DD only, no timestamps.
- **Don't create duplicates:** Check if similar todo exists before creating.
- **Don't duplicate existing docs:** If a report/plan exists, LINK to it.
- **Don't skip the description:** "Fix OAuth" is not enough context.

## References

- `references/bulk-extraction.md` -- Bulk todo extraction from docs
- `references/examples.md` -- Example single, global, and bulk todo creation

## Integration

- Complements `/check-todos` (list) and `/update-todo` (modify)
- Todos created during a session can be reviewed at session-wrap time
