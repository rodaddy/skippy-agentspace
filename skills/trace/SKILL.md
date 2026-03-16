---
name: trace
description: Display agent flow trace -- shows how skills, agents, and tools interacted during this session. File-based, no external dependencies.
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

## Filtering

- `filter=agents` -- show only agent spawn/complete events
- `filter=skills` -- show only skill activations
- `filter=errors` -- show only errors and escalations
- `last=N` -- show only the last N events
