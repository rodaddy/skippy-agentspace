# Bulk Todo Extraction

Extract multiple todos from existing docs (STATE.md, checkpoint docs, session notes).

## Trigger

User says "extract todos from STATE.md" or similar.

## Process

1. **Read the source file** (e.g. `.planning/STATE.md`)
2. **Find todo items:**
   - Checkbox syntax: `- [ ] <item>`
   - "Pending Todos" or "Next Steps" sections
   - Any markdown list items representing unfinished work
3. **Create one file per item:**
   - Title from checkbox text (or first sentence)
   - Description from surrounding context (if available)
   - Default priority: medium (unless doc specifies)
4. **Report what was created:**
   ```
   Extracted 3 todos from STATE.md:
   - auto-update-infrastructure-inventory.md (global, medium)
   - fix-oauth-token-refresh.md (project, high)
   - add-approval-workflow.md (project, medium)
   ```

## Scope Detection in Bulk Mode

- Extracting from a project's STATE.md -> project todos (`.planning/todos/pending/`)
- Extracting from global notes -> global ideas (`.claude_ideas/active/`)
- If mixed, ask the user or use context clues

## Context Linking (CRITICAL)

Before writing a todo, check if detailed planning, reports, or session notes already exist:

1. Search `.reports/` for related files
2. Search `.sessions/` for session notes covering this topic
3. Check memory files

**If context exists:** Link to it in a `## References` section. Do NOT copy content into the todo -- just reference the files.

**If no context exists:** Write a concise description. Don't pad it.
