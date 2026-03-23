---
name: session-start
description: Pick up where you left off after /clear. Reads project state via lightweight agent, presents briefing and next actions. Counterpart to /session-wrap.
allowed-tools: "Read,Grep,Glob"
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
Task(subagent_type="Explore", model="sonnet", prompt="""
Working directory: {CWD}

Derive PROJECT_NAME from CWD relative to DEV_ROOT (/Volumes/ThunderBolt/Development).
If CWD == DEV_ROOT, PROJECT_NAME = "Development".

## Phase 1: Live State + Open Brain (parallel)

Run these in parallel:
1. Bash: cd {CWD} && git branch --show-current && git status --short | head -10 && git log --oneline -5
2. Bash: mcp2cli open-brain session_load --params '{"project": "<PROJECT_NAME>"}' 2>/dev/null || echo "OB_UNAVAILABLE"
3. Bash: ls {DEV_ROOT}/.claude_ideas/active/ 2>/dev/null | wc -l

Open Brain is the PRIMARY context source. It contains session summaries, decisions, learnings, blockers, and next steps from all previous sessions.

## Phase 2: Fallback (ONLY if Open Brain returned "OB_UNAVAILABLE" or empty)

If and only if Open Brain failed, fall back to local files:
- Reports base: If CWD == DEV_ROOT, REPORTS_BASE = DEV_ROOT/.reports. Otherwise REPORTS_BASE = DEV_ROOT/.reports/<project-name>.
- Read {REPORTS_BASE}/briefing.md, checkpoint.md, session-history.md (last 2 entries)
- Read {CWD}/.planning/STATE.md (first 20 lines)
- Prefix output with **[FALLBACK -- Open Brain unavailable, using local files]**

## Output Format

Return ONLY this format, MAX 30 LINES TOTAL. No raw file dumps. Summarize, don't copy:

**Branch:** <name> | **Dirty:** <N files or clean>
**Recent:** <last 3 commits, one line each>

**Last session:** <date> -- <one-line summary>
**Done:** <3-5 terse bullets>
**Decisions:** <1-2 bullets or "None">
**Blockers:** <active blockers/issues, or "None">
**Carry-forward:** <deferred items from previous sessions, or "None">
**Next:** <planned next actions>
**Phase:** <current phase/status, one line>
**Ideas:** <N active> pending (use /check-todos to review)

If Open Brain returned data, ALL of Done/Decisions/Blockers/Carry-forward/Next come from it.
Carry-forward items are CRITICAL -- these are things that keep getting deferred. Flag them.
""")
```

### Step 2: Present and Wait

Output the scout's briefing directly. Do NOT paraphrase. Then add: **"Ready. What do you want to work on?"** -- STOP and wait.

## Rules

- Never read project files in the main session -- delegate to scout
- Trust checkpoint.md as authoritative state if it exists
- No AskUserQuestion -- present state and wait
