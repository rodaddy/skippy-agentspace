---
name: trace
description: Display agent flow trace -- shows how skills, agents, and tools interacted during this session. File-based, no external dependencies.
allowed-tools: "Read,Grep,Glob"
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rodaddy/skippy-agentspace
  category: utility
  absorbed_from: oh-my-claudecode/trace
---

# trace -- Agent Flow Visualization

Shows the chronological flow of skill activations, agent spawns, and tool interactions during the current session. Portable, file-based -- no MCP dependencies.

## Usage

```
/trace
/trace filter=agents
/trace last=10
```

## How It Works

### Event Log

Skills and orchestrators write trace events to `.skippy/trace.jsonl`:

```json
{"ts": "2026-03-15T21:30:00Z", "type": "skill", "name": "drive", "action": "start", "detail": "PRD setup for auth module"}
{"ts": "2026-03-15T21:30:05Z", "type": "agent", "name": "executor", "action": "spawn", "detail": "complexity=MEDIUM, task=implement login endpoint"}
{"ts": "2026-03-15T21:30:45Z", "type": "agent", "name": "executor", "action": "complete", "detail": "3 files changed, build passes"}
{"ts": "2026-03-15T21:31:00Z", "type": "verify", "name": "drive", "action": "check", "detail": "US-001: 3/3 criteria pass"}
```

### Event Types

| Type | When | Example |
|------|------|---------|
| `skill` | Skill activation/completion | `/drive start`, `/autopilot phase=2` |
| `agent` | Agent spawn/complete/error | `executor spawned`, `architect verified` |
| `verify` | Verification check | `US-001 passes`, `build failed` |
| `error` | Failure or escalation | `QA cycle 3 same error` |

### Writing Trace Events

Any skill can append to the trace log. Helper pattern:

```bash
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","type":"skill","name":"drive","action":"start","detail":"..."}' >> .skippy/trace.jsonl
```

Or in the skill prompt, instruct the orchestrator to append trace events as it works.

## Display

When `/trace` is invoked:

1. Read `.skippy/trace.jsonl`
2. Parse events
3. Display timeline:

```
21:30:00  [skill]  drive         START   PRD setup for auth module
21:30:05  [agent]  executor      SPAWN   complexity=MEDIUM, implement login endpoint
21:30:45  [agent]  executor      DONE    3 files changed, build passes
21:31:00  [verify] drive         CHECK   US-001: 3/3 criteria pass
21:31:10  [skill]  drive         DONE    All stories pass, architect approved
```

4. Show summary:
   - Total duration
   - Agents spawned (count by type)
   - Skills activated
   - Verification results
   - Errors/escalations

## Example Trace Output

A real session running `/drive` to implement an auth module:

```
SESSION: 2026-03-15T21:29:55Z  Duration: 4m 22s

21:29:55  [skill]  drive         START   PRD setup for auth module (3 stories)
21:30:05  [agent]  planner       SPAWN   complexity=MEDIUM, break US-001 into tasks
21:30:18  [agent]  planner       DONE    4 tasks, 2 files identified
21:30:20  [agent]  executor      SPAWN   complexity=MEDIUM, implement login endpoint
21:30:45  [agent]  executor      DONE    3 files changed, build passes
21:31:00  [verify] drive         CHECK   US-001: 3/3 criteria pass
21:31:05  [agent]  executor      SPAWN   complexity=MEDIUM, implement token refresh
21:31:38  [error]  executor      FAIL    typecheck: Property 'exp' missing on TokenPayload
21:31:40  [agent]  executor      SPAWN   complexity=MEDIUM, fix type error + retry
21:31:55  [agent]  executor      DONE    1 file changed, typecheck passes
21:32:00  [verify] drive         CHECK   US-002: 2/2 criteria pass
21:32:17  [skill]  drive         DONE    All stories pass, architect approved

SUMMARY:
  Skills activated:  1 (drive)
  Agents spawned:    4 (planner x1, executor x3)
  Verifications:     2 pass, 0 fail
  Errors:            1 (resolved -- type fix)
```

## Reading Traces

**Follow the spawn-done pairs.** Every `SPAWN` should have a matching `DONE` or `FAIL`. An unpaired spawn means the agent hung or was killed -- check the detail for what it was working on.

**Errors that self-resolve are normal.** A `FAIL` followed by another `SPAWN` with the same agent means the orchestrator retried. Only worry about errors that appear 3+ times in a row (QA death loop) or that end the session.

**Duration gaps reveal bottlenecks.** If there's a 2-minute gap between an agent `SPAWN` and `DONE`, that agent hit something expensive (large file scan, complex generation). If there's a gap between `DONE` and the next `SPAWN`, the orchestrator was thinking.

**Verification events are the truth.** `CHECK` events with criteria counts (e.g., "3/3 pass") confirm actual acceptance. Code being written without a following `CHECK` means it shipped unverified.

**Use filters to focus.** When debugging a failure, start with `filter=errors` to find the break point, then `last=10` from that area to see surrounding context.

## Filtering

- `filter=agents` -- show only agent spawn/complete events
- `filter=skills` -- show only skill activations
- `filter=errors` -- show only errors and escalations
- `last=N` -- show only the last N events
