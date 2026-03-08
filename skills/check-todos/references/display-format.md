# Display Format Reference

## Full Display Template

```markdown
## Pending Items
{filter note if applicable}

### Project Todos (project-name)
1. [P:high] Task title - area:tag1,tag2
2. [P:medium] Another task - area:tag3

### Project Todos (other-project)
3. [P:high] Other task - area:integration

### Global Ideas
4. [P:high] Idea title - project:infrastructure (has details)
5. [P:medium] Another idea - project:tooling

### Someday/Future
6. [P:low] Future idea - project:integration
7. [P:low] Another future idea

---
Total: N project todos (X proj1, Y proj2), M global ideas, K someday
```

## Formatting Rules

- **Numbering:** Continuous across all sections (1, 2, 3... not restarting per section)
- **Priority badge:** `[P:high]`, `[P:medium]`, `[P:low]`
- **Sort order:** Within each section: high > medium > low, then alphabetical
- **Details indicator:** Append `(has details)` to items that link to reports/plans/sessions
- **Internal mapping:** Keep a PATHS dict: `{1: "/path/to/file.md", 2: ...}`

## Edge Cases

**No todos found:**
```
No pending todos or ideas found.

Scanned:
- Project todos: {CWD}/.planning/todos/pending/
- Global ideas: <dev-root>/.claude_ideas/active/
- Someday: <dev-root>/.claude_ideas/someday/

Ready to create a new todo or idea?
```

**Filter returns nothing:**
```
No items found matching filter: <filter>
Try removing the filter or check spelling.
```

**User says "all":**
Read each file individually and display full contents. Expensive but useful for deep review.
