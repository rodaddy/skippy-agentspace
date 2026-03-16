---
name: session-start
description: Pick up where you left off after /clear. Reads project state via lightweight agent, presents briefing and next actions. Counterpart to /session-wrap.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: workflow
triggers:
  - /session-start
  - pick up where we left off
  - what were we doing
  - where did we leave off
---

# Session Start - Post-Clear Context Recovery

Restores project context after `/clear` using a lightweight scout agent.

## Workflow

### Step 1: Spawn Scout

Tell the user "Pulling session state..." then spawn:

```
Task(subagent_type="Explore", model="opus", prompt="""
Working directory: {CWD}

Reports are centralized at Development/.reports/<project-name>/.
Derive PROJECT_NAME from CWD relative to DEV_ROOT (/Volumes/ThunderBolt/Development).
If CWD == DEV_ROOT, REPORTS_BASE = DEV_ROOT/.reports. Otherwise REPORTS_BASE = DEV_ROOT/.reports/<project-name>.

Gather state from these sources (parallel tool calls):
1. Bash: cd {CWD} && git branch --show-current && git status --short | head -10 && git log --oneline -5
2. Read {REPORTS_BASE}/briefing.md (if exists -- this is the primary source, compact)
3. Read {REPORTS_BASE}/checkpoint.md (if exists)
4. Read {REPORTS_BASE}/session.md (if exists -- use for detail if briefing.md is missing)
5. Read {REPORTS_BASE}/session-history.md (if exists -- scan last 2 entries for recent context)
6. Read {CWD}/.planning/STATE.md (first 20 lines only)
7. Bash: ls {DEV_ROOT}/.claude_ideas/active/ 2>/dev/null | wc -l
8. Bash: mcp2cli open-brain session_load --params '{"project": "<PROJECT_NAME>"}' 2>/dev/null || echo "Open Brain unavailable"

Source 8 (Open Brain) provides semantic context from previous sessions -- decisions made, patterns discovered, blockers encountered. If it returns data, weave it into the briefing under **Brain context:** (1-3 lines). If it fails, skip silently.

Return ONLY this format, MAX 30 LINES TOTAL. No raw file dumps. Summarize, don't copy:

**Branch:** <name> | **Dirty:** <N files or clean>
**Recent:** <last 3 commits, one line each>

**Last session:** <date> -- <one-line summary>
**Done:** <3-5 terse bullets>
**Decisions:** <1-2 bullets or "None">
**Blockers:** <active blockers/issues from last session, or "None">
**Carry-forward:** <items from previous sessions not yet done, or "None">
**Next:** <new items from last session's "Next Session">
**Brain context:** <1-3 lines from Open Brain session_load, or omit if unavailable>
**Recent history:** <1-2 line summary of what session-history.md shows, or "No history yet">
**Phase:** <current GSD phase status, one line>
**Ideas:** <N active> pending (use /check-todos to review)

If a file doesn't exist, skip its section. Do NOT exceed 30 lines.
Carry-forward items are CRITICAL -- these are things that keep getting deferred. Flag them.
""")
```

### Step 2: Present and Wait

Output the scout's briefing directly. Do NOT paraphrase. Then add: **"Ready. What do you want to work on?"** -- STOP and wait.

## Rules

- Never read project files in the main session -- delegate to scout
- Trust checkpoint.md as authoritative state if it exists
- No AskUserQuestion -- present state and wait
