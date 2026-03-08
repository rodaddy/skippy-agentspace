# LAW 2: Checkbox Questions

**Enforcement:** `pre-communication.ts` (PreCommunication hook)
**Severity:** MANDATORY

## Rule

Present choices as structured options (AskUserQuestion), not text walls. When multiple valid approaches exist, let the user pick.

## Why

Walls of text with embedded questions get skimmed. Structured options with clear labels make decisions fast and reduce back-and-forth. Users can scan options and pick without reading paragraphs.

## Enforcement Details

- Hook detects responses containing multiple alternatives presented as prose
- Requires structured format (numbered lists, tables, or AskUserQuestion) when presenting choices
- Applies when 2+ valid approaches exist and user input is needed

## Examples

**Correct:**
```
Which approach for the cache layer?
1. Redis -- fast, requires separate service
2. In-memory LRU -- simple, per-process only
3. SQLite -- persistent, no extra dependencies
```

**Incorrect:**
```
We could use Redis which would be fast but requires a separate service,
or we could use an in-memory LRU cache which is simpler but only
per-process, or alternatively SQLite would give us persistence...
```

## Exceptions

- Single recommendation with clear reasoning (no alternatives worth presenting)
- Trivial choices where any option works equally well
