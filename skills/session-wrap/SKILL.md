---
name: session-wrap
description: Wrap up a session - create session file + dated history file + briefing update, commit on current branch.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
---

# Session Wrap - End-of-Session Workflow

Main-context workflow. No subagent. No approval gates. Everything runs directly for zero permission prompts.

## Pre-flight

Gather values with SEPARATE Bash calls (no chaining):

```
TODAY           = $(date +%Y-%m-%d)
CURRENT_BRANCH  = git branch --show-current
SESSION_ID      = resolve from session files or uuidgen fallback
PROJECT_DIR     = cwd
PROJECT_NAME    = basename of PROJECT_DIR relative to dev root
REPORTS_BASE    = <dev-root>/.reports/$PROJECT_NAME
SESSIONS_DIR    = $REPORTS_BASE/sessions
BRIEFING_FILE   = $REPORTS_BASE/briefing.md
```

**CRITICAL: All reports go to a centralized reports directory, never project-local.**

### Directory Setup

```bash
mkdir -p $SESSIONS_DIR
```

## Workflow

### Step 1: Read Existing State

Read (some may not exist -- that's fine):
- Files in SESSIONS_DIR/
- BRIEFING_FILE
- Most recent session's "Next Session" section for carry-forward
- Active todos/ideas

### Step 2: Draft Content

Draft session summary covering: what was done, files changed, decisions made, known issues, new ideas. See `references/session-templates.md` for file templates.

### Step 2.5: Review Active Todos (MANDATORY)

Compare each active todo against session work:
- **Completed:** Add to completed list
- **Progressed:** Add to progressed list
- **Unchanged:** Skip

### Step 3: Write Files

Use parallel Write calls:
1. Session file: `SESSIONS_DIR/SESSION_ID.md`
2. History file: `REPORTS_BASE/session-TODAY_SLUG.md`
3. Append briefing block to BRIEFING_FILE (Edit, not Write)
4. Handle todo status changes

### Step 4: Commit on Current Branch

NO session branch. Commit directly on current branch:

```bash
git add .reports/sessions/SESSION_ID.md
git add .reports/session-TODAY_SLUG.md .reports/briefing.md
git commit -m "session: wrap TODAY -- SHORT_SUMMARY"
```

Each git command in its own Bash call. Only stage reports files.

### Step 5: Sync Index (optional)

Run any search index update tools if available.

### Step 6: Report

```
Session wrapped:
   - Session file: .reports/sessions/<SESSION_ID>.md
   - History: .reports/session-<DATE>_<slug>.md
   - Briefing: .reports/briefing.md [APPENDED/SKIPPED]
   - Todos: [N completed, M progressed, K unchanged]
   - Commit: [hash] on [branch]
```

## Error Handling

| Issue | Action |
|-------|--------|
| Not a git repo | Skip commit, still create session files |
| No changes to commit | Continue (not an error) |
| Directories don't exist | Create with mkdir -p |
| No previous session files | No carry-forward to extract |

## Rules

- **Carry-forward pruning is mandatory.** Compare every item from previous carry-forward against what was done this session. Only carry genuinely pending items.
- **Use separate Bash calls** for each git command
- **Never use Write on briefing file** -- append only via Edit

## References

- `references/session-templates.md` -- Full file templates for session, history, and briefing
