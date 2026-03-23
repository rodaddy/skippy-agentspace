---
name: check-todos
description: Unified todo checker - shows both project todos and global ideas in a single numbered list, then routes selection to action.
allowed-tools: "Read,Grep,Glob"
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
---

# Check Todos - Unified Todo & Idea Viewer

Gathers and displays all pending work across project todos, global ideas, and someday items in a single prioritized list. After display, prompts for action selection.

## When to Use

- Getting an overview of all pending work
- Before starting work to see what needs attention
- After completing a task to pick the next item
- Reviewing someday items to consider reactivating

## Workflow

### Step 1: Gather All Todos

Spawn a Sonnet explore agent to scan these locations:

> `<dev-root>` is the parent directory containing all your projects (e.g., `~/Development`). Detect it as the parent of `{CWD}` or use `$DEV_ROOT` if set.

**Project todos:**
- Current project: `{CWD}/.planning/todos/pending/*.md`
- All projects: `<dev-root>/*/.planning/todos/pending/*.md`

**Global ideas:**
- Active: `<dev-root>/.claude_ideas/active/*.md`
- Someday: `<dev-root>/.claude_ideas/someday/*.md`

Agent extracts from each file: title, priority, tags, has-details flag, file path.

Agent returns structured summary, NOT raw file contents.

### Step 2: Apply Filter (Optional)

If user specified a filter (e.g., "check infra todos"), match against tags, area, or project directory name.

### Step 3: Display Results

See `references/display-format.md` for the full display template.

Summary format: numbered list grouped by section (Project Todos per project, Global Ideas, Someday/Future). Sort within each section by priority (high > medium > low), then alphabetically.

### Step 4: Prompt for Selection

Ask user which item to work on. Accept number, 'all' for deep review, or 'none' to skip.

### Step 5: Route Selection

Based on item type, offer appropriate actions:

**Project todos:** Work on it, add progress, defer, drop, complete
**Global ideas:** Work on it, convert to project todo, defer, complete, drop
**Someday items:** Reactivate, convert to project todo, drop, keep

See `references/routing-actions.md` for detailed action menus and implementation.

### Step 6: Execute Action

- **Work on it:** Read the todo, summarize context, hand off
- **Update/Complete/Defer/Drop:** Call `/update-todo`
- **Convert:** Create in target project, move original to completed
- **Reactivate:** Move from someday to active

## Rules

- **Use Sonnet for explore agent** -- keep raw contents out of main context
- **Number items continuously** across all sections
- **Preserve priority ordering** within each section
- **Support partial matches** for filters
- **After any action, offer to show updated list** (don't auto-refresh)

## Output

```
Checked todos: X project, Y global ideas, Z someday
Selected: <title>
Action: <what was done or what's next>
```

## References

- `references/display-format.md` -- Full display template and formatting rules
- `references/routing-actions.md` -- Detailed action menus for each item type
