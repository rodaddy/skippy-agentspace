---
name: session-wrap
description: Wrap up a session - create session file + dated history file + briefing update, commit on current branch. Use when ending a work session.
triggers:
 - /session-wrap
 - wrap this session
 - wrap session
 - end session
 - session done
 - wrap
---

# Session Wrap - End-of-Session Workflow

Main-context workflow. No subagent. No approval gates. Everything runs directly in the orchestrator context for zero permission prompts.

## Pre-flight

Gather these values with SEPARATE Bash calls (no chaining, no `$$`):

```
TODAY           = $(date +%Y-%m-%d)
CURRENT_BRANCH  = git branch --show-current
SESSION_ID      = $(uuidgen)   # ALWAYS generate fresh. NEVER read /tmp/claude-sid-* or session files.
PROJECT_DIR     = cwd
DEV_ROOT        = <DEV_DIR>
PROJECT_NAME    = basename of PROJECT_DIR relative to DEV_ROOT
                  (e.g., PROJECT_DIR=<DEV_DIR>/resumeUpdate -> PROJECT_NAME=resumeUpdate)
                  If PROJECT_DIR == DEV_ROOT, PROJECT_NAME is empty (use root .reports/)
                  For nested projects: infrastructure/observability -> infrastructure-observability
REPORTS_BASE    = $DEV_ROOT/.reports/$PROJECT_NAME (if PROJECT_NAME is empty, just $DEV_ROOT/.reports)
SESSIONS_DIR    = $REPORTS_BASE/sessions
HISTORY_DIR     = $REPORTS_BASE
BRIEFING_FILE   = $REPORTS_BASE/briefing.md
IDEAS_ACTIVE    = $DEV_ROOT/.claude_ideas/active
IDEAS_COMPLETED = $DEV_ROOT/.claude_ideas/completed
QMD_BIN         = "qmd"
```

**CRITICAL: All reports go to Development/.reports/<project-name>/, never to <project>/.reports/.** This centralizes session history across all projects.

### Session ID Resolution

1. **User provides it** -- use directly
2. **Generate with `uuidgen`** via Bash -- always generates a fresh unique ID

**NEVER read `/tmp/claude-sid-*` files.** Those files persist across sessions and will give you a stale ID from a previous session, causing re-wrap of the wrong session file or OB duplicate entries.

### Directory Setup

Before writing any files, create directories with Bash:
```
mkdir -p $SESSIONS_DIR
mkdir -p $IDEAS_ACTIVE
mkdir -p $IDEAS_COMPLETED
```

## File Structure

**Centralized** (`Development/.reports/<project-name>/`):
```
Development/.reports/
  sessions/                # Root-level (Development) sessions
  briefing.md              # Root-level briefing
  resumeUpdate/            # Project-specific
    sessions/
    briefing.md
  my-project/              # Project-specific
    sessions/
    briefing.md
  ...
```

All session files live under `Development/.reports/`. No `.reports/` in individual project directories.

## Session Context

Before starting the wrap steps, draft a detailed session summary covering:
- What was done (numbered list with specifics)
- Files changed
- Decisions made (WITH rationale -- "X over Y because Z")
- Known issues / blockers (with what's needed to unblock)
- New ideas that came up

Keep this in working memory -- it drives all the file writes AND the OB push.

## Step 1: Read Existing State

Read these files (some may not exist -- that's fine):
- List files in SESSIONS_DIR/
- List session-*.md files in HISTORY_DIR/
- BRIEFING_FILE
- Most recent session file in SESSIONS_DIR/ -- extract carry-forward from its "Next Session" section
- All files in IDEAS_ACTIVE/

Every session wrap creates a new session file. There is no re-wrap -- each `uuidgen` ID is unique.

**Use parallel tool calls** -- read multiple files simultaneously to save time.

## Step 2: Draft Content

Based on session context + carry-forward from previous session:

**Summary quality bar (MANDATORY -- thin summaries are worthless):**
- **summary:** 2-3 paragraph narrative. What was accomplished, why it matters, what state things are in now. NOT a one-liner. Include enough context that a future session can pick up cold without reading every file.
- **key_decisions:** Every architectural/implementation choice made WITH rationale. "Chose NATS over HTTP because X" not just "chose NATS."
- **next_steps:** Specific actionable items with enough context to resume cold. "Run swarm on king-strategies #167 then fix the 5 CRITICALs" not "continue work."
- **blockers:** Anything that stalled progress, with what's needed to unblock. Empty array is fine if nothing blocked.

**Anti-patterns (DO NOT):**
- "HB snapshot -- working on stuff" <- useless
- Empty key_decisions array <- every session has decisions
- "continue work" as a next_step <- what work? be specific
- One-sentence summary <- OB search uses this for relevance, make it count

### Session File (SESSIONS_DIR/SESSION_ID.md)

Template:

```
# Session [TODAY] -- [SHORT_TITLE]

**Session ID:** [SESSION_ID]
**Date:** [TODAY]
**Branch:** [CURRENT_BRANCH]

## Summary
[2-3 paragraph narrative: what was accomplished, why it matters, and what state things are in now.
NOT a one-liner. Include enough context that a future session can pick up cold without reading every file.]

## What Was Done
[Numbered list with specifics -- include file paths, function names, config values changed.
Each item should be actionable context, not vague ("added auth" -> "added per-user token support via AUTH_TOKEN_USER_* env vars")]

## Files Changed
[List from session context]

## Decisions Made
[Each decision with rationale: "Chose X over Y because Z". These feed OB's key_decisions field.]

## Known Issues / Blockers
[List from session context, with what's needed to unblock each]

## Learnings
[Key takeaways, gotchas discovered]

## Next Session
### Carry-forward (from previous sessions)
[Items from previous carry-forward that are STILL PENDING -- see Carry-forward Pruning below]
### New from this session
[New items arising from this session's work]
```

#### Carry-forward Pruning (CRITICAL -- THIS KEEPS GETTING SKIPPED)

**STOP. Do this step deliberately. Do NOT skip it.**

For EVERY item in the previous carry-forward list, check:
1. Was it done this session? -> **DROP IT**
2. Was it made irrelevant by a decision? -> **DROP IT**
3. Has it been carried for 3+ sessions without action? -> **FLAG IT** to the user: "This has been deferred N sessions. Drop, do now, or keep?"
4. Is it genuinely still pending and actionable? -> **KEEP IT**

**If you blindly copy the previous list, you are violating this rule.** Each item must be individually evaluated.

### History File (HISTORY_DIR/session-TODAY_SLUG.md)

Standalone file. SLUG is a kebab-case summary.

```
# [TODAY] -- [SHORT_TITLE]

**Session ID:** [SESSION_ID]
**Branch:** [CURRENT_BRANCH]

## Done
[Compact bullet list]

## Decisions
[Compact bullet list]

## Files Changed
[Compact list]

## Known Issues
[Compact list]
```

### Briefing Append Block

```
---

**Last session:** [TODAY] -- [SHORT_TITLE]
**Done:** [pipe-separated compact list]
**Decisions:** [pipe-separated compact list]
**Blockers:** [pipe-separated compact list]
**Carry-forward:** [pipe-separated -- PRUNED, never blindly copied]
**Next:** [pipe-separated compact list -- NEW items from this session only]
```

## Step 2.5: Glossary Check (if GLOSSARY.md exists)

If the project has a `GLOSSARY.md`, scan session work for new domain terms that were introduced but aren't in the glossary. Present candidates to the user:

```
New terms used this session not in GLOSSARY.md:
- "regime" (used in strategy context)
- "staleness window" (used in data freshness checks)

Add to glossary? [yes/skip]
```

If yes, append the terms with definitions. If no GLOSSARY.md exists, skip silently.

## Step 2.6: Review Active Todos (MANDATORY -- DO NOT SKIP)

Read every file in IDEAS_ACTIVE/ and PROJECT_DIR/.planning/todos/pending/ (if any exist). For each item, compare against the session context:

- **Completed:** Session work fully satisfies the idea -> add to completed list
- **Progressed:** Session work partially advances the idea -> add to progressed list
- **Unchanged:** No overlap with this session -> skip

**Actions (applied in Step 3):**
- Completed ideas: read the active file, add `completed: [TODAY]` to frontmatter, write to IDEAS_COMPLETED/
- Progressed ideas: Edit the file in IDEAS_ACTIVE/ to append a `**Progress ([TODAY]):**` line
- Include todo status changes in the session file

**Report line (REQUIRED):** Include `**Todos updated:** [N completed, M progressed, K unchanged]`

## Step 3: Write Files

Use **parallel Write calls** where possible:
1. Write session file: SESSIONS_DIR/SESSION_ID.md
2. Write history file: HISTORY_DIR/session-TODAY_SLUG.md

Then:
3. **Rewrite BRIEFING_FILE entirely** using Write tool:
   - Top section = current state summary (what works, what's left) based on THIS session's knowledge
   - Bottom section = rolling history (last 5 session entries only -- drop older ones)
   - This ensures the briefing always reflects reality, not 2-week-old headers
4. Handle .claude_ideas/ changes (completed/progressed)

**Step 3 MUST complete before Step 3.5. Files are ALWAYS the source of truth.**

## Step 3.5: Persist to Open Brain (MANDATORY attempt -- graceful on failure)

**You MUST attempt this step. Do NOT skip it.** Open Brain is semantic memory -- without it, session knowledge is trapped in flat files. If OB fails, fall back to local files and report the failure. But you must TRY.

**Health check first:**
```bash
mcp2cli open-brain search_brain --params '{"query":"health check","limit":1}' --timeout 5000
```

If OB is unreachable, skip this step and report `OB: unreachable (skipped)`. Do NOT block the wrap.

**Push session (REQUIRED -- must include ALL fields with rich content):**
```bash
mcp2cli open-brain session_save --params '{
  "session_id": "<SESSION_ID>",
  "project": "<PROJECT_NAME>",
  "summary": "<FULL 2-3 paragraph narrative from Step 2 -- NOT a one-liner>",
  "tags": ["session-wrap", "<PROJECT_NAME>", "<CURRENT_BRANCH>", "<SESSION_ID>"],
  "blockers": [<array of current blocker strings>],
  "next_steps": [<array of specific actionable next steps>],
  "key_decisions": [<array of decisions WITH rationale, e.g. "Chose upsert-merge over silent reject because duplicate pushes should enrich, not drop">]
}'
```

**Data quality rules (CRITICAL):**
- **summary**: 2-3 paragraphs. Must include what was done, why, and current state. A future agent should understand the session from summary alone.
- **key_decisions**: Every architectural/implementation choice made this session. Include "X over Y because Z" format.
- **next_steps**: Specific and actionable. "Continue work" is NOT a valid next step.
- **blockers**: Only genuine blockers. Empty array is fine if nothing is blocked.
- **session_id**: The uuidgen ID from pre-flight. Enables dedup if the wrap runs twice.
- **tags**: Include SESSION_ID in tags so `get_entry` can retrieve the full record later.

**Verify the push landed:**
```bash
mcp2cli open-brain get_entry --params '{"table": "sessions", "id": "<returned-uuid>"}'
```
If verification fails, note it in Step 6 report but don't retry.

**Decisions (one call per significant decision):**
```bash
mcp2cli open-brain log_decision --params '{"title": "<decision>", "rationale": "<why>", "alternatives": ["<alt1>"], "tags": ["<project>"]}'
```

**Learnings (one call per gotcha, pattern, or solution discovered):**
```bash
mcp2cli open-brain log_thought --params '{"content": "<learning with context>", "tags": ["<project>"]}'
```

**Briefing snapshot (upserts per-project -- always reflects latest state):**
```bash
mcp2cli open-brain session_save --params '{
  "session_id": "briefing-<PROJECT_NAME>",
  "project": "<PROJECT_NAME>",
  "summary": "<full briefing content from Step 3 -- current state + rolling history>",
  "tags": ["briefing", "<PROJECT_NAME>"],
  "next_steps": [<carry-forward + new next steps>],
  "blockers": [<current blockers>],
  "key_decisions": [<recent key decisions from rolling history>]
}'
```
This creates ONE entry per project that always reflects the latest state. Any agent on any machine searches "briefing my-project" and gets the current picture. The deterministic `session_id: "briefing-<PROJECT_NAME>"` ensures every wrap upserts instead of creating duplicates.

**Show results inline** -- the user must see what went into OB:
```
Open Brain capture:
  - Session: saved (id: abc123, embedded: true) -- VERIFIED
  - Briefing: upserted (session_id: briefing-<PROJECT_NAME>)
  - Decisions: 2 logged
  - Learnings: 1 logged
```

**On failure:** If `mcp2cli open-brain` returns an error or times out:
1. Print the error to the user
2. Fall back to local files
3. Report "OB: FAILED -- fallback to local" in Step 6
4. Continue to Step 4 -- never block the commit

## Step 4: Commit on Current Branch

NO session branch. NO merge to main. Commit directly on current branch.

**CRITICAL: Use separate Bash calls for each git command.**

```
git add .reports/sessions/SESSION_ID.md
git add .reports/session-TODAY_SLUG.md .reports/briefing.md
git add .claude_ideas/completed/*.md .claude_ideas/active/*.md   # may error if empty, fine
git commit -m "session: wrap TODAY -- SHORT_SUMMARY (SESSION_ID)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**Git command rules:**
- **No `$(cat <<'EOF')`** -- use simple `-m "message"` with literal newlines
- **No `&&` chaining** -- each git command in its own Bash tool call
- Only stage `.reports/` and `.claude_ideas/` files -- never unrelated changes
- If nothing to commit, that's fine -- report it and continue

## Step 5: Sync qmd index

```bash
qmd update
qmd embed
```

Separate Bash calls. Do NOT pipe output through other commands.

## Step 6: Report

Output this to the user:

```
Session wrapped:
  - Session file: .reports/sessions/<SESSION_ID>.md
  - History: .reports/session-<DATE>_<slug>.md
  - Briefing: .reports/briefing.md [REWRITTEN]
  - Todos: [N completed, M progressed, K unchanged]
  - OB session: pushed (session_id: <SESSION_ID>) -- VERIFIED | FAILED: <reason> | unreachable (skipped)
  - OB briefing: upserted (session_id: briefing-<PROJECT_NAME>) | FAILED | skipped
  - OB decisions: N logged
  - OB learnings: N logged
  - Commit: [hash] on [branch]
  - qmd: synced | FAILED: <reason> | skipped (no qmd)
```

## Error Handling

| Issue | Action |
|-------|--------|
| Not a git repo | Skip commit, still create session files |
| No changes to commit | Continue (not an error) |
| `.reports/sessions/` doesn't exist | Create with mkdir -p |
| No previous session files | No carry-forward to extract |
| qmd fails | Report failure, don't block wrap |
| mcp2cli open-brain fails | Log warning, fall back to local files, continue to Step 4 |
| Permission prompt encountered | Skip that step, report it |

## Rules

- **Carry-forward pruning is mandatory.** Compare every item from previous carry-forward against what was done this session. Only carry genuinely pending items.
- **Use separate Bash calls** for each git command
- **Briefing is FULL REWRITE** -- not append. Stale headers must not persist.
- **Rolling history capped at 5 sessions** in the briefing.
- **Step 3.5 never blocks.** If Open Brain is down, log the error and move on. File writes (Step 3) and commit (Step 4) must always succeed regardless of OB status.

## References

- `references/session-templates.md` -- Full file templates for session, history, and briefing
