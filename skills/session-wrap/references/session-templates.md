# Session File Templates

## Session File (SESSIONS_DIR/SESSION_ID.md)

```markdown
# Session [TODAY] -- [SHORT_TITLE]

**Session ID:** [SESSION_ID]
**Date:** [TODAY]
**Branch:** [CURRENT_BRANCH]

## Summary
[2-3 sentence summary]

## What Was Done
[Numbered list from session context]

## Files Changed
[List from session context]

## Decisions Made
[List from session context]

## Known Issues / Blockers
[List from session context]

## Learnings
[Key takeaways, gotchas discovered]

## Next Session
### Carry-forward (from previous sessions)
[Items from previous carry-forward that are STILL PENDING]
### New from this session
[New items arising from this session's work]
```

### Carry-forward Pruning (MANDATORY)

Before writing carry-forward, compare EVERY item from the previous session's carry-forward against:
1. What was done this session (remove if completed)
2. What was explicitly marked invalid/unnecessary (remove)
3. What the session context says to drop (remove)

**Only carry forward items that are genuinely still pending.**

## History File (REPORTS_BASE/session-TODAY_SLUG.md)

Standalone file. SLUG is a kebab-case summary.

```markdown
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

## Briefing Append Block

Appended to briefing.md (never overwrite):

```markdown
---

**Last session:** [TODAY] -- [SHORT_TITLE]
**Done:** [pipe-separated compact list]
**Decisions:** [pipe-separated compact list]
**Blockers:** [pipe-separated compact list]
**Carry-forward:** [pipe-separated -- PRUNED, never blindly copied]
**Next:** [pipe-separated compact list -- NEW items from this session only]
```

## Session ID Resolution

Resolution order (each step is a SEPARATE tool call):
1. User provides it -- use directly
2. Check temp files for session ID
3. Read session config file
4. Generate fallback with `uuidgen`
