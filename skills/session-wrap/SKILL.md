---
name: session-wrap
description: Wrap up a session - create session file + dated history file + briefing update + persist to Open Brain, commit on current branch.
allowed-tools: "Read,Write,Edit,Grep,Glob"
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

> `<dev-root>` is the parent directory containing all your projects (e.g., `~/Development`). Detect it as the parent of `{CWD}` or use `$DEV_ROOT` if set.

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

**Step 3 MUST complete before Step 3.5. Files are ALWAYS the source of truth.**

### Step 3.5: Persist to Open Brain (MANDATORY attempt -- graceful on failure)

**You MUST attempt this step. Do NOT skip it.** Open Brain is PAI's semantic memory -- without it, session knowledge is trapped in flat files. If OB fails, fall back to local files and report the failure. But you must TRY.

**This supplements Step 3 file writes** -- files are always the source of truth. OB adds cross-session semantic search.

Run these mcp2cli calls and **show the result of each call to the user:**

**1. Session summary (REQUIRED):**
```bash
mcp2cli open-brain session_save --params '{"summary": "<full session summary from Step 2>", "project": "<PROJECT_NAME>", "tags": ["session-wrap", "<branch-type>"], "key_decisions": ["<decision1>", "<decision2>"], "next_steps": ["<next1>"], "blockers": []}'
```
Expected: `{"id": "uuid", "embedded": true}` -- save the ID for the report.

**2. Decisions (one call per significant decision):**
```bash
mcp2cli open-brain log_decision --params '{"title": "<decision>", "rationale": "<why>", "alternatives": ["<alt1>"], "tags": ["<project>"]}'
```

**3. Learnings (one call per gotcha, pattern, or solution discovered):**
```bash
mcp2cli open-brain log_thought --params '{"content": "<learning with context>", "tags": ["<project>"]}'
```

**Show results inline** -- the user must see what went into OB:
```
Open Brain capture:
  - Session: saved (id: abc123, embedded: true)
  - Decisions: 2 logged
  - Learnings: 1 logged
```

**On failure:** If `mcp2cli open-brain` returns an error or times out:
1. Print the error to the user
2. Fall back to local files:
   - Decisions: append to `~/.config/pai-private/knowledge/decisions-v2.json`
   - Learnings: append to `~/.config/pai-private/knowledge/learnings-v2.json`
3. Report "fallback to local" in Step 6
4. Continue to Step 4 -- never block the commit

### Step 4: Commit on Current Branch

NO session branch. Commit directly on current branch:

```bash
git add .reports/sessions/SESSION_ID.md
git add .reports/session-TODAY_SLUG.md .reports/briefing.md
git commit -m "session: wrap TODAY -- SHORT_SUMMARY"
```

Each git command in its own Bash call. Only stage reports files.

### Step 5: Sync Indexes

**qmd index sync** (background -- don't wait for completion):

```bash
rsync -az ~/.cache/qmd/index.sqlite root@10.71.20.15:/root/.cache/qmd/index.sqlite
```

Run this in the background. Report success/failure in the final summary but don't block on it. The server uses this index for `search_all` federated search. First sync is ~1GB, incrementals are small.

If rsync fails (server unreachable, etc.), note it in the report and move on -- it's non-critical.

### Step 6: Report

```
Session wrapped:
   Files:
   - Session: .reports/sessions/<SESSION_ID>.md
   - History: .reports/session-<DATE>_<slug>.md
   - Briefing: .reports/briefing.md [APPENDED/SKIPPED]

   Open Brain:
   - Session: saved (id: <uuid>) | FAILED: <reason> | fallback to local
   - Decisions: N logged | FAILED | fallback to local
   - Learnings: N logged | FAILED | fallback to local

   Todos: [N completed, M progressed, K unchanged]
   Commit: [hash] on [branch]
   qmd sync: synced | FAILED: <reason> | skipped (no index)
```

## Error Handling

| Issue | Action |
|-------|--------|
| Not a git repo | Skip commit, still create session files |
| No changes to commit | Continue (not an error) |
| Directories don't exist | Create with mkdir -p |
| No previous session files | No carry-forward to extract |
| mcp2cli open-brain fails | Log warning, fall back to local files, continue to Step 4 |

## Rules

- **Carry-forward pruning is mandatory.** Compare every item from previous carry-forward against what was done this session. Only carry genuinely pending items.
- **Use separate Bash calls** for each git command
- **Never use Write on briefing file** -- append only via Edit
- **Step 3.5 never blocks.** If Open Brain is down, log the error and move on. File writes (Step 3) and commit (Step 4) must always succeed regardless of OB status.

## References

- `references/session-templates.md` -- Full file templates for session, history, and briefing
